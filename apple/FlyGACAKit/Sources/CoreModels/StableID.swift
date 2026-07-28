import CryptoKit
import Foundation

public enum StableID {
    /// Deterministic question id: first 16 hex chars of SHA-256("bankID|prompt").
    ///
    /// The shared corpus has no per-question ids, and the web keys SRS state by
    /// array index — which silently re-keys when a bank is edited. Deriving an id
    /// from content fixes that here: the id survives reordering, and when a
    /// refreshed corpus shifts indices, persisted SRS rows are reconciled by this
    /// hash (their `cardKey` rewritten) instead of being orphaned.
    public static func question(bankID: String, prompt: String) -> String {
        let digest = SHA256.hash(data: Data("\(bankID)|\(prompt)".utf8))
        return Array(digest).prefix(8).map { String(format: "%02x", $0) }.joined()
    }
}
