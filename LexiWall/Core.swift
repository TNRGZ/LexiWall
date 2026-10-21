import Foundation

enum Level: String, Codable, CaseIterable, Identifiable {
    case a1 = "A1", a2 = "A2", b1 = "B1", b2 = "B2", c1 = "C1"
    var id: String { rawValue }
}

enum Category: String, Codable, CaseIterable, Identifiable {
    case daily, work, travel, technology, expressions
    var id: String { rawValue }
    var title: String {
        switch self {
        case .daily: return "Günlük yaşam"
        case .work: return "İş hayatı"
        case .travel: return "Seyahat"
        case .technology: return "Teknoloji"
        case .expressions: return "Kalıplar"
        }
    }
    var query: String {
        switch self {
        case .daily: return "everyday life"
        case .work: return "business workplace"
        case .travel: return "travel journey"
        case .technology: return "computer technology"
        case .expressions: return "conversation expression"
        }
    }
}

struct Attribution: Codable, Hashable {
    var name: String
    var url: String
    var license: String
    var licenseURL: String
}

struct Lexeme: Codable, Identifiable, Hashable {
    var term: String
    var meaning: String
    var secondary: [String]
    var explanation: String
    var example: String
    var exampleTR: String
    var level: Level
    var category: Category
    var isEstimated: Bool
    var sources: [Attribution]
    var id: String { Self.key(term) }
    static func key(_ value: String) -> String {
        value.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "en_US_POSIX"))
            .replacingOccurrences(of: "’", with: "'")
            .split(whereSeparator: { $0.isWhitespace }).joined(separator: " ")
    }
    var isUsable: Bool {
        !id.isEmpty && term.count <= 40 && !meaning.isEmpty && meaning.count <= 100 &&
        !explanation.isEmpty && explanation.count <= 220 &&
        !example.isEmpty && example.count <= 180 &&
        !exampleTR.isEmpty && exampleTR.count <= 220 &&
        secondary.count <= 2 && secondary.allSatisfy { !$0.isEmpty && $0.count <= 160 }
    }
    static let preview = Lexeme(
        term: "by the way", meaning: "bu arada", secondary: [],
        explanation: "Konuşmaya konuyla bağlantılı ek bir bilgi veya yeni bir konu ekler.",
        example: "By the way, I found your keys.", exampleTR: "Bu arada, anahtarlarını buldum.",
        level: .a2, category: .expressions, isEstimated: false, sources: [])
}

struct SelectionFilter {
    var levels = Set(Level.allCases)
    var categories = Set(Category.allCases)
    func includes(_ item: Lexeme) -> Bool {
        levels.contains(item.level) && categories.contains(item.category)
    }
}

enum Selection {
    static func available(_ items: [Lexeme], filter: SelectionFilter, excluded: Set<String>) -> [Lexeme] {
        var seen = excluded
        return items.filter { $0.isUsable && filter.includes($0) && seen.insert($0.id).inserted }
    }
    static func batch(_ items: [Lexeme], count: Int, filter: SelectionFilter, excluded: Set<String>) throws -> [Lexeme] {
        let pool = available(items, filter: filter, excluded: excluded)
        guard [72, 168, 336].contains(count) else { throw LexiError.message("Geçersiz görsel sayısı.") }
        guard pool.count >= count else {
            throw LexiError.message("Bu filtrelerde \(pool.count) yeni kart var; \(count) kart için yeterli değil. Filtreleri genişletin veya internetten yeni içerik ekleyin.")
        }
        return Array(pool.shuffled().prefix(count))
    }
}

enum LexiError: LocalizedError {
    case message(String)
    var errorDescription: String? {
        switch self { case .message(let text): return text }
    }
}

struct ExportPlan: Codable {
    var keys: [String]
    var theme: String
    func remaining(excluding saved: Set<String>) -> [String] { keys.filter { !saved.contains($0) } }
}

struct LibraryState: Codable {
    var schema = 1
    var online: [Lexeme] = []
    var exported: Set<String> = []
    var known: Set<String> = []
    var pending: Set<String> = []
    var discoveryRound = 0
    var lastSavedCount = 0
    var activeExport: ExportPlan?
}

@MainActor
final class LibraryStore {
    private(set) var state: LibraryState
    private let url: URL
    let seed: [Lexeme]

    init(directory: URL? = nil, seedURL: URL? = Bundle.main.url(forResource: "seed", withExtension: "json")) throws {
        guard let seedURL else { throw LexiError.message("Yerel kelime dosyası bulunamadı.") }
        seed = try JSONDecoder().decode([Lexeme].self, from: Data(contentsOf: seedURL))
        guard seed.count >= 336, seed.allSatisfy(\.isUsable), Set(seed.map(\.id)).count == seed.count else {
            throw LexiError.message("Yerel kelime dosyası doğrulanamadı.")
        }
        let root: URL
        if let directory { root = directory }
        else { root = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent("LexiWall", isDirectory: true) }
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        url = root.appendingPathComponent("library-v1.json")
        if FileManager.default.fileExists(atPath: url.path) {
            do {
                state = try JSONDecoder().decode(LibraryState.self, from: Data(contentsOf: url))
                guard state.schema == 1 else { throw LexiError.message("Bilinmeyen kayıt sürümü.") }
            } catch {
                // Never silently erase history: that would create duplicate wallpapers.
                throw LexiError.message("Kelime geçmişi okunamadı. Veriler korunuyor. Dosyaları yedekleyip uygulamayı yeniden kurun. \(error.localizedDescription)")
            }
        } else { state = LibraryState() }
    }

    var items: [Lexeme] {
        var seen = Set<String>()
        return (seed + state.online).filter { $0.isUsable && seen.insert($0.id).inserted }
    }
    func update(_ mutate: (inout LibraryState) -> Void) throws {
        var next = state
        mutate(&next)
        let data = try JSONEncoder().encode(next)
        try data.write(to: url, options: .atomic)
        state = next
    }
}
