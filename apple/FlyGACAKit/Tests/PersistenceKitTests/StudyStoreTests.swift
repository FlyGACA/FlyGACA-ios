import CoreModels
import StudyEngines
import XCTest

@testable import PersistenceKit

/// StudyStore is the single durable write path — the only actor-based, SwiftData-
/// backed, hand-rolled-JSON-blob code in the package. These tests exercise it via
/// an in-memory container (no App Group, no disk, no simulator) so `swift test`
/// stays hermetic on a Mac. The parity contracts they lock down (10-most-recent
/// exam cap, best-per-bank quiz score, day-based streak) mirror the web app.
final class StudyStoreTests: XCTestCase {
    private func makeStore() throws -> StudyStore {
        let container = try Persistence.container(inMemory: true)
        return StudyStore(container: container)
    }

    private func makeQuestion(bankID: String = "bank-a", index: Int = 0, id: String = "q-1") -> Question {
        Question(
            id: id, bankID: bankID, index: index, prompt: "Prompt",
            choices: ["A", "B"], correctIndex: 0, explanation: "Because.")
    }

    private func makeQuizFile(bankID: String, questions: [Question]) -> QuizFile {
        QuizFile(
            generated: "v2", exam: .standard,
            banks: [Bank(id: bankID, title: bankID, blurb: "", source: nil, questions: questions)])
    }

    // MARK: - Exams

    func testRecordExamThenExamHistoryReturnsMostRecentFirst() async throws {
        let store = try makeStore()
        let epoch = Date(timeIntervalSince1970: 0)
        let older = SessionResult(
            total: 10, correct: 7, percent: 70, passed: false, byBank: [:],
            duration: 60, finishedAt: epoch)
        let newer = SessionResult(
            total: 10, correct: 9, percent: 90, passed: true, byBank: [:],
            duration: 60, finishedAt: epoch.addingTimeInterval(3600))

        try await store.recordExam(moduleID: "ppl-exam", result: older)
        try await store.recordExam(moduleID: "ppl-exam", result: newer)

        let history = try await store.examHistory(moduleID: "ppl-exam")
        XCTAssertEqual(history.count, 2)
        XCTAssertEqual(history.first?.percent, 90)
        XCTAssertEqual(history.last?.percent, 70)
    }

    func testExamHistoryIsCappedAtTenMostRecentPerModule() async throws {
        let store = try makeStore()
        let epoch = Date(timeIntervalSince1970: 0)
        for i in 0..<12 {
            let result = SessionResult(
                total: 10, correct: i, percent: i * 10, passed: nil, byBank: [:],
                duration: 60, finishedAt: epoch.addingTimeInterval(TimeInterval(i * 3600)))
            try await store.recordExam(moduleID: "ppl-exam", result: result)
        }
        let history = try await store.examHistory(moduleID: "ppl-exam")
        XCTAssertEqual(history.count, StudyStore.examHistoryLimit)
        // The two oldest inserts (percent 0 and 10) are pruned; the newest is first.
        XCTAssertFalse(history.contains { $0.percent == 0 })
        XCTAssertFalse(history.contains { $0.percent == 10 })
        XCTAssertEqual(history.first?.percent, 110)
    }

    func testExamHistoryIsScopedPerModule() async throws {
        let store = try makeStore()
        let epoch = Date(timeIntervalSince1970: 0)
        let ppl = SessionResult(
            total: 5, correct: 5, percent: 100, passed: true, byBank: [:],
            duration: 30, finishedAt: epoch)
        let cpl = SessionResult(
            total: 5, correct: 3, percent: 60, passed: false, byBank: [:],
            duration: 30, finishedAt: epoch)
        try await store.recordExam(moduleID: "ppl-exam", result: ppl)
        try await store.recordExam(moduleID: "cpl", result: cpl)

        let pplHistory = try await store.examHistory(moduleID: "ppl-exam")
        XCTAssertEqual(pplHistory.map(\.percent), [100])
        let cplHistory = try await store.examHistory(moduleID: "cpl")
        XCTAssertEqual(cplHistory.map(\.percent), [60])
    }

