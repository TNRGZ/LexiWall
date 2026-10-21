import Photos
import UIKit
import UniformTypeIdentifiers

@MainActor
final class PhotoExporter {
    static let albumTitle = "LexiWall Hourly"
    private let library = PHPhotoLibrary.shared()

    func authorize() async throws {
        var status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        if status == .notDetermined { status = await PHPhotoLibrary.requestAuthorization(for: .readWrite) }
        guard status == .authorized else {
            throw LexiError.message("Albüm oluşturup bulabilmek için Fotoğraflar’da Tam Erişim gerekli. Ayarlar → Uygulamalar → LexiWall → Fotoğraflar → Tam Erişim yolunu kullanın. Sınırlı erişim yeterli değil.")
        }
    }

    func album() async throws -> PHAssetCollection {
        let options = PHFetchOptions()
        options.predicate = NSPredicate(format: "title = %@", Self.albumTitle)
        if let album = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .albumRegular, options: options).firstObject { return album }
        let title = Self.albumTitle
        try await library.performChanges { @Sendable in
            PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: title)
        }
        guard let album = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .albumRegular, options: options).firstObject else {
            throw LexiError.message("Fotoğraflar albümü oluşturulamadı.")
        }
        return album
    }

    /// Recover the small write-ahead journal after termination between a Photos commit and a disk write.
    func reconcile(store: LibraryStore, album: PHAssetCollection) throws {
        guard !store.state.pending.isEmpty else { return }
        var files = Set<String>()
        PHAsset.fetchAssets(in: album, options: nil).enumerateObjects { asset, _, _ in
            for resource in PHAssetResource.assetResources(for: asset) { files.insert(resource.originalFilename) }
        }
        let recovered = Set(store.state.pending.filter { files.contains(WallpaperRenderer.fileName(for: $0)) })
        try store.update { state in
            state.exported.formUnion(recovered)
            state.pending.removeAll()
        }
    }

    func save(files: [URL], album: PHAssetCollection) async throws {
        let albumIdentifier = album.localIdentifier
        // PhotoKit runs this block on its own queue, not on MainActor.
        try await library.performChanges { @Sendable in
            guard let collection = PHAssetCollection.fetchAssetCollections(withLocalIdentifiers: [albumIdentifier], options: nil).firstObject,
                  let change = PHAssetCollectionChangeRequest(for: collection) else { return }
            let placeholders = files.compactMap { file -> PHObjectPlaceholder? in
                let request = PHAssetCreationRequest.forAsset()
                let options = PHAssetResourceCreationOptions()
                options.originalFilename = file.lastPathComponent
                options.uniformTypeIdentifier = UTType.jpeg.identifier
                request.addResource(with: .photo, fileURL: file, options: options)
                return request.placeholderForCreatedAsset
            }
            change.addAssets(placeholders as NSArray)
        }
        // Verify album membership before advancing history, including unexpected no-op changes.
        var savedNames = Set<String>()
        PHAsset.fetchAssets(in: album, options: nil).enumerateObjects { asset, _, _ in
            PHAssetResource.assetResources(for: asset).forEach { savedNames.insert($0.originalFilename) }
        }
        guard files.allSatisfy({ savedNames.contains($0.lastPathComponent) }) else {
            throw LexiError.message("Albüm kaydı doğrulanamadı. Yeniden denemede kayıt günlüğü kontrol edilecek.")
        }
    }
}
