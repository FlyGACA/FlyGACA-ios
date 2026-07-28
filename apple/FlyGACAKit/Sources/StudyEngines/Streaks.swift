import Foundation

/// Daily study streak — web shape (`{day, count}` in src/lib/studyProgress.ts).
/// The streak is family-wide: it lives in the shared App Group store so studying
/// in any Fly GACA app keeps it alive.
public struct Streak: Hashable, Sendable, Codable {
    /// UTC day ("yyyy-mm-dd") of the last study event; empty when never studied.
    public var day: String
    public var count: Int

    public static let none = Streak(day: "", count: 0)

    public init(day: String, count: Int) {
        self.day = day
        self.count = count
    }
}

public enum Streaks {
    /// Advance a streak for a study event now — port of the web's `nextStreak`:
    /// same day = unchanged, consecutive day = +1, gap = reset to 1.
    public static func next(_ previous: Streak, now: Date) -> Streak {
        let today = Leitner.day(now)
        let yesterday = Leitner.day(now.addingTimeInterval(-86_400))
        if previous.day == today { return previous }
        if previous.day == yesterday { return Streak(day: today, count: previous.count + 1) }
        return Streak(day: today, count: 1)
    }
}