    // MARK: - Flashcards / SRS

    func testGradeThenSrsEntriesRoundTrips() async throws {
        let store = try makeStore()
        let question = makeQuestion(bankID: "bank-a", index: 2, id: "q-3")
        let epoch = Date(timeIntervalSince1970: 0)

        let entry = try await store.grade(question: question, correct: true, now: epoch)
        // Fresh card graded correct promotes box 0 → 1 (web Leitner parity).
        XCTAssertEqual(entry.box, 1)

        let entries = try await store.srsEntries(bankID: "bank-a")
        XCTAssertEqual(entries[question.legacyKey], entry)
    }

    func testGradeWrongResetsBoxToZero() async throws {
        let store = try makeStore()
        let question = makeQuestion(bankID: "bank-a", index: 4, id: "q-5")
        let epoch = Date(timeIntervalSince1970: 0)

        _ = try await store.grade(question: question, correct: true, now: epoch)
        _ = try await store.grade(question: question, correct: true, now: epoch)
        let wrong = try await store.grade(question: question, correct: false, now: epoch)
        XCTAssertEqual(wrong.box, 0)

        let entries = try await store.srsEntries(bankID: "bank-a")
        XCTAssertEqual(entries.count, 1, "Re-grading updates one row, never inserts a duplicate.")
    }

    // MARK: - Content refresh reconciliation

    func testReconcileSRSRewritesCardKeyWhenQuestionMovesIndex() async throws {
        let store = try makeStore()
        let epoch = Date(timeIntervalSince1970: 0)
        let question = makeQuestion(bankID: "bank-a", index: 2, id: "q-3")
        _ = try await store.grade(question: question, correct: true, now: epoch)

        // The refreshed corpus reorders "q-3" from index 2 to index 0.
        let movedQuestion = makeQuestion(bankID: "bank-a", index: 0, id: "q-3")
        let quiz = makeQuizFile(bankID: "bank-a", questions: [movedQuestion])

        try await store.reconcileSRS(bankID: "bank-a", quiz: quiz)

        let entries = try await store.srsEntries(bankID: "bank-a")
        XCTAssertNil(entries["2"], "the stale index-2 key must not remain")
        XCTAssertEqual(entries["0"]?.box, 1, "progress carries over to the question's new index")
    }

    func testReconcileSRSLeavesOrphanedRowUntouchedWhenQuestionIsRemoved() async throws {
        let store = try makeStore()
        let epoch = Date(timeIntervalSince1970: 0)
        let question = makeQuestion(bankID: "bank-a", index: 2, id: "q-3")
        _ = try await store.grade(question: question, correct: true, now: epoch)

        // The refreshed corpus no longer has "q-3" at all.
        let quiz = makeQuizFile(bankID: "bank-a", questions: [makeQuestion(bankID: "bank-a", index: 0, id: "q-other")])

        try await store.reconcileSRS(bankID: "bank-a", quiz: quiz)

        let entries = try await store.srsEntries(bankID: "bank-a")
        XCTAssertEqual(entries["2"]?.box, 1, "orphaned row is left as-is, not deleted")
    }

    func testReconcileSRSIsNoOpWhenIndexAlreadyMatches() async throws {
        let store = try makeStore()
        let epoch = Date(timeIntervalSince1970: 0)
        let question = makeQuestion(bankID: "bank-a", index: 2, id: "q-3")
        _ = try await store.grade(question: question, correct: true, now: epoch)

        let quiz = makeQuizFile(bankID: "bank-a", questions: [question])
        try await store.reconcileSRS(bankID: "bank-a", quiz: quiz)

        let entries = try await store.srsEntries(bankID: "bank-a")
        XCTAssertEqual(entries.count, 1)
        XCTAssertEqual(entries["2"]?.box, 1)
    }

    func testReconcileSRSIsNoOpWhenBankIsUnknownToTheRefreshedQuiz() async throws {
        let store = try makeStore()
        let epoch = Date(timeIntervalSince1970: 0)
        let question = makeQuestion(bankID: "bank-a", index: 2, id: "q-3")
        _ = try await store.grade(question: question, correct: true, now: epoch)

        let quiz = makeQuizFile(bankID: "bank-b", questions: [makeQuestion(bankID: "bank-b", index: 0, id: "q-other")])
        try await store.reconcileSRS(bankID: "bank-a", quiz: quiz)

        let entries = try await store.srsEntries(bankID: "bank-a")
        XCTAssertEqual(entries["2"]?.box, 1)
    }

