import Foundation

/// A flashcard's spaced-repetition state — the exact web shape
/// (src/calc/study/srs.ts `SrsEntry`): Leitner box 0…5 and the UTC calendar day
/// ("yyyy-mm-dd") the card next becomes due. Kept as a day STRING, not a Date:
/// the web computes days in UTC (`toISOString().slice(0, 10)`), and comparing
/// formatted strings is what keeps iOS and web agreeing on "due today".
public struct SrsEntry: Hashable, Sendable, Codable {
    public var box: Int
    public var due: String

    public init(box: Int, due: String) {
        self.box = box
        self.due = due
    }
}
