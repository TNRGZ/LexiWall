import SwiftUI
import Translation
import UIKit

@MainActor
final class AppModel: ObservableObject {
    @Published var items: [Lexeme] = []
    @Published var filter = SelectionFilter()
    @Published var theme: WallpaperTheme = .midnight
    @Published var count = 168
    @Published var status = "Çevrimdışı havuz hazır."
    @Published var errorMessage: String?
    @Published var busy = false
    @Published var progress = 0.0
    @Published var saved = 0
    @Published var translationConfiguration: TranslationSession.Configuration?
    @Published var preview: UIImage?
    @Published var revision = 0
    @Published var showGuide = false
    private(set) var store: LibraryStore?
    private let api = VocabularyAPI()
    private let exporter = PhotoExporter()
    private var operation: Task<Void, Never>?
    private var stopRequested = false
    private var translating = false
    private var translationRunning = false
    private var exporting = false
    private var pendingDrafts: [DraftLexeme] = []
    private var roundCategory = 0

    init() {
        do { store = try LibraryStore(); sync() }
        catch { errorMessage = error.localizedDescription; status = "Yerel veriler açılamadı." }
        updatePreview()
    }
    var excluded: Set<String> {
        guard let store else { return [] }
        return store.state.exported.union(store.state.known).union(store.state.pending)
    }
    var available: [Lexeme] { Selection.available(items, filter: filter, excluded: excluded) }
    var exportedCount: Int { store?.state.exported.count ?? 0 }
    var hasUnfinishedExport: Bool { store?.state.activeExport != nil }
    var exportTitle: String {
        if let store, let plan = store.state.activeExport {
            return "Kalan \(plan.remaining(excluding: store.state.exported).count) görseli kaydet"
        }
        return "\(count) görseli Fotoğraflar’a kaydet"
    }
    func sync() { items = store?.items ?? []; revision += 1 }
    func updatePreview(_ item: Lexeme = .preview) {
        do { preview = try WallpaperRenderer.image(item, theme: theme) }
        catch { errorMessage = error.localizedDescription }
    }
    func markKnown(_ item: Lexeme) {
        guard !hasUnfinishedExport else {
            errorMessage = "Bu işlemden önce yarım kalan görsel paketini tamamlayın."
            return
        }
        do { try store?.update { $0.known.insert(item.id) }; sync() }
        catch { errorMessage = error.localizedDescription }
    }
    func resetHistory() {
        do {
            guard store?.state.pending.isEmpty == true else { throw LexiError.message("Önce yarım kalan kaydı devam ettirerek doğrulayın.") }
            try store?.update { $0.exported.removeAll(); $0.known.removeAll(); $0.activeExport = nil }
            sync(); status = "Geçmiş sıfırlandı; albümdeki fotoğraflar korundu."
        } catch { errorMessage = error.localizedDescription }
    }
    func stop() {
        stopRequested = true
        if translating {
            translationConfiguration = nil
            if !translationRunning {
                translating = false; busy = false; pendingDrafts = []
                status = "Arama durduruldu; mevcut içerikler korundu."
                return
            }
        } else if !exporting {
            operation?.cancel()
        }
        status = "Durduruluyor; devam eden kayıt tamamlanacak…"
    }

