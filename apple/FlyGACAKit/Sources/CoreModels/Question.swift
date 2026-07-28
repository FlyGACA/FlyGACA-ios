import Foundation

/// One quiz question, enriched from the terse web schema (`{q, options, answer,
/// explain, cite, citeRef}` in public/data/quiz.json — see src/lib/content.ts).
///
/// The web corpus has NO stable per-question id (the web keys progress by array
/// index), so `id` is derived deterministically from the content at decode time
/// while `index`/`legacyKey` retain the web's index-keying for progress parity.
public struct Question: Identifiable, Hashable, Sendable {
    /// Stable content-derived id — survives reordering; changes only when the
    /// prompt text itself changes. See `StableID.question(bankID:prompt:)`.
    public let id: String
    public let bankID: String
    /// Position within the bank — the web's card key (`String(index)`).
    public let index: Int
    public let prompt: String
    public let choices: [String]
    /// 0-based index into `choices` (web `answer`).
    public let correctIndex: Int
    public let explanation: String
    /// Human-readable citation label, e.g. "GACAR Part 91, §91.165".
    public let citation: String?
    /// Deep link into the regulatory library (web `citeRef`).
    public let citeRef: CiteRef?

    /// The key the web app uses for SRS/flag state — index as a string.
    public var legacyKey: String { String(index) }
    public var correctChoice: String { choices[correctIndex] }

    public init(
        id: String,
        bankID: String,
        index: Int,
        prompt: String,
        choices: [String],
        correctIndex: Int,
        explanation: String,
        citation: String? = nil,
        citeRef: CiteRef? = nil
    ) {
        self.id = id
        self.bankID = bankID
        self.index = index
        self.prompt = prompt
        self.choices = choices
        self.correctIndex = correctIndex
        self.explanation = explanation
        self.citation = citation
        self.citeRef = citeRef
    }
}

/// Reference into the regulatory corpus (web `SearchRef`): kind is
/// "regulations" | "reference" | "handbook"; kept as a raw string so new kinds
/// added on the web never break decoding here.
public struct CiteRef: Hashable, Sendable, Decodable {
    public let kind: String
    public let id: String
    public let anchor: String?

    public init(kind: String, id: String, anchor: String? = nil) {
        self.kind = kind
        self.id = id
        self.anchor = anchor
    }
}
