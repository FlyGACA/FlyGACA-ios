import CoreModels
import XCTest

@testable import StudyEngines

final class SamplerTests: XCTestCase {
    private func bank(_ id: String, count: Int) -> Bank {
        Bank(
            id: id, title: id, blurb: "", source: nil,
            questions: (0..<count).map { index in
                Question(
                    id: StableID.question(bankID: id, prompt: "q\(index)"),
                    bankID: id, index: index, prompt: "q\(index)",
                    choices: ["A", "B"], correctIndex: 0, explanation: "e")
            })
    }

    func testSeededDrawIsDeterministic() {
        let banks = [bank("a", count: 20), bank("b", count: 20)]
        let first = QuestionSampler.draw(from: banks, count: 10, seed: 42)
        let second = QuestionSampler.draw(from: banks, count: 10, seed: 42)
        XCTAssertEqual(first.map(\.id), second.map(\.id))
        XCTAssertNotEqual(
            first.map(\.id), QuestionSampler.draw(from: banks, count: 10, seed: 43).map(\.id))
    }

    func testDrawHasNoDuplicatesAndClampsToPool() {
        let banks = [bank("a", count: 6)]
        let drawn = QuestionSampler.draw(from: banks, count: 25, seed: 1)
        XCTAssertEqual(drawn.count, 6)
        XCTAssertEqual(Set(drawn.map(\.id)).count, 6)
    }
}
