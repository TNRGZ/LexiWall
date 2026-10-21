import XCTest
@testable import LexiWall

private final class StubProtocol: URLProtocol {
    // Tests are serialized by default; each test owns and resets this handler.
    static var handler: ((URLRequest) -> (Int, Data))?
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        guard let handler = Self.handler, let url = request.url else { return }
        let (status, body) = handler(request)
        let response = HTTPURLResponse(url: url, statusCode: status, httpVersion: nil, headerFields: ["Content-Type": "application/json"])!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: body)
        client?.urlProtocolDidFinishLoading(self)
    }
    override func stopLoading() {}
}

final class NetworkTests: XCTestCase {
    private func api(status: Int, json: String) -> VocabularyAPI {
        StubProtocol.handler = { _ in (status, Data(json.utf8)) }
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [StubProtocol.self]
        return VocabularyAPI(session: URLSession(configuration: config))
    }
    override func tearDown() { StubProtocol.handler = nil; super.tearDown() }
    func testFrequencyFilteringAndSorting() async throws {
        let api = api(status: 200, json: #"[{"word":"rare","tags":["f:0.01"]},{"word":"home","tags":["f:100"]},{"word":"garden","tags":["f:10"]},{"word":"123","tags":["f:90"]}]"#)
        let result = try await api.discover(category: .daily, round: 0)
        XCTAssertEqual(result.map(\.word), ["home", "garden"])
    }
    func testMissingExampleOrAttributionSkipsCard() async throws {
        let api = api(status: 200, json: #"[{"word":"home","meanings":[{"partOfSpeech":"noun","definitions":[{"definition":"A place to live."}]}]}]"#)
        let draft = try await api.draft(DatamuseWord(word: "home", tags: ["f:100"]), category: .daily)
        XCTAssertNil(draft)
    }
    func testMissingDictionaryWordIsNotAServiceOutage() async throws {
        let api = api(status: 404, json: #"{"title":"No Definitions Found"}"#)
        let result = try await api.draft(DatamuseWord(word: "a missing phrase", tags: []), category: .expressions)
        XCTAssertNil(result)
    }
    func testValidExampleUsesMatchingSense() async throws {
        let api = api(status: 200, json: #"[{"word":"home","license":{"name":"CC BY-SA 3.0","url":"https://creativecommons.org/licenses/by-sa/3.0"},"sourceUrls":["https://en.wiktionary.org/wiki/home"],"meanings":[{"partOfSpeech":"noun","definitions":[{"definition":"A place where someone lives.","example":"Our home is near the sea."}]}]}]"#)
        let draft = try await api.draft(DatamuseWord(word: "home", tags: ["f:100"]), category: .daily)
        XCTAssertEqual(draft?.example, "Our home is near the sea.")
        XCTAssertEqual(draft?.level, .a1)
    }
    func testRateLimitAndMalformedJSONThrow() async {
        for (status, json) in [(429,"{}"), (200,"not-json")] {
            do { _ = try await api(status: status, json: json).discover(category: .daily, round: 0); XCTFail("Expected failure") }
            catch { XCTAssertFalse(error.localizedDescription.isEmpty) }
        }
    }
}
