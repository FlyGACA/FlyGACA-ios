import XCTest

@testable import StudyEngines

/// Parity with the web's `nextStreak` (src/lib/studyProgress.ts):
/// same day = unchanged, consecutive day = +1, gap = reset to 1.
final class StreakTests: XCTestCase {
    let day1 = Date(timeIntervalSince1970: 0) // 1970-01-01

    func testFirstStudyEventStartsAtOne() {
        XCTAssertEqual(Streaks.next(.none, now: day1), Streak(day: "1970-01-01", count: 1))
    }

    func testSameDayIsUnchanged() {
        let streak = Streak(day: "1970-01-01", count: 3)
        XCTAssertEqual(Streaks.next(streak, now: day1.addingTimeInterval(3_600)), streak)
    }

    func testConsecutiveDayIncrements() {
        let streak = Streak(day: "1970-01-01", count: 3)
        XCTAssertEqual(
            Streaks.next(streak, now: day1.addingTimeInterval(86_400)),
            Streak(day: "1970-01-02", count: 4))
    }

    func testGapResets() {
        let streak = Streak(day: "1970-01-01", count: 9)
        XCTAssertEqual(
            Streaks.next(streak, now: day1.addingTimeInterval(3 * 86_400)),
            Streak(day: "1970-01-04", count: 1))
    }
}
