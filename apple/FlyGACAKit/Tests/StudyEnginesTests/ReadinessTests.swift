import CoreModels
import XCTest

@testable import StudyEngines

final class ReadinessTests: XCTestCase {
    func testNoExamsRenormalizesOverCoverageAndMastery() {
        let readiness = ReadinessAnalytics.readiness(
            quizBest: ["a": 80],
            bankIDs: ["a", "b"],
            srs: ["0": SrsEntry(box: 4, due: "1970-01-01"), "1": SrsEntry(box: 0, due: "1970-01-01")],
            cardCount: 2,
            examPercents: [])
        XCTAssertEqual(readiness.coverage, 0.5)
        XCTAssertEqual(readiness.mastery, 0.5)
        XCTAssertNil(readiness.examAverage)
        XCTAssertEqual(readiness.score, 50)
    }

    func testExamAverageCarriesHalfTheWeight() {
        let readiness = ReadinessAnalytics.readiness(
            quizBest: ["a": 90, "b": 70],
            bankIDs: ["a", "b"],
            srs: ["0": SrsEntry(box: 3, due: "1970-01-01"), "1": SrsEntry(box: 1, due: "1970-01-01")],
            cardCount: 2,
            examPercents: [80])
        // 0.8 * 0.5 + 1.0 * 0.25 + 0.5 * 0.25 = 0.775 → 78
        XCTAssertEqual(readiness.score, 78)
    }

    func testEmptyModuleScoresZero() {
        let readiness = ReadinessAnalytics.readiness(
            quizBest: [:], bankIDs: [], srs: [:], cardCount: 0, examPercents: [])
        XCTAssertEqual(readiness.score, 0)
    }
}
