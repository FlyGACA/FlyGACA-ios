import CoreModels
import XCTest

@testable import ContentKit

/// ContentRefresher is pure Foundation (no network in `swift test`) — these
/// tests drive it through a fake transport so they stay hermetic and fast.
final class ContentRefresherTests: XCTestCase {
    private var bundledDirectory: URL!
    private var cacheDirectory: URL!

    override func setUpWithError() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("flygaca-refresh-\(UUID().uuidString)", isDirectory: true)
        bundledDirectory = root.appendingPathComponent("bundled", isDirectory: true)
        cacheDirectory = root.appendingPathComponent("cache", isDirectory: true)
        try FileManager.default.createDirectory(at: bundledDirectory, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: bundledDirectory.deletingLastPathComponent())
    }

    private func writeBundledFixture(generated: String = "v1") throws {
        try Data(
            """
            { "contentVersion": "\(generated)", "module": {
              "id": "aip", "kind": "subject", "status": "live", "access": "paid",
              "bankIds": ["aip-ais"] } }
            """.utf8
        ).write(to: bundledDirectory.appendingPathComponent("module.json"))
        try Data(
            """
            { "generated": "\(generated)",
              "exam": { "questions": 25, "minutes": 30, "passMark": 75 },
              "banks": [ { "id": "aip-ais", "title": "AIP & AIS", "desc": "", "questions": [
                { "q": "One?", "options": ["A", "B"], "answer": 0, "explain": "e" }
              ] } ] }
            """.utf8
        ).write(to: bundledDirectory.appendingPathComponent("quiz.json"))
    }

    private func makeStore() -> ContentStore {
        ContentStore(bundledDirectory: bundledDirectory, cacheDirectory: cacheDirectory, moduleID: "aip")
    }

    // MARK: - Fake transport

    private enum FakeError: Error { case exhausted }

    private actor FakeTransport: ContentTransporting {
        private var responses: [ContentFetchResult]
        private(set) var requestedETags: [String?] = []

        init(_ responses: [ContentFetchResult]) {
            self.responses = responses
        }

        func fetch(_ url: URL, ifNoneMatch etag: String?) async throws -> ContentFetchResult {
            requestedETags.append(etag)
            guard !responses.isEmpty else { throw FakeError.exhausted }
            return responses.removeFirst()
        }
    }

    private func remoteCorpusData(generated: String, extraBankID: String? = nil) -> Data {
        var banksJSON = """
            { "id": "aip-ais", "title": "AIP & AIS", "desc": "", "questions": [
                { "q": "One?", "options": ["A", "B"], "answer": 0, "explain": "e" },
                { "q": "Two?", "options": ["A", "B"], "answer": 1, "explain": "e" }
              ] }
            """
        if let extraBankID {
            banksJSON += """
                , { "id": "\(extraBankID)", "title": "Other module", "desc": "", "questions": [
                    { "q": "Foreign?", "options": ["A", "B"], "answer": 0, "explain": "e" }
                  ] }
                """
        }
        return Data(
            """
            { "generated": "\(generated)",
              "exam": { "questions": 25, "minutes": 30, "passMark": 75 },
              "banks": [ \(banksJSON) ] }
            """.utf8
        )
    }

    // MARK: - Tests

    func testNotModifiedLeavesCacheUntouched() async throws {
        try writeBundledFixture()
        let store = makeStore()
        let transport = FakeTransport([ContentFetchResult(statusCode: 304, data: nil, etag: nil)])
        let refresher = ContentRefresher(transport: transport, corpusURL: URL(string: "https://flygaca.com/data/quiz.json")!)

        let outcome = try await refresher.refresh(store: store)

        XCTAssertEqual(outcome, .notModified)
        XCTAssertFalse(FileManager.default.fileExists(atPath: cacheDirectory.path))
    }

    func testUpToDateWhenGeneratedStampMatches() async throws {
        try writeBundledFixture(generated: "v1")
        let store = makeStore()
        let transport = FakeTransport([
            ContentFetchResult(statusCode: 200, data: remoteCorpusData(generated: "v1"), etag: "etag-1")
        ])
        let refresher = ContentRefresher(transport: transport, corpusURL: URL(string: "https://flygaca.com/data/quiz.json")!)

        let outcome = try await refresher.refresh(store: store)

        XCTAssertEqual(outcome, .upToDate)
        XCTAssertFalse(FileManager.default.fileExists(atPath: cacheDirectory.appendingPathComponent("quiz.json").path))
    }

    func testRefreshedCorpusIsFilteredValidatedAndPreferredOnNextLoad() async throws {
        try writeBundledFixture(generated: "v1")
        let store = makeStore()
        let transport = FakeTransport([
            ContentFetchResult(
                statusCode: 200,
                data: remoteCorpusData(generated: "v2", extraBankID: "ppl-1"),
                etag: "etag-2")
        ])
        let refresher = ContentRefresher(transport: transport, corpusURL: URL(string: "https://flygaca.com/data/quiz.json")!)

        let outcome = try await refresher.refresh(store: store)

        guard case .refreshed(let generated) = outcome else {
            return XCTFail("expected .refreshed, got \(outcome)")
        }
        XCTAssertEqual(generated, "v2")

        let reloaded = try store.load()
        XCTAssertEqual(reloaded.contentVersion, "v2")
        XCTAssertEqual(reloaded.quiz.banks.map(\.id), ["aip-ais"])
        XCTAssertEqual(reloaded.quiz.banks.first?.questions.count, 2)
        XCTAssertNil(reloaded.quiz.bank(id: "ppl-1"))
        // The manifest itself is untouched — only contentVersion moved.
        XCTAssertEqual(reloaded.manifest.bankIDs, ["aip-ais"])

        let etagPath = cacheDirectory.appendingPathComponent(".corpus-etag")
        XCTAssertEqual(try String(contentsOf: etagPath, encoding: .utf8), "etag-2")
    }

    func testSecondRefreshSendsThePersistedETag() async throws {
        try writeBundledFixture(generated: "v1")
        let store = makeStore()
        let transport = FakeTransport([
            ContentFetchResult(statusCode: 200, data: remoteCorpusData(generated: "v2"), etag: "etag-2"),
            ContentFetchResult(statusCode: 304, data: nil, etag: nil),
        ])
        let refresher = ContentRefresher(transport: transport, corpusURL: URL(string: "https://flygaca.com/data/quiz.json")!)

        _ = try await refresher.refresh(store: store)
        let second = try await refresher.refresh(store: store)

        XCTAssertEqual(second, .notModified)
        let seenETags = await transport.requestedETags
        XCTAssertEqual(seenETags, [nil, "etag-2"])
    }

    func testEmptyModuleSliceThrows() async throws {
        try writeBundledFixture(generated: "v1")
        let store = makeStore()
        let onlyForeignBank = Data(
            """
            { "generated": "v2", "banks": [
              { "id": "ppl-1", "title": "PPL", "desc": "", "questions": [] }
            ] }
            """.utf8
        )
        let transport = FakeTransport([ContentFetchResult(statusCode: 200, data: onlyForeignBank, etag: nil)])
        let refresher = ContentRefresher(transport: transport, corpusURL: URL(string: "https://flygaca.com/data/quiz.json")!)

        do {
            _ = try await refresher.refresh(store: store)
            XCTFail("expected emptyModuleSlice")
        } catch ContentRefreshError.emptyModuleSlice(let moduleID) {
            XCTAssertEqual(moduleID, "aip")
        }
    }

    func testMalformedCorpusThrows() async throws {
        try writeBundledFixture(generated: "v1")
        let store = makeStore()
        let transport = FakeTransport([
            ContentFetchResult(statusCode: 200, data: Data("not json".utf8), etag: nil)
        ])
        let refresher = ContentRefresher(transport: transport, corpusURL: URL(string: "https://flygaca.com/data/quiz.json")!)

        do {
            _ = try await refresher.refresh(store: store)
            XCTFail("expected malformedCorpus")
        } catch ContentRefreshError.malformedCorpus {
            // expected
        }
    }

    func testBadStatusThrows() async throws {
        try writeBundledFixture(generated: "v1")
        let store = makeStore()
        let transport = FakeTransport([ContentFetchResult(statusCode: 500, data: Data(), etag: nil)])
        let refresher = ContentRefresher(transport: transport, corpusURL: URL(string: "https://flygaca.com/data/quiz.json")!)

        do {
            _ = try await refresher.refresh(store: store)
            XCTFail("expected badStatus")
        } catch ContentRefreshError.badStatus(let code) {
            XCTAssertEqual(code, 500)
        }
    }
}
