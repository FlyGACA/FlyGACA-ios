import CoreModels
import Foundation

// The platform seams. FeatureUI talks ONLY to these protocols; the Firebase /
// RevenueCat / gateway implementations arrive in the PlatformLive target
// (Phase 4) and are injected by the app's composition root. Until then the
// mocks in Mocks.swift keep every screen working fully offline — which is also
// the shipping default: a paid-up-front app IS its own entitlement.

/// Firebase Auth seam. Sign-in is optional in the family (used for cross-device
/// progress backup and Captain Adel) — never required to study.
public protocol AuthProviding: Sendable {
    var currentUserID: String? { get }
    func signOut() async throws
}

/// Decides whether this install may open the module. Paid-up-front apps return
/// true unconditionally; a future free tier would check the server-owned
/// entitlement (users/{uid}.entitlement + packEntitlements/{uid} — read-only,
/// the app never grants).
public protocol EntitlementsProviding: Sendable {
    func hasAccess(to module: ModuleManifest) async -> Bool
}

/// Compact progress snapshot uploaded (upload-only, best-effort) to
/// users/{uid}/progress/summary — mirrors the web's `ProgressSummary` so both
/// clients feed the same B2B readiness reports.
public struct ProgressSummary: Codable, Equatable, Sendable {
    public var quizBest: [String: Int]
    public var examBest: Int?
    public var examCount: Int
    public var gsDone: [String]
    public var updatedAt: Date

    public init(
        quizBest: [String: Int],
        examBest: Int?,
        examCount: Int,
        gsDone: [String],
        updatedAt: Date
    ) {
        self.quizBest = quizBest
        self.examBest = examBest
        self.examCount = examCount
        self.gsDone = gsDone
        self.updatedAt = updatedAt
    }
}

public protocol ProgressSyncing: Sendable {
    func upload(_ summary: ProgressSummary) async throws
}

public struct ChatTurn: Codable, Equatable, Sendable {
    public let role: String
    public let text: String

    public init(role: String, text: String) {
        self.role = role
        self.text = text
    }
}

/// Captain Adel seam — the /api/chat gateway (SSE) once PlatformLive lands.
public protocol ChatClient: Sendable {
    func send(_ message: String, history: [ChatTurn]) async throws -> AsyncThrowingStream<String, any Error>
}
