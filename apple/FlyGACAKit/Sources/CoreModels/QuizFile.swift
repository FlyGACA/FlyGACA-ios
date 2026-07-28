import Foundation

/// A topic bank of questions (web `QuizBank`). `blurb` maps the web's `desc`.
public struct Bank: Identifiable, Hashable, Sendable {
    public let id: String
    public let title: String
    public let blurb: String
    /// Source label, e.g. "GACAR Part 91".
    public let source: String?
    public let questions: [Question]

    public init(id: String, title: String, blurb: String, source: String?, questions: [Question]) {
        self.id = id
        self.title = title
        self.blurb = blurb
        self.source = source
        self.questions = questions
    }
}

public enum QuizDecodingError: Error, Equatable {
    /// A question's `answer` index falls outside its `options` array.
    case answerOutOfRange(bank: String, question: Int)
}

/// The decoded quiz corpus — the app's slice of public/data/quiz.json, emitted
/// verbatim by scripts/build-ios-content.mjs. Decoding enriches each terse
/// question record with its bank, index and stable id, and validates every
/// answer index so a bad corpus fails loudly at load, not at grading.
public struct QuizFile: Sendable {
    /// Corpus build stamp (web `generated`), used as the content version.
    public let generated: String?
    public let exam: ExamConfig
    public let banks: [Bank]

    public init(generated: String?, exam: ExamConfig, banks: [Bank]) {
        self.generated = generated
        self.exam = exam
        self.banks = banks
    }

    public func bank(id: String) -> Bank? {
        banks.first { $0.id == id }
    }

    public static func decode(_ data: Data) throws -> QuizFile {
        let dto = try JSONDecoder().decode(FileDTO.self, from: data)
        let banks: [Bank] = try dto.banks.map { bank in
            let questions: [Question] = try bank.questions.enumerated().map { index, q in
                guard q.options.indices.contains(q.answer) else {
                    throw QuizDecodingError.answerOutOfRange(bank: bank.id, question: index)
                }
                return Question(
                    id: StableID.question(bankID: bank.id, prompt: q.q),
                    bankID: bank.id,
                    index: index,
                    prompt: q.q,
                    choices: q.options,
                    correctIndex: q.answer,
                    explanation: q.explain,
                    citation: q.cite,
                    citeRef: q.citeRef
                )
            }
            return Bank(id: bank.id, title: bank.title, blurb: bank.desc, source: bank.source, questions: questions)
        }
        return QuizFile(generated: dto.generated, exam: dto.exam ?? .standard, banks: banks)
    }

    // The wire format stays byte-for-byte the web schema; only these DTOs know it.
    private struct FileDTO: Decodable {
        let generated: String?
        let exam: ExamConfig?
        let banks: [BankDTO]
    }

    private struct BankDTO: Decodable {
        let id: String
        let title: String
        let desc: String
        let source: String?
        let questions: [QuestionDTO]
    }

    private struct QuestionDTO: Decodable {
        let q: String
        let options: [String]
        let answer: Int
        let explain: String
        let cite: String?
        let citeRef: CiteRef?
    }
}
