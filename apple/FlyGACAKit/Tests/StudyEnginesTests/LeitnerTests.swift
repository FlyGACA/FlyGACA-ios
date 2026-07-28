import CoreModels
import XCTest

@testable import StudyEngines

/// Parity vectors against the web engine (src/calc/study/srs.ts) — every expected
/// value here was hand-computed from the TypeScript implementation. If one of
/// these fails after an engine change, web and iOS have diverged.
final class LeitnerTests: XCTestCase {
    let epoch = Date(timeIntervalSince1970: 0) // 1970-01-01T00:00:00Z

    func testDayIsUTCNotLocal() {
        // 23:59 UTC on Jan 1 is already Jan 2 in Riyadh (UTC+3). The web uses
        // toISOString() (UTC); a Calendar.current port would return "1970-01-02"
        // on a Mac in a positive-offset timezone and drift all due dates.
        XCTAssertEqual(Leitner.day(Date(timeIntervalSince1970: 86_340)), "1970-01-01")
        XCTAssertEqual(Leitner.day(epoch), "1970-01-01")
    }

    func testFirstCorrectGradePromotesToBoxOneDueTomorrow() {
        let entry = Leitner.schedule(nil, correct: true, now: epoch)
        XCTAssertEqual(entry, SrsEntry(box: 1, due: "1970-01-02"))
    }

    func testFirstWrongGradeStaysBoxZeroDueToday() {
        let entry = Leitner.schedule(nil, correct: false, now: epoch)
        XCTAssertEqual(entry, SrsEntry(box: 0, due: "1970-01-01"))
    }

    func testPromotionToTopBoxUsesThirtyDayInterval() {
        let entry = Leitner.schedule(SrsEntry(box: 4, due: "1970-01-01"), correct: true, now: epoch)
        XCTAssertEqual(entry, SrsEntry(box: 5, due: "1970-01-31"))
    }

    func testTopBoxIsCapped() {
        let entry = Leitner.schedule(SrsEntry(box: 5, due: "1970-01-01"), correct: true, now: epoch)
        XCTAssertEqual(entry.box, 5)
    }

    func testWrongGradeResetsToBoxZero() {
        let entry = Leitner.schedule(SrsEntry(box: 4, due: "1970-03-01"), correct: false, now: epoch)
        XCTAssertEqual(entry, SrsEntry(box: 0, due: "1970-01-01"))
    }

    func testIntervalLadderMatchesWeb() {
        // srs.ts INTERVAL_DAYS = [0, 1, 3, 7, 14, 30], clamped at both ends.
        XCTAssertEqual((0...5).map(Leitner.intervalDays(forBox:)), [0, 1, 3, 7, 14, 30])
        XCTAssertEqual(Leitner.intervalDays(forBox: -1), 0)
        XCTAssertEqual(Leitner.intervalDays(forBox: 99), 30)
    }

    func testUnseenCardsAreAlwaysDue() {
        XCTAssertTrue(Leitner.isDue(nil, now: epoch))
    }

    func testDueTodayOrEarlierIsDue() {
        XCTAssertTrue(Leitner.isDue(SrsEntry(box: 2, due: "1970-01-01"), now: epoch))
        XCTAssertTrue(Leitner.isDue(SrsEntry(box: 2, due: "1969-12-25"), now: epoch))
        XCTAssertFalse(Leitner.isDue(SrsEntry(box: 2, due: "1970-01-02"), now: epoch))
    }

    func testDueKeysPreservesInputOrder() {
        let entries = [
            "0": SrsEntry(box: 1, due: "1970-01-02"), // not due
            "2": SrsEntry(box: 1, due: "1970-01-01"), // due
        ]
        // "1" is unseen → due; order must follow allKeys, not dictionary order.
        XCTAssertEqual(
            Leitner.dueKeys(in: entries, allKeys: ["0", "1", "2"], now: epoch), ["1", "2"])
        XCTAssertEqual(Leitner.dueCount(in: entries, allKeys: ["0", "1", "2"], now: epoch), 2)
    }

    func testMasteryThresholdIsBoxThree() {
        let entries = [
            "a": SrsEntry(box: 0, due: "1970-01-01"),
            "b": SrsEntry(box: 2, due: "1970-01-01"),
            "c": SrsEntry(box: 3, due: "1970-01-01"),
            "d": SrsEntry(box: 5, due: "1970-01-01"),
        ]
        XCTAssertEqual(Leitner.masteredCount(in: entries), 2)
        XCTAssertEqual(Leitner.masteredCount(in: entries, threshold: 5), 1)
    }
}
