import CoreModels
import Foundation

/// Leitner spaced repetition — a literal port of the web engine
/// (src/calc/study/srs.ts), which is the cross-platform contract: users move between
/// the web app and these apps, so box/due/mastery must agree exactly. Any change
/// here must land in srs.ts too (and vice versa); the parity vectors in
/// StudyEnginesTests assert the shared semantics.
///
/// A card lives in a box 0…5; a correct grade promotes it (longer interval), a
/// wrong grade sends it back to box 0. Unseen cards are always due.
public enum Leitner {
    public static let maxBox = 5
    /// Cards at/above this box count as "learned" (web `masteredCount` default).
    public static let masteryThreshold = 3
    /// Review interval in days for each box 0…maxBox.
    static let intervals = [0, 1, 3, 7, 14, 30]

    /// UTC calendar day ("yyyy-mm-dd") — the web's `srsDay`
    /// (`Date.toISOString().slice(0, 10)`). Deliberately NOT `Calendar.current`:
    /// a local-time calendar would drift a day against the web near midnight.
    public static func day(_ date: Date) -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", c.year!, c.month!, c.day!)
    }

    public static func intervalDays(forBox box: Int) -> Int {
        intervals[max(0, min(maxBox, box))]
    }

    /// Promote on a correct grade (capped), reset to box 0 on a wrong one.
    public static func nextBox(_ box: Int, correct: Bool) -> Int {
        correct ? min(maxBox, box + 1) : 0
    }

    /// The card's new box + due date after grading it now.
    public static func schedule(_ previous: SrsEntry?, correct: Bool, now: Date) -> SrsEntry {
        let box = nextBox(previous?.box ?? 0, correct: correct)
        let due = day(now.addingTimeInterval(TimeInterval(intervalDays(forBox: box)) * 86_400))
        return SrsEntry(box: box, due: due)
    }

    /// True when a card should be reviewed now (unseen cards count as due).
    public static func isDue(_ entry: SrsEntry?, now: Date) -> Bool {
        guard let entry else { return true }
        return entry.due <= day(now)
    }

    /// The subset of `allKeys` that are due now, preserving input order.
    public static func dueKeys(in entries: [String: SrsEntry], allKeys: [String], now: Date) -> [String] {
        allKeys.filter { isDue(entries[$0], now: now) }
    }

    public static func dueCount(in entries: [String: SrsEntry], allKeys: [String], now: Date) -> Int {
        dueKeys(in: entries, allKeys: allKeys, now: now).count
    }

    /// Cards considered "learned" (box at/above the threshold).
    public static func masteredCount(in entries: [String: SrsEntry], threshold: Int = masteryThreshold) -> Int {
        entries.values.filter { $0.box >= threshold }.count
    }
}