    func refresh() {
        guard !busy, let store else { return }
        busy = true; stopRequested = false; progress = 0; saved = 0
        pendingDrafts = []; status = "İnternetten yeni kelimeler aranıyor…"
        operation = Task {
            do {
                let categories = Category.allCases.filter { filter.categories.contains($0) }
                guard !categories.isEmpty else { throw LexiError.message("En az bir kategori seçin.") }
                let category = categories[roundCategory % categories.count]
                roundCategory += 1
                let round = store.state.discoveryRound
                try store.update { $0.discoveryRound += 1 }
                let words = try await api.discover(category: category, round: round)
                let existing = Set(items.map(\.id)).union(excluded)
                let candidates = Array(words.filter { !existing.contains(Lexeme.key($0.word)) }.prefix(45))
                var failures = 0
                for (index, word) in candidates.enumerated() {
                    try Task.checkCancellation()
                    if stopRequested { throw CancellationError() }
                    status = "Sözlük ve örnek cümle: \(index + 1)/\(candidates.count)"
                    do {
                        if let draft = try await api.draft(word, category: category) { pendingDrafts.append(draft) }
                        failures = 0
                    } catch {
                        if Task.isCancelled { throw CancellationError() }
                        if case SourceError.http(let code) = error, [401, 403, 429].contains(code) { throw error }
                        failures += 1
                        if failures >= 5 { break }
                    }
                    progress = Double(index + 1) / Double(max(1, candidates.count)) * 0.5
                    if pendingDrafts.count >= 24 { break }
                    try await Task.sleep(for: .milliseconds(180))
                }
                guard !pendingDrafts.isEmpty else {
                    throw LexiError.message("Bu aramada eksiksiz yeni kart bulunamadı veya servis kullanılamıyor. Yerel ve önbellekteki içerikler hazır; yeniden arama farklı adayları dener.")
                }
                let availability = await LanguageAvailability().status(from: Locale.Language(identifier: "en"), to: Locale.Language(identifier: "tr"))
                guard availability != .unsupported else { throw LexiError.message("Bu cihazda İngilizce–Türkçe çeviri desteklenmiyor. Yerel içerikle devam edebilirsiniz.") }
                if stopRequested { throw CancellationError() }
                status = "Apple çevirisi hazırlanıyor; gerekirse dil paketlerini onaylayın."
                translating = true
                translationConfiguration = .init(source: Locale.Language(identifier: "en"), target: Locale.Language(identifier: "tr"))
            } catch {
                finish(error: error)
            }
        }
    }

    func translate(using session: TranslationSession) async {
        guard translating, let store else { return }
        translationRunning = true
        defer { translationConfiguration = nil; translating = false; translationRunning = false; busy = false; pendingDrafts = [] }
        do {
            try await session.prepareTranslation()
            var added = 0
            var skipped = 0
            let drafts = pendingDrafts
            for (index, draft) in drafts.enumerated() {
                try Task.checkCancellation()
                if stopRequested { throw CancellationError() }
                status = "Türkçe içerik hazırlanıyor: \(index + 1)/\(drafts.count)"
                let texts = [draft.term, draft.definition, draft.example] + draft.secondary
                let requests = texts.enumerated().map { TranslationSession.Request(sourceText: $0.element, clientIdentifier: String($0.offset)) }
                do {
                    let responses = try await session.translations(from: requests)
                    var translated: [String: String] = [:]
                    for response in responses {
                        if let key = response.clientIdentifier { translated[key] = response.targetText.trimmingCharacters(in: .whitespacesAndNewlines) }
                    }
                    guard let meaning = translated["0"], let explanation = translated["1"], let exampleTR = translated["2"],
                          Lexeme.key(explanation) != Lexeme.key(draft.definition), Lexeme.key(exampleTR) != Lexeme.key(draft.example) else { skipped += 1; continue }
                    let item = Lexeme(term: draft.term, meaning: meaning, secondary: draft.secondary.indices.compactMap { translated[String($0 + 3)] },
                        explanation: explanation, example: draft.example, exampleTR: exampleTR,
                        level: draft.level, category: draft.category, isEstimated: true, sources: draft.sources)
                    guard item.isUsable, (try? WallpaperRenderer.layout(item, theme: theme)) != nil else { skipped += 1; continue }
                    try store.update { state in
                        if !state.online.contains(where: { $0.id == item.id }) { state.online.append(item) }
                    }
                    added += 1
                } catch {
                    if Task.isCancelled || stopRequested { throw CancellationError() }
                    if error is CocoaError { throw error }
                    // Keep earlier successful items. A failed translation must not become a partial card.
                    skipped += 1
                    if skipped >= 5 { break }
                }
                progress = 0.5 + Double(index + 1) / Double(drafts.count) * 0.5
            }
            sync()
            status = "\(added) yeni kart eklendi. \(skipped) kart atlandı. Çevrimdışı toplam: \(items.count)."
        } catch { finish(error: error) }
    }

