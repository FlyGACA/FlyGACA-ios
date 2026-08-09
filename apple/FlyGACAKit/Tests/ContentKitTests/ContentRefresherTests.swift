import CoreModels
import CryptoKit
import XCTest

@testable import ContentKit

/// ContentRefresher is pure Foundation (no network in `swift test`) — these
/// tests drive it through a fake transport so they stay hermetic and fast.
/// Every successful-refresh fixture is signed with a throwaway Ed25519 key,
/// mirroring how `quiz.json.sig` is served next to `quiz.json` in production.
final class ContentRefresherTests: XCTestCase {
    private var bundledDirectory: URL!
    private var cacheDirectory: URL!
    private let signingKey = Curve25519.Signing.PrivateKey()

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

    private func makeVerifier() -> CorpusSignatureVerifier {
        CorpusSignatureVerifier(
            base64PublicKey: signingKey.publicKey.rawRepresentation.base64EncodedString())
    }

    private func makeRefresher(
        transport: FakeTransport,
        signatureVerifier: CorpusSignatureVerifier? = nil
    ) -> ContentRefresher {
        ContentRefresher(
            transport: transport,
            corpusURL: URL(string: "https://flygaca.com/data/quiz.json")!,
            signatureVerifier: signatureVerifier ?? makeVerifier())
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

    /// The base64 Ed25519 signature `ContentRefresher` expects at
    /// `quiz.json.sig` — over the exact served bytes, like the publish
    /// pipeline (scripts/sign-corpus.sh).
    private func signatureResult(for data: Data) throws -> ContentFetchResult {
        ContentFetchResult(
            statusCode: 200,
            data: Data(try signingKey.signature(for: data).base64EncodedString().utf8),
            etag: nil)
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
        let refresher = makeRefresher(transport: transport)

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
        let refresher = makeRefresher(transport: transport)

        let outcome = try await refresher.refresh(store: store)

        XCTAssertEqual(outcome, .upToDate)
        XCTAssertFalse(FileManager.default.fileExists(atPath: cacheDirectory.appendingPathComponent("quiz.json").path))
    }

    func testRefreshedCorpusIsFilteredValidatedAndPreferredOnNextLoad() async throws {
        try writeBundledFixture(generated: "v1")
        let store = makeStore()
        let corpus = remoteCorpusData(generated: "v2", extraBankID: "ppl-1")
        let transport = FakeTransport([
            ContentFetchResult(statusCode: 200, data: corpus, etag: "etag-2"),
            try signatureResult(for: corpus),
        ])
        let refresher = makeRefresher(transport: transport)

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
        let corpus = remoteCorpusData(generated: "v2")
        let transport = FakeTransport([
            ContentFetchResult(statusCode: 200, data: corpus, etag: "etag-2"),
            try signatureResult(for: corpus),
            ContentFetchResult(statusCode: 304, data: nil, etag: nil),
        ])
        let refresher = makeRefresher(transport: transport)

        _ = try await refresher.refresh(store: store)
        let second = try await refresher.refresh(store: store)

        XCTAssertEqual(second, .notModified)
        let seenETags = await transport.requestedETags
        // Corpus fetch (no ETag yet), signature fetch (never conditional),
        // then the second corpus fetch with the persisted ETag.
        XCTAssertEqual(seenETags, [nil, nil, "etag-2"])
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
        let transport = FakeTransport([
            ContentFetchResult(statusCode: 200, data: onlyForeignBank, etag: nil),
            try signatureResult(for: onlyForeignBank),
        ])
        let refresher = makeRefresher(transport: transport)

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
        let refresher = makeRefresher(transport: transport)

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
        let refresher = makeRefresher(transport: transport)

        do {
            _ = try await refresher.refresh(store: store)
            XCTFail("expected badStatus")
        } catch ContentRefreshError.badStatus(let code) {
            XCTAssertEqual(code, 500)
        }
    }

    // MARK: - Signature verification

    func testMissingSignatureFileRejectsRefresh() async throws {
        try writeBundledFixture(generated: "v1")
        let store = makeStore()
        let corpus = remoteCorpusData(generated: "v2")
        let transport = FakeTransport([
            ContentFetchResult(statusCode: 200, data: corpus, etag: "etag-2"),
            ContentFetchResult(statusCode: 404, data: nil, etag: nil),
        ])
        let refresher = makeRefresher(transport: transport)

        do {
            _ = try await refresher.refresh(store: store)
            XCTFail("expected invalidSignature")
        } catch ContentRefreshError.invalidSignature {
            // expected
        }
        // The unsigned corpus must never reach the cache.
        XCTAssertFalse(FileManager.default.fileExists(atPath: cacheDirectory.appendingPathComponent("quiz.json").path))
    }

    func testForgedSignatureRejectsRefresh() async throws {
        try writeBundledFixture(generated: "v1")
        let store = makeStore()
        let corpus = remoteCorpusData(generated: "v2")
        // A validly-formed signature, but over different bytes — i.e. forged.
        let forged = try signatureResult(for: remoteCorpusData(generated: "v3"))
        let transport = FakeTransport([
            ContentFetchResult(statusCode: 200, data: corpus, etag: "etag-2"),
            forged,
        ])
        let refresher = makeRefresher(transport: transport)

        do {
            _ = try await refresher.refresh(store: store)
            XCTFail("expected invalidSignature")
        } catch ContentRefreshError.invalidSignature {
            // expected
        }
        XCTAssertFalse(FileManager.default.fileExists(atPath: cacheDirectory.appendingPathComponent("quiz.json").path))
    }

    func testUndecodableSignatureRejectsRefresh() async throws {
        try writeBundledFixture(generated: "v1")
        let store = makeStore()
        let corpus = remoteCorpusData(generated: "v2")
        let transport = FakeTransport([
            ContentFetchResult(statusCode: 200, data: corpus, etag: "etag-2"),
            ContentFetchResult(statusCode: 200, data: Data("%%% not base64 %%%".utf8), etag: nil),
        ])
        let refresher = makeRefresher(transport: transport)

        do {
            _ = try await refresher.refresh(store: store)
            XCTFail("expected invalidSignature")
        } catch ContentRefreshError.invalidSignature {
            // expected
        }
    }

    func testUnconfiguredVerifierFailsClosed() async throws {
        try writeBundledFixture(generated: "v1")
        let store = makeStore()
        let corpus = remoteCorpusData(generated: "v2")
        let transport = FakeTransport([
            ContentFetchResult(statusCode: 200, data: corpus, etag: "etag-2"),
            try signatureResult(for: corpus),
        ])
        // No FGCorpusPublicKey (as in an app whose Info.plist lacks the key):
        // even a genuinely valid signature is rejected — fail closed.
        let refresher = makeRefresher(
            transport: transport,
            signatureVerifier: CorpusSignatureVerifier(base64PublicKey: nil))

        do {
            _ = try await refresher.refresh(store: store)
            XCTFail("expected invalidSignature")
        } catch ContentRefreshError.invalidSignature {
            // expected
        }
        XCTAssertFalse(FileManager.default.fileExists(atPath: cacheDirectory.appendingPathComponent("quiz.json").path))
    }
}
