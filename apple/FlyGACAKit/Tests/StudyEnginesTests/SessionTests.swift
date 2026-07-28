import CoreModels
import XCTest

@testable import StudyEngines

final class SessionTests: XCTestCase {
    private func question(bank: String, index: Int, correct: Int = 0) -> Question {
        Question(
            id: StableID.question(bankID: bank, prompt: "q\(index) of \(bank)"),
            bankID: bank,
            index: index,
            prompt: "q\(index) of \(bank)",
            choices: ["A", "B", "C", "D"],
            correctIndex: correct,
            explanation: "because"
        )
    }

    func testScoringRoundsLikeTheWeb() {
        // 2/3 = 66.67 → Math.round → 67 (web MockExam pct parity).
        let session = StudySession(
            questions: [question(bank: "a", index: 0), question(bank: "a", index: 1), question(bank: "a", index: 2)],
            config: .mock(ExamConfig(title: nil, questionCount: 3, minutes: 30, passMark: 67)))
        session.start(now: .init(timeIntervalSince1970: 0))
        session.answer(0)
        session.advance()
        session.answer(0)
        session.advance()
        session.answer(3) // wrong
        session.advance(now: .init(timeIntervalSince1970: 60))

        XCTAssertEqual(session.phase, .finished)
        let result = try! XCTUnwrap(session.result)
        XCTAssertEqual(result.correct, 2)
        XCTAssertEqual(result.percent, 67)
        XCTAssertEqual(result.passed, true)
        XCTAssertEqual(result.duration, 60)
    }

    func testPassMarkBoundaryPassesAtExactly() {
        // 3/4 = 75 with passMark 75 → pass (web: pct >= passMark).
        let questions = (0..<4).map { question(bank: "a", index: $0) }
        let session = StudySession(
            questions: questions,
            config: .mock(ExamConfig(title: nil, questionCount: 4, minutes: 30, passMark: 75)))
        session.start()
        for i in 0..<4 {
            session.answer(i == 3 ? 1 : 0)
            session.advance()
        }
        XCTAssertEqual(session.result?.percent, 75)
        XCTAssertEqual(session.result?.passed, true)
    }

    func testUnansweredQuestionsCountAsWrong() {
        let session = StudySession(
            questions: [question(bank: "a", index: 0), question(bank: "a", index: 1)],
            config: .mock(.standard))
        session.start()
        session.answer(0)
        session.submit()
        XCTAssertEqual(session.result?.correct, 1)
        XCTAssertEqual(session.result?.percent, 50)
    }

    func testPracticeIsUnscored() {
        let session = StudySession(questions: [question(bank: "a", index: 0)], config: .practice)
        session.start()
        session.answer(0)
        session.advance()
        XCTAssertNil(session.result?.passed)
        XCTAssertEqual(session.result?.percent, 100)
    }

    func testPerBankBreakdown() {
        let session = StudySession(
            questions: [
                question(bank: "airspace", index: 0),
                question(bank: "airspace", index: 1),
                question(bank: "weather", index: 0),
            ],
            config: .mock(.standard))
        session.start()
        session.answer(0) // right
        session.advance()
        session.answer(1) // wrong
        session.advance()
        session.answer(0) // right
        session.advance()

        XCTAssertEqual(session.result?.byBank["airspace"], BankScore(correct: 1, total: 2))
        XCTAssertEqual(session.result?.byBank["weather"], BankScore(correct: 1, total: 1))
    }

    func testExamClockExpiryAndAutoSubmitIdempotence() {
        let t0 = Date(timeIntervalSince1970: 0)
        let exam = ExamConfig(title: nil, questionCount: 1, minutes: 1, passMark: 75)
        let session = StudySession(questions: [question(bank: "a", index: 0)], config: .exam(exam))
        XCTAssertNil(session.remaining(now: t0)) // not started yet
        session.start(now: t0)
        XCTAssertEqual(session.remaining(now: t0.addingTimeInterval(30)), 30)
        XCTAssertFalse(session.isExpired(now: t0.addingTimeInterval(59)))
        XCTAssertTrue(session.isExpired(now: t0.addingTimeInterval(60)))
        XCTAssertEqual(session.remaining(now: t0.addingTimeInterval(90)), 0) // clamped

        session.submit(now: t0.addingTimeInterval(60))
        XCTAssertEqual(session.phase, .finished)
        let first = session.result
        session.submit(now: t0.addingTimeInterval(120)) // second submit is a no-op
        XCTAssertEqual(session.result, first)
    }

    func testAnswerCanBeChangedUntilSubmitAndJumpNavigates() {
        let session = StudySession(
            questions: [question(bank: "a", index: 0), question(bank: "a", index: 1)],
            config: .mock(.standard))
        session.start()
        session.answer(2)
        session.answer(0) // change of mind — last answer wins
        session.jump(to: 1)
        session.answer(0)
        session.jump(to: 99) // out of range — ignored
        XCTAssertEqual(session.currentIndex, 1)
        session.submit()
        XCTAssertEqual(session.result?.correct, 2)
    }
}