    func export() {
        guard !busy, let store else { return }
        busy = true; exporting = true; stopRequested = false; saved = 0; progress = 0
        status = "Fotoğraflar izni kontrol ediliyor…"
        operation = Task {
            let oldIdle = UIApplication.shared.isIdleTimerDisabled
            UIApplication.shared.isIdleTimerDisabled = true
            defer { UIApplication.shared.isIdleTimerDisabled = oldIdle; busy = false; exporting = false }
            do {
                try await exporter.authorize()
                let album = try await exporter.album()
                try exporter.reconcile(store: store, album: album)
                sync()
                let plan: ExportPlan
                if let active = store.state.activeExport { plan = active }
                else {
                    let selection = try Selection.batch(items, count: count, filter: filter, excluded: excluded)
                    plan = ExportPlan(keys: selection.map(\.id), theme: theme.rawValue)
                    try store.update { $0.activeExport = plan }
                }
                let lookup = Dictionary(uniqueKeysWithValues: items.map { ($0.id, $0) })
                let remaining = plan.remaining(excluding: store.state.exported)
                let batch = remaining.compactMap { lookup[$0] }
                guard batch.count == remaining.count, let selectedTheme = WallpaperTheme(rawValue: plan.theme) else {
                    throw LexiError.message("Yarım kalan paketin içeriği bulunamadı. Geçmişi sıfırlamadan önce uygulama verilerini yedekleyin.")
                }
                let total = plan.keys.count
                saved = total - batch.count
                progress = Double(saved) / Double(max(total, 1))
                let directory = FileManager.default.temporaryDirectory.appendingPathComponent("LexiWallExport", isDirectory: true)
                // Only our own temporary folder is cleaned; Photos assets are never deleted.
                if FileManager.default.fileExists(atPath: directory.path) { try FileManager.default.removeItem(at: directory) }
                try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
                defer { try? FileManager.default.removeItem(at: directory) }
                for start in stride(from: 0, to: batch.count, by: 6) {
                    if stopRequested || Task.isCancelled { throw CancellationError() }
                    let chunk = Array(batch[start..<min(start + 6, batch.count)])
                    var files: [URL] = []
                    for item in chunk {
                        let file = directory.appendingPathComponent(WallpaperRenderer.fileName(for: item.id))
                        try autoreleasepool {
                            let image = try WallpaperRenderer.image(item, theme: selectedTheme)
                            guard let data = image.jpegData(compressionQuality: 0.94) else { throw LexiError.message("Görsel oluşturulamadı.") }
                            try data.write(to: file, options: .atomic)
                        }
                        files.append(file)
                        await Task.yield()
                    }
                    try store.update { $0.pending = Set(chunk.map(\.id)) }
                    status = "Kaydediliyor: \(saved)/\(total)"
                    try await exporter.save(files: files, album: album)
                    saved += chunk.count
                    try store.update { state in
                        state.exported.formUnion(chunk.map(\.id)); state.pending.removeAll(); state.lastSavedCount = saved
                    }
                    for file in files { try? FileManager.default.removeItem(at: file) }
                    progress = Double(saved) / Double(total)
                    sync()
                }
                try store.update { $0.activeExport = nil }
                sync()
                status = "\(saved) görsel ‘\(PhotoExporter.albumTitle)’ albümüne kaydedildi."
                showGuide = true
            } catch { finish(error: error) }
        }
    }
    private func finish(error: Error) {
        sync(); busy = false; translating = false; translationConfiguration = nil
        if error is CancellationError || stopRequested {
            status = "Durduruldu. \(saved) kaydedilmiş görsel korundu."
        } else {
            errorMessage = error.localizedDescription
            status = saved > 0 ? "\(saved) görsel kaydedildi; kalan işlem tamamlanamadı." : "İşlem tamamlanamadı; mevcut içerikler korundu."
        }
    }
}
