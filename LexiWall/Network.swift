import Foundation

enum SourceError: LocalizedError {
    case http(Int)
    var errorDescription: String? {
        switch self {
        case .http(429): return "Servisin istek sınırına ulaşıldı. Daha sonra tekrar deneyin."
        case .http(401), .http(403): return "Servis erişimi reddedildi veya API anahtarı istiyor. Yerel içerikle devam edebilirsiniz."
        case .http(let code): return "Kaynak yanıtı: HTTP \(code)."
        }
    }
}

struct DatamuseWord: Decodable {
    var word: String
    var tags: [String]?
    var frequency: Double { tags?.compactMap { $0.hasPrefix("f:") ? Double($0.dropFirst(2)) : nil }.first ?? 0 }
}

struct DictionaryEntry: Decodable {
    struct License: Decodable { var name: String; var url: String }
    struct Meaning: Decodable {
        struct Definition: Decodable { var definition: String; var example: String? }
        var partOfSpeech: String
        var definitions: [Definition]
    }
    var word: String
    var meanings: [Meaning]
    var license: License?
    var sourceUrls: [String]?
}

struct DraftLexeme {
    var term: String
    var definition: String
    var secondary: [String]
    var example: String
    var level: Level
    var category: Category
    var sources: [Attribution]
}

/// A bounded interactive refresh; repeated refreshes advance discovery and grow the cache.
actor VocabularyAPI {
    private let session: URLSession
    init(session: URLSession? = nil) {
        if let session { self.session = session }
        else {
            let config = URLSessionConfiguration.ephemeral
            config.timeoutIntervalForRequest = 12
            config.timeoutIntervalForResource = 20
            config.waitsForConnectivity = false
            self.session = URLSession(configuration: config)
        }
    }
    private func request<T: Decodable>(_ url: URL, type: T.Type) async throws -> T {
        for attempt in 0...1 {
            try Task.checkCancellation()
            do {
                var request = URLRequest(url: url)
                request.setValue("application/json", forHTTPHeaderField: "Accept")
                let (data, response) = try await session.data(for: request)
                guard let http = response as? HTTPURLResponse else { throw LexiError.message("Geçersiz sunucu yanıtı.") }
                if http.statusCode == 429 { throw SourceError.http(429) }
                if (500...599).contains(http.statusCode), attempt == 0 {
                    try await Task.sleep(for: .milliseconds(800)); continue
                }
                guard http.statusCode == 200 else { throw SourceError.http(http.statusCode) }
                guard data.count < 4_000_000 else { throw LexiError.message("Kaynak yanıtı beklenenden büyük.") }
                return try JSONDecoder().decode(T.self, from: data)
            } catch let error as URLError where attempt == 0 && [.timedOut, .networkConnectionLost].contains(error.code) {
                try await Task.sleep(for: .milliseconds(800))
            }
        }
        throw LexiError.message("Kaynağa ulaşılamadı.")
    }

    func discover(category: Category, round: Int) async throws -> [DatamuseWord] {
        var components = URLComponents(string: "https://api.datamuse.com/words")!
        let prefixes = Array("abcdefghijklmnopqrstuvwxyz")
        var params = [URLQueryItem(name: "md", value: "f"), URLQueryItem(name: "max", value: "600")]
        if category == .expressions {
            let patterns = ["* *", "* the *", "in *", "on *", "at *", "by *", "take *", "get *", "* of *"]
            params.append(URLQueryItem(name: "sp", value: patterns[round % patterns.count]))
        } else if round % 2 == 0 {
            params.append(URLQueryItem(name: "ml", value: category.query))
            params.append(URLQueryItem(name: "topics", value: category.query))
        } else {
            params.append(URLQueryItem(name: "sp", value: "\(prefixes[(round / 2) % prefixes.count]) *".replacingOccurrences(of: " ", with: "")))
            params.append(URLQueryItem(name: "topics", value: category.query))
        }
        components.queryItems = params
        let words = try await request(components.url!, type: [DatamuseWord].self)
        return words.filter { word in
            word.frequency >= 0.2 && (2...40).contains(word.word.count) &&
            word.word.range(of: "^[A-Za-z][A-Za-z '\\-]+$", options: .regularExpression) != nil &&
            (category != .expressions || word.word.contains(" "))
        }.sorted { $0.frequency > $1.frequency }
    }

    func draft(_ word: DatamuseWord, category: Category) async throws -> DraftLexeme? {
        let url = URL(string: "https://api.dictionaryapi.dev/api/v2/entries/en")!.appendingPathComponent(word.word)
        let records: [DictionaryEntry]
        do { records = try await request(url, type: [DictionaryEntry].self) }
        catch SourceError.http(404) { return nil }
        for record in records {
            // Require traceable, licensed examples; don't invent a sentence for an unknown sense.
            guard Lexeme.key(record.word) == Lexeme.key(word.word),
                  let license = record.license,
                  let source = record.sourceUrls?.first, source.hasPrefix("https://"),
                  license.url.hasPrefix("https://") else { continue }
            let definitions = record.meanings.flatMap(\.definitions)
            guard let selected = definitions.first(where: {
                guard let example = $0.example else { return false }
                let pattern = "(?i)\\b" + NSRegularExpression.escapedPattern(for: word.word) + "\\b"
                return (12...180).contains(example.count) && example.range(of: pattern, options: .regularExpression) != nil && (8...160).contains($0.definition.count)
            }), let example = selected.example else { continue }
            var seen: Set<String> = [selected.definition]
            let secondary = definitions.filter { (8...115).contains($0.definition.count) && seen.insert($0.definition).inserted }.prefix(2).map(\.definition)
            let level: Level = word.frequency >= 100 ? .a1 : word.frequency >= 25 ? .a2 : word.frequency >= 5 ? .b1 : word.frequency >= 1 ? .b2 : .c1
            return DraftLexeme(term: word.word, definition: selected.definition, secondary: secondary,
                example: example, level: level, category: word.word.contains(" ") ? .expressions : category,
                sources: [Attribution(name: "Wiktionary / Free Dictionary API", url: source, license: license.name, licenseURL: license.url)])
        }
        return nil
    }
}
