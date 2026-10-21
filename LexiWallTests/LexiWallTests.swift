import XCTest
@testable import LexiWall

final class LexiWallTests: XCTestCase {
    @MainActor private func makeStore() throws -> LibraryStore {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        addTeardownBlock { try? FileManager.default.removeItem(at: directory) }
        return try LibraryStore(directory: directory)
    }
    func testCanonicalKeys() {
        XCTAssertEqual(Lexeme.key("  BY   the WAY \n"), "by the way")
        XCTAssertEqual(Lexeme.key("DON’T"), "don't")
    }
    func testInterruptedExportKeepsExactRemainingSelection() {
        let plan = ExportPlan(keys: ["home", "house", "room"], theme: "midnight")
        XCTAssertEqual(plan.remaining(excluding: ["home", "unrelated"]), ["house", "room"])
        XCTAssertEqual(plan.remaining(excluding: ["home", "house", "room"]), [])
    }
    @MainActor func testSeedHasEnoughCompleteUniqueCards() throws {
        let store = try makeStore()
        XCTAssertEqual(store.seed.count, 360)
        XCTAssertTrue(store.seed.allSatisfy(\.isUsable))
        XCTAssertEqual(Set(store.seed.map(\.id)).count, store.seed.count)
        XCTAssertTrue(store.seed.contains { $0.id == "by the way" })
        XCTAssertTrue(store.seed.contains { !$0.secondary.isEmpty })
    }
    @MainActor func testAllThreeBatchSizesHaveNoDuplicates() throws {
        let store = try makeStore()
        for count in [72, 168, 336] {
            let batch = try Selection.batch(store.items, count: count, filter: SelectionFilter(), excluded: [])
            XCTAssertEqual(batch.count, count)
            XCTAssertEqual(Set(batch.map(\.id)).count, count)
        }
    }
    @MainActor func testHistoryAndKnownItemsAreExcluded() throws {
        let store = try makeStore()
        let first = try Selection.batch(store.items, count: 168, filter: SelectionFilter(), excluded: [])
        let excluded = Set(first.map(\.id))
        let second = try Selection.batch(store.items, count: 168, filter: SelectionFilter(), excluded: excluded)
        XCTAssertTrue(excluded.isDisjoint(with: second.map(\.id)))
    }
    @MainActor func testInsufficientPoolDoesNotRepeat() throws {
        let store = try makeStore()
        XCTAssertThrowsError(try Selection.batch(store.items, count: 336, filter: SelectionFilter(), excluded: Set(store.items.prefix(30).map(\.id))))
        XCTAssertThrowsError(try Selection.batch(store.items, count: 0, filter: SelectionFilter(), excluded: []))
    }
    @MainActor func testFiltersAndEmptyFilters() throws {
        let store = try makeStore()
        var filter = SelectionFilter()
        filter.levels = [.b1]; filter.categories = [.expressions]
        let result = Selection.available(store.items, filter: filter, excluded: [])
        XCTAssertFalse(result.isEmpty)
        XCTAssertTrue(result.allSatisfy { $0.level == .b1 && $0.category == .expressions })
        filter.levels = []
        XCTAssertTrue(Selection.available(store.items, filter: filter, excluded: []).isEmpty)
    }
    @MainActor func testPersistenceKeepsHistoryAndPendingJournal() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let first = try LibraryStore(directory: directory)
        try first.update {
            $0.exported = ["home"]; $0.known = ["by the way"]; $0.pending = ["approach"]
            $0.activeExport = ExportPlan(keys: ["home", "approach"], theme: "paper")
        }
        let reopened = try LibraryStore(directory: directory)
        XCTAssertEqual(reopened.state.exported, ["home"])
        XCTAssertEqual(reopened.state.known, ["by the way"])
        XCTAssertEqual(reopened.state.pending, ["approach"])
        XCTAssertEqual(reopened.state.activeExport?.remaining(excluding: reopened.state.exported), ["approach"])
    }
    @MainActor func testCorruptedHistoryIsNotSilentlyReset() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = try LibraryStore(directory: directory)
        try store.update { $0.exported = ["home"] }
        let url = directory.appendingPathComponent("library-v1.json")
        try Data("not json".utf8).write(to: url)
        XCTAssertThrowsError(try LibraryStore(directory: directory))
        XCTAssertEqual(try String(contentsOf: url, encoding: .utf8), "not json")
    }
    @MainActor func testEverySeedLayoutFitsAllThemes() throws {
        let store = try makeStore()
        for item in store.seed {
            for theme in WallpaperTheme.allCases {
                let layout = try WallpaperRenderer.layout(item, theme: theme)
                for rect in layout.rects {
                    XCTAssertTrue(WallpaperRenderer.safeContent.contains(rect), item.term)
                    XCTAssertGreaterThanOrEqual(rect.minY, 860)
                    XCTAssertLessThanOrEqual(rect.maxY, 2250)
                }
            }
        }
    }
    @MainActor func testImagePixelsAndFilename() throws {
        for theme in WallpaperTheme.allCases {
            let image = try WallpaperRenderer.image(.preview, theme: theme)
            XCTAssertEqual(image.cgImage?.width, 1206)
            XCTAssertEqual(image.cgImage?.height, 2622)
            XCTAssertNotNil(image.jpegData(compressionQuality: 0.94))
        }
        XCTAssertEqual(WallpaperRenderer.fileName(for: "home"), WallpaperRenderer.fileName(for: "home"))
        XCTAssertNotEqual(WallpaperRenderer.fileName(for: "home"), WallpaperRenderer.fileName(for: "house"))
    }
}
