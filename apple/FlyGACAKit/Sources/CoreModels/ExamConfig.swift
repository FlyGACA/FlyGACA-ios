import Foundation

/// Timed-exam parameters — the web's `quiz.json` `exam` block
/// (`{title, questions, minutes, passMark}`), defaulting to the GACAR mock-exam
/// standard of 25 questions / 30 minutes / 75% pass.
public struct ExamConfig: Hashable, Sendable, Decodable {
    public let title: String?
    public let questionCount: Int
    public let minutes: Int
    /// Pass threshold in percent.
    public let passMark: Int

    public static let standard = ExamConfig(title: nil, questionCount: 25, minutes: 30, passMark: 75)

    public init(title: String?, questionCount: Int, minutes: Int, passMark: Int) {
        self.title = title
        self.questionCount = questionCount
        self.minutes = minutes
        self.passMark = passMark
    }

    enum CodingKeys: String, CodingKey {
        case title
        case questionCount = "questions"
        case minutes
        case passMark
    }
}

/// Per-module exam overrides (the pack's optional `exam` block); unset fields
/// fall back to the corpus-wide config — same overlay the web mock exam applies.
public struct ExamOverride: Hashable, Sendable, Decodable {
    public let questionCount: Int?
    public let minutes: Int?
    public let passMark: Int?

    public init(questionCount: Int? = nil, minutes: Int? = nil, passMark: Int? = nil) {
        self.questionCount = questionCount
        self.minutes = minutes
        self.passMark = passMark
    }

    enum CodingKeys: String, CodingKey {
        case questionCount = "questions"
        case minutes
        case passMark
    }

    public func resolved(over base: ExamConfig) -> ExamConfig {
        ExamConfig(
            title: base.title,
            questionCount: questionCount ?? base.questionCount,
            minutes: minutes ?? base.minutes,
            passMark: passMark ?? base.passMark
        )
    }
}
