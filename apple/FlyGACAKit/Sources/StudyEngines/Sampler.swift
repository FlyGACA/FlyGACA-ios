import CoreModels
import Foundation

/// Draws exam/quiz question sets from the module's banks — the web mock exam's
/// pool behaviour: flatten the configured banks, shuffle, take N. Seedable so
/// tests (and "retake the same paper") are deterministic.
public enum QuestionSampler {
    public static func draw(
        from banks: [Bank],
        count: Int,
        using rng: inout some RandomNumberGenerator
    ) -> [Question] {
        let pool = banks.flatMap(\.questions)
        return Array(pool.shuffled(using: &rng).prefix(count))
    }

    public static func draw(from banks: [Bank], count: Int, seed: UInt64) -> [Question] {
        var rng = SplitMix64(seed: seed)
        return draw(from: banks, count: count, using: &rng)
    }

    public static func draw(from banks: [Bank], count: Int) -> [Question] {
        var rng = SystemRandomNumberGenerator()
        return draw(from: banks, count: count, using: &rng)
    }
}

/// Small, fast, seedable PRNG (SplitMix64) — for reproducible draws only, not
/// for anything security-sensitive.
public struct SplitMix64: RandomNumberGenerator, Sendable {
    private var state: UInt64

    public init(seed: UInt64) {
        state = seed
    }

    public mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}
