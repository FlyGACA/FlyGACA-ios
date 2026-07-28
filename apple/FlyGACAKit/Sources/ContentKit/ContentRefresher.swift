import CoreModels
import Foundation

/// Phase 4 (see ARCHITECTURE.md §2, "Remote content refresh"): fetches the
/// shared corpus from `https://flygaca.com/data/quiz.json`, trims it down to
/// this app's module slice, and — only once it round-trips cleanly through
/// `QuizFile.decode` — writes it into `ContentStore.cacheDirectory`, which
/// `ContentStore.activeDirectory` already prefers over the bundled snapshot.
///
/// Pure Foundation + `JSONSerialization`: no Firebase, no domain-model
/// re-encoding. The manifest (`module.json`) never changes over the wire —
/// only its `contentVersion` stamp is patched — so bank ids, exam overrides
/// etc. can't drift from what the app was built with.
public struct ContentRefresher: Sendable {
    public let transport: any ContentTransporting
    public let corpusURL: URL

    public init(
        transport: any ContentTransporting = URLSessionContentTransport(),
        corpusURL: URL = URL(string: "https://flygaca.com/data/quiz.json")!
    ) {
        self.transport = transport
        self.corpusURL = corpusURL
    }

    /// Fetches, filters to `store`'s module, validates, and (if newer) commits
    /// the refreshed corpus to `store.cacheDirectory`. Callers that also want
    /// SRS rows reconciled by question hash should follow a `.refreshed`
    /// outcome with `StudyStore.reconcileSRS(bankID:quiz:)` per affected bank.
    @discardableResult
    public func refresh(store: ContentStore) async throws -> ContentRefreshOutcome {
        let etagPath = etagFile(in: store)
        let cachedETag = try? String(contentsOf: etagPath, encoding: .utf8)
        let result = try await transport.fetch(corpusURL, ifNoneMatch: cachedETag)

        guard result.statusCode != 304 else { return .notModified }
        guard result.statusCode == 200, let data = result.data else {
            throw ContentRefreshError.badStatus(result.statusCode)
        }

        let corpusObject: Any
        do {
            corpusObject = try JSONSerialization.jsonObject(with: data)
        } catch {
            throw ContentRefreshError.malformedCorpus
        }
        guard let corpus = corpusObject as? [String: Any],
            let banks = corpus["banks"] as? [[String: Any]]
        else {
            throw ContentRefreshError.malformedCorpus
        }
        let remoteGenerated = corpus["generated"] as? String

        let current = try store.load()
        if let remoteGenerated, let currentGenerated = current.contentVersion, remoteGenerated == currentGenerated {
            try? persistETag(result.etag, to: etagPath)
            return .upToDate
        }

        let allowedBankIDs = Set(current.manifest.bankIDs)
        let filteredBanks = banks.filter { bank in
            guard let id = bank["id"] as? String else { return false }
            return allowedBankIDs.contains(id)
        }
        guard !filteredBanks.isEmpty else {
            throw ContentRefreshError.emptyModuleSlice(moduleID: current.manifest.id)
        }

        var filteredCorpus = corpus
        filteredCorpus["banks"] = filteredBanks
        let filteredData = try JSONSerialization.data(withJSONObject: filteredCorpus)
        // Belt-and-braces: never let a malformed remote corpus overwrite a
        // working cache — only commit once the filtered slice itself decodes.
        _ = try QuizFile.decode(filteredData)

        let moduleData = try stampedModuleJSON(generated: remoteGenerated, bundledDirectory: store.bundledDirectory)

        try FileManager.default.createDirectory(at: store.cacheDirectory, withIntermediateDirectories: true)
        try filteredData.write(to: store.cacheDirectory.appendingPathComponent("quiz.json"), options: .atomic)
        try moduleData.write(to: store.cacheDirectory.appendingPathComponent("module.json"), options: .atomic)
        try? persistETag(result.etag, to: etagPath)

        return .refreshed(generated: remoteGenerated)
    }

    private func etagFile(in store: ContentStore) -> URL {
        store.cacheDirectory.appendingPathComponent(".corpus-etag")
    }

    private func persistETag(_ etag: String?, to path: URL) throws {
        guard let etag else { return }
        try FileManager.default.createDirectory(
            at: path.deletingLastPathComponent(), withIntermediateDirectories: true)
        try etag.write(to: path, atomically: true, encoding: .utf8)
    }

    /// The bundled `module.json`, byte-identical except for a patched
    /// `contentVersion` — the manifest itself never changes over the wire.
    private func stampedModuleJSON(generated: String?, bundledDirectory: URL) throws -> Data {
        let bundledModuleURL = bundledDirectory.appendingPathComponent("module.json")
        guard let raw = try? Data(contentsOf: bundledModuleURL) else {
            throw ContentRefreshError.missingBundledManifest
        }
        guard let object = (try? JSONSerialization.jsonObject(with: raw)) as? [String: Any] else {
            throw ContentRefreshError.missingBundledManifest
        }
        var stamped = object
        stamped["contentVersion"] = generated
        return try JSONSerialization.data(withJSONObject: stamped)
    }
}

public enum ContentRefreshOutcome: Sendable, Equatable {
    /// The server had nothing newer than the cached ETag (a conditional 304).
    case notModified
    /// The server responded, but its corpus matched what's already active.
    case upToDate
    /// A newer corpus slice was fetched, validated and written to the cache.
    case refreshed(generated: String?)
}

public enum ContentRefreshError: Error, Equatable {
    case malformedResponse
    case badStatus(Int)
    case malformedCorpus
    /// The refreshed corpus no longer has any bank this module ships —
    /// almost certainly a bad fetch or a corpus regression, never intentional.
    case emptyModuleSlice(moduleID: String)
    case missingBundledManifest
}
