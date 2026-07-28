import CoreModels
import Foundation

/// Signed-out auth — the default composition until PlatformLive ships.
public struct MockAuth: AuthProviding {
    public let currentUserID: String?

    public init(userID: String? = nil) {
        currentUserID = userID
    }

    public func signOut() async throws {}
}

/// Everything unlocked — the production default for a paid-up-front app
/// (buying the app IS the entitlement) and the preview/test default.
public struct FullAccess: EntitlementsProviding {
    public init() {}

    public func hasAccess(to module: ModuleManifest) async -> Bool { true }
}

/// Drops summaries on the floor — study progress is local-first; upload is a
/// best-effort backup, so a no-op is a valid (offline) implementation.
public struct NoopProgressSync: ProgressSyncing {
    public init() {}

    public func upload(_ summary: ProgressSummary) async throws {}
}

/// Streams a canned reply — keeps chat UI previewable without the gateway.
public struct CannedChat: ChatClient {
    public let reply: String

    public init(reply: String = "Captain Adel is available in the full release.") {
        self.reply = reply
    }

    public func send(_ message: String, history: [ChatTurn]) async throws
        -> AsyncThrowingStream<String, any Error>
    {
        let reply = self.reply
        return AsyncThrowingStream { continuation in
            continuation.yield(reply)
            continuation.finish()
        }
    }
}
