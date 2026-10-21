#!/usr/bin/env python3
"""Run on a GitHub macOS runner. No Apple account, certificate or password required."""
from pathlib import Path
import json
import os
import plistlib
import re
import shutil
import subprocess
import sys
import zipfile

ROOT = Path(__file__).resolve().parents[1]
BUILD = ROOT / 'build'
DIAGNOSTICS = BUILD / 'diagnostics'
ARTIFACTS = BUILD / 'artifacts'


def run(arguments, log_name=None):
    print('+ ' + ' '.join(map(str, arguments)), flush=True)
    if log_name:
        with (DIAGNOSTICS / log_name).open('w', encoding='utf-8') as log:
            process = subprocess.Popen(list(map(str, arguments)), cwd=ROOT, stdout=subprocess.PIPE,
                                       stderr=subprocess.STDOUT, text=True, errors='replace')
            for line in process.stdout:
                print(line, end='', flush=True)
                log.write(line)
            if process.wait() != 0:
                raise RuntimeError(f'Command failed. See {log_name}.')
        return ''
    return subprocess.check_output(list(map(str, arguments)), cwd=ROOT, text=True)


def select_simulator(devices):
    candidates = []
    for runtime, entries in devices.items():
        match = re.search(r'iOS-(\d+)', runtime)
        if not match or int(match.group(1)) < 18:
            continue
        for device in entries:
            if device.get('isAvailable') and device.get('name', '').startswith('iPhone'):
                candidates.append(device)
    candidates.sort(key=lambda device: (device['name'] != 'iPhone 16 Pro', device['name']))
    if not candidates:
        raise RuntimeError('No iPhone simulator with iOS 18+ is installed on this runner.')
    return candidates[0]


def main():
    if sys.platform != 'darwin':
        raise RuntimeError('This script requires macOS and Xcode. Run the GitHub Actions workflow from Windows.')
    bundle_id = os.environ.get('LEXIWALL_BUNDLE_ID', 'com.example.lexiwall')
    if not re.fullmatch(r'[A-Za-z][A-Za-z0-9-]*(?:\.[A-Za-z0-9-]+){2,}', bundle_id) or len(bundle_id) > 150:
        raise ValueError('Invalid bundle identifier.')
    DIAGNOSTICS.mkdir(parents=True, exist_ok=True)
    ARTIFACTS.mkdir(parents=True, exist_ok=True)
    version = run(['xcodebuild', '-version'])
    (DIAGNOSTICS / 'xcode-version.txt').write_text(version, encoding='utf-8')
    devices = json.loads(run(['xcrun', 'simctl', 'list', 'devices', 'available', '--json']))['devices']
    simulator = select_simulator(devices)
    (DIAGNOSTICS / 'simulator.json').write_text(json.dumps(simulator, indent=2), encoding='utf-8')
    common = ['xcodebuild', '-project', 'LexiWall.xcodeproj', '-scheme', 'LexiWall']
    results = BUILD / 'LexiWallTests.xcresult'
    try:
        # An IPA is only offered if compilation and all XCTest tests succeed.
        run(common + ['-configuration', 'Debug', '-sdk', 'iphonesimulator',
            '-destination', f'platform=iOS Simulator,id={simulator["udid"]}',
            '-destination-timeout', '180', '-parallel-testing-enabled', 'NO',
            '-derivedDataPath', BUILD / 'simulator', '-resultBundlePath', results,
            'CODE_SIGNING_ALLOWED=NO', 'test'], 'simulator-tests.log')
        run(common + ['-configuration', 'Release', '-sdk', 'iphoneos',
            '-destination', 'generic/platform=iOS', '-derivedDataPath', BUILD / 'device',
            'CODE_SIGNING_ALLOWED=NO', 'CODE_SIGNING_REQUIRED=NO', 'CODE_SIGN_IDENTITY=',
            f'PRODUCT_BUNDLE_IDENTIFIER={bundle_id}', 'build'], 'device-build.log')
        app = BUILD / 'device/Build/Products/Release-iphoneos/LexiWall.app'
        with (app / 'Info.plist').open('rb') as file:
            info = plistlib.load(file)
        if 'iPhoneOS' not in info.get('CFBundleSupportedPlatforms', []):
            raise RuntimeError('The build is not a physical iPhone application.')
        executable = app / info['CFBundleExecutable']
        if 'arm64' not in run(['lipo', '-archs', executable]).split():
            raise RuntimeError('The app does not contain the iPhone arm64 architecture.')
        payload = BUILD / 'ipa/Payload'
        payload.mkdir(parents=True, exist_ok=True)
        shutil.copytree(app, payload / 'LexiWall.app', symlinks=True)
        ipa = ARTIFACTS / 'LexiWall-unsigned.ipa'
        run(['ditto', '-c', '-k', '--keepParent', payload, ipa])
        with zipfile.ZipFile(ipa) as archive:
            if archive.testzip() is not None or 'Payload/LexiWall.app/Info.plist' not in archive.namelist():
                raise RuntimeError('IPA archive verification failed.')
        shutil.copy2(ROOT / 'WINDOWS-KURULUM.md', ARTIFACTS)
        metadata = {'bundleIdentifier': info['CFBundleIdentifier'],
                    'minimumIOS': info['MinimumOSVersion'],
                    'signed': False, 'simulatorTests': 'passed',
                    'physicalDeviceTest': 'not run'}
        (ARTIFACTS / 'build-info.json').write_text(json.dumps(metadata, indent=2), encoding='utf-8')
        print('IPA built and checked. It must be signed locally by AltStore before installation.')
    finally:
        if results.exists():
            run(['ditto', '-c', '-k', '--keepParent', results, DIAGNOSTICS / 'LexiWallTests.xcresult.zip'])


if __name__ == '__main__':
    main()
