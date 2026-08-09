import CryptoKit
import Foundation
import os

/// Ed25519 gate for the remote corpus refresh. The shared corpus at
/// `https://flygaca.com/data/quiz.json` now travels with a detached signature
/// at `quiz.json.sig` (base64, produced by `scripts/sign-corpus.sh`); only
/// bytes that verify against the pinned public key may reach
/// `ContentStore.cacheDirectory`, which `ContentStore.activeDirectory` prefers
/// over the bundled snapshot. Pure CryptoKit — no network, no Firebase.
///
/// FAIL CLOSED: the public key ships in each app's Info.plist as
/// `FGCorpusPublicKey` (base64 raw Ed25519 key, set via
/// `INFOPLIST_KEY_FGCorpusPublicKey` in `Apps/Shared/App-Shared.xcconfig`).
/// When the key is absent or malformed the verifier stays unconfigured, every
/// `isValidSignature(_:for:)` returns `false`, and a clear message is logged —
/// `ContentRefresher` then refuses the refresh and keeps the existing cache,
/// so an unconfigured build simply never adopts remote content.
public struct CorpusSignatureVerifier: Sendable {
    private static let logger = Logger(subsystem: "FlyGACA.ContentKit", category: "CorpusSignatureVerifier")

    /// The pinned Ed25519 public key; `nil` means "signing not configured",
    /// which fails closed on every verification.
    private let publicKey: Curve25519.Signing.PublicKey?

    /// Production entry point: reads `FGCorpusPublicKey` (base64) from the app
    /// bundle's Info.plist. See docs/CORPUS-SIGNING.md for key generation.
    public init(bundle: Bundle = .main) {
        self.init(base64PublicKey: bundle.object(forInfoDictionaryKey: "FGCorpusPublicKey") as? String)
    }

    /// Explicit-key entry point (tests, tools). A missing or undecodable key
    /// leaves the verifier unconfigured — fail closed, never crash.
    public init(base64PublicKey: String?) {
        guard let base64PublicKey, !base64PublicKey.isEmpty else {
            Self.logger.error(
                "FGCorpusPublicKey is missing from Info.plist — corpus signing is not configured; remote corpus refreshes will be rejected (fail closed).")
            publicKey = nil
            return
        }
        guard let raw = Data(base64Encoded: base64PublicKey),
            let key = try? Curve25519.Signing.PublicKey(rawRepresentation: raw)
        else {
            Self.logger.error(
                "FGCorpusPublicKey is not a valid base64 Ed25519 public key; remote corpus refreshes will be rejected (fail closed).")
            publicKey = nil
            return
        }
        publicKey = key
    }

    /// `true` only when the verifier is configured AND `signature` is a valid
    /// Ed25519 signature over the exact corpus bytes (`message`).
    public func isValidSignature(_ signature: Data, for message: Data) -> Bool {
        guard let publicKey else { return false }
        return publicKey.isValidSignature(signature, for: message)
    }
}
