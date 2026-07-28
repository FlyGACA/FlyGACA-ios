import CoreModels
import Foundation

/// Cache-then-bundle content resolution. `ContentRefresher` fetches updated
/// corpus JSON from https://flygaca.com/data (ETag + `generated` check) into
/// `cacheDirectory`; `activeDirectory` below prefers it once it exists, so
/// callers of `load()` never need to know which snapshot answered.
public struct ContentStore: Sendable {
    public let bundledDirectory: URL
    public let cacheDirectory: URL

    /// Expected module id (the app's FGModuleID) — load() verifies the content
    /// actually belongs to this app.
    public let moduleID: String?

    public init(bundledDirectory: URL, cacheDirectory: URL? = nil, moduleID: String? = nil) {
        self.bundledDirectory = bundledDirectory
        self.cacheDirectory = cacheDirectory
            ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("FlyGACAContent", isDirectory: true)
        self.moduleID = moduleID
    }

    /// The directory content should load from: a refreshed cache snapshot when
    /// one exists (Phase 4), otherwise the bundled snapshot.
    public var activeDirectory: URL {
        let cachedManifest = cacheDirectory.appendingPathComponent("module.json")
        if FileManager.default.fileExists(atPath: cachedManifest.path) {
            return cacheDirectory
        }
        return bundledDirectory
    }

    public func load() throws -> ModuleContent {
        let content = try ContentLoader.load(from: activeDirectory)
        if let moduleID, content.manifest.id != moduleID {
            throw ContentError.moduleMismatch(found: content.manifest.id, expected: moduleID)
        }
        return content
    }
}
