import XCTest

@testable import CoreModels

/// Decoding against the REAL wire shape — this fixture is a trimmed copy of
/// public/data/quiz.json records (the terse web schema the bundler emits
/// verbatim). If the web schema changes, this is the test that breaks first.
final class QuizDecodeTests: XCTestCase {
    static let fixture = Data(
        """
        {
          "generated": "2026-07-01T00:00:00.000Z",
          "note": "trimmed fixture",
          "exam": { "title": "GACAR Knowledge — Mock Exam", "questions": 25, "minutes": 30, "passMark": 75 },
          "banks": [
            {
              "id": "vfr-flight-rules",
              "title": "VFR & Flight Rules",
              "desc": "Weather minima and friends.",
              "source": "GACAR Part 91",
              "questions": [
                {
                  "q": "What is the minimum flight visibility for VFR flight in Class D airspace?",
                  "options": ["3 km", "5 km", "8 km", "1,500 m"],
                  "answer": 1,
                  "explain": "GACAR §91.165 sets 5 km flight visibility.",
                  "cite": "GACAR Part 91, §91.165",
                  "citeRef": { "kind": "regulations", "id": "part-91", "anchor": "sec-91-165" }
                },
                {
                  "q": "A bare-minimum question with no citation.",
                  "options": ["Yes", "No"],
                  "answer": 0,
                  "explain": "Because."
                }
              ]
            },
            {
              "id": "airspace",
              "title": "Airspace",
              "desc": "Classes and clearances.",
              "source": "GACAR Part 71",
              "questions": [
                {
                  "q": "A bare-minimum question with no citation.",
                  "options": ["Yes", "No"],
                  "answer": 1,
                  "explain": "Different bank, same prompt."
                }
              ]
            }
          ]
        }
        """.utf8)

    func testDecodesTerseWebSchemaIntoRichModels() throws {
        let file = try QuizFile.decode(Self.fixture)

        XCTAssertEqual(file.generated, "2026-07-01T00:00:00.000Z")
        XCTAssertEqual(file.exam.questionCount, 25)
        XCTAssertEqual(file.exam.minutes, 30)
        XCTAssertEqual(file.exam.passMark, 75)
        XCTAssertEqual(file.banks.count, 2)

        let bank = try XCTUnwrap(file.bank(id: "vfr-flight-rules"))
        XCTAssertEqual(bank.title, "VFR & Flight Rules")
        XCTAssertEqual(bank.blurb, "Weather minima and friends.")
        XCTAssertEqual(bank.source, "GACAR Part 91")

        let q = bank.questions[0]
        XCTAssertEqual(q.prompt, "What is the minimum flight visibility for VFR flight in Class D airspace?")
        XCTAssertEqual(q.choices, ["3 km", "5 km", "8 km", "1,500 m"])
        XCTAssertEqual(q.correctIndex, 1)
        XCTAssertEqual(q.correctChoice, "5 km")
        XCTAssertEqual(q.explanation, "GACAR §91.165 sets 5 km flight visibility.")
        XCTAssertEqual(q.citation, "GACAR Part 91, §91.165")
        XCTAssertEqual(q.citeRef?.kind, "regulations")
        XCTAssertEqual(q.citeRef?.id, "part-91")
        XCTAssertEqual(q.citeRef?.anchor, "sec-91-165")

        XCTAssertNil(bank.questions[1].citation)
        XCTAssertNil(bank.questions[1].citeRef)
    }

    func testIndexKeysMatchTheWebCardKeys() throws {
        let file = try QuizFile.decode(Self.fixture)
        let bank = try XCTUnwrap(file.bank(id: "vfr-flight-rules"))
        XCTAssertEqual(bank.questions.map(\.index), [0, 1])
        XCTAssertEqual(bank.questions.map(\.legacyKey), ["0", "1"])
    }

    func testStableIDsAreDeterministicAndBankScoped() throws {
        let first = try QuizFile.decode(Self.fixture)
        let second = try QuizFile.decode(Self.fixture)
        XCTAssertEqual(
            first.banks.flatMap { $0.questions.map(\.id) },
            second.banks.flatMap { $0.questions.map(\.id) })

        let ids = first.banks.flatMap { $0.questions.map(\.id) }
        XCTAssertEqual(Set(ids).count, ids.count, "ids must be unique across the corpus")
        for id in ids {
            XCTAssertEqual(id.count, 16)
        }
        // Same prompt in two banks must NOT collide — the id is bank-scoped.
        XCTAssertNotEqual(
            first.bank(id: "vfr-flight-rules")!.questions[1].id,
            first.bank(id: "airspace")!.questions[0].id)
    }

    func testAnswerIndexOutOfRangeFailsLoudly() {
        let bad = Data(
            """
            { "banks": [ { "id": "b", "title": "B", "desc": "", "questions": [
              { "q": "broken", "options": ["only one"], "answer": 3, "explain": "x" }
            ] } ] }
            """.utf8)
        XCTAssertThrowsError(try QuizFile.decode(bad)) { error in
            XCTAssertEqual(
                error as? QuizDecodingError, .answerOutOfRange(bank: "b", question: 0))
        }
    }

    func testMissingExamBlockFallsBackToStandard() throws {
        let minimal = Data("""
        { "banks": [] }
        """.utf8)
        let file = try QuizFile.decode(minimal)
        XCTAssertEqual(file.exam, .standard)
    }
}