    // MARK: - Quiz bests

    func testRecordQuizScoreKeepsBestPerBankAndNeverDowngrades() async throws {
        let store = try makeStore()
        try await store.recordQuizScore(moduleID: "ppl-exam", bankID: "bank-a", percent: 70)
        try await store.recordQuizScore(moduleID: "ppl-exam", bankID: "bank-a", percent: 50)
        var best = try await store.quizBest(moduleID: "ppl-exam")
        XCTAssertEqual(best["bank-a"], 70)

        try await store.recordQuizScore(moduleID: "ppl-exam", bankID: "bank-a", percent: 90)
        best = try await store.quizBest(moduleID: "ppl-exam")
        XCTAssertEqual(best["bank-a"], 90)
    }

    // MARK: - Lessons

    func testMarkLessonDoneIsIdempotent() async throws {
        let store = try makeStore()
        try await store.markLessonDone(moduleID: "ppl-exam", lessonID: "lesson-1")
        try await store.markLessonDone(moduleID: "ppl-exam", lessonID: "lesson-1")
        let done = try await store.lessonsDone(moduleID: "ppl-exam")
        XCTAssertEqual(done, ["lesson-1"])
    }

    // MARK: - Flags

    func testSetFlagTogglesIndexInAndOutOfTheBank() async throws {
        let store = try makeStore()
        try await store.setFlag(moduleID: "ppl-exam", bankID: "bank-a", index: 3, flagged: true)
        try await store.setFlag(moduleID: "ppl-exam", bankID: "bank-a", index: 5, flagged: true)
        var flagged = try await store.flaggedIndices(moduleID: "ppl-exam", bankID: "bank-a")
        XCTAssertEqual(Set(flagged), [3, 5])

        try await store.setFlag(moduleID: "ppl-exam", bankID: "bank-a", index: 3, flagged: false)
        flagged = try await store.flaggedIndices(moduleID: "ppl-exam", bankID: "bank-a")
        XCTAssertEqual(flagged, [5])
    }

    func testSetFlagIsIdempotentAndScopedPerBank() async throws {
        let store = try makeStore()
        try await store.setFlag(moduleID: "ppl-exam", bankID: "bank-a", index: 1, flagged: true)
        try await store.setFlag(moduleID: "ppl-exam", bankID: "bank-a", index: 1, flagged: true)
        let bankA = try await store.flaggedIndices(moduleID: "ppl-exam", bankID: "bank-a")
        XCTAssertEqual(bankA, [1], "Flagging twice doesn't duplicate the index.")

        let bankB = try await store.flaggedIndices(moduleID: "ppl-exam", bankID: "bank-b")
        XCTAssertEqual(bankB, [], "A different bank in the same module starts unflagged.")
    }

    // MARK: - Streak

    func testTouchStreakAdvancesByDayGaps() async throws {
        let store = try makeStore()
        let day0 = Date(timeIntervalSince1970: 0)
        let sameDayLater = day0.addingTimeInterval(3600)
        let day1 = day0.addingTimeInterval(86_400)
        let day11 = day0.addingTimeInterval(86_400 * 11)

        var streak = try await store.touchStreak(now: day0)
        XCTAssertEqual(streak, Streak(day: "1970-01-01", count: 1))

        streak = try await store.touchStreak(now: sameDayLater)
        XCTAssertEqual(streak, Streak(day: "1970-01-01", count: 1), "Same day = unchanged.")

        streak = try await store.touchStreak(now: day1)
        XCTAssertEqual(streak, Streak(day: "1970-01-02", count: 2), "Consecutive day = +1.")

        streak = try await store.touchStreak(now: day11)
        XCTAssertEqual(streak, Streak(day: "1970-01-12", count: 1), "Gap resets to 1.")
    }
}
