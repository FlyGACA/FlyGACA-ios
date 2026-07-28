import CoreModels
import Foundation
import Observation

/// How a study session behaves. There is ONE session engine — practice, mock and
/// exam are configurations of it, which is what makes every module's five core
/// features come from the same code path:
///  - `.practice` — untimed, per-question feedback (reveal + explanation).
///  - `.mock`     — scored against the pass mark, untimed, feedback at the end.
///  - `.exam`     — scored AND timed; auto-submits when time expires.
public struct SessionConfig: Hashable, Sendable {
    public enum Mode: Hashable, Sendable {
        case practice
        case mock
        case exam
    }

    public let mode: Mode
    public let timeLimit: TimeInterval?
    /// Pass threshold in percent; nil = unscored (practice).
    public let passMark: Int?

    /// Practice reveals the answer as soon as one is chosen.
    public var revealsAnswers: Bool { mode == .practice }

    public static let practice = SessionConfig(mode: .practice, timeLimit: nil, passMark: nil)

    public static func mock(_ exam: ExamConfig) -> SessionConfig {
        SessionConfig(mode: .mock, timeLimit: nil, passMark: exam.passMark)
    }

    public static func exam(_ exam: ExamConfig) -> SessionConfig {
        SessionConfig(mode: .exam, timeLimit: TimeInterval(exam.minutes * 60), passMark: exam.passMark)
    }

    public init(mode: Mode, timeLimit: TimeInterval?, passMark: Int?) {
        self.mode = mode
        self.timeLimit = timeLimit
        self.passMark = passMark
    }
}

public struct BankScore: Hashable, Sendable, Codable {
    public var correct: Int
    public var total: Int

    public init(correct: Int, total: Int) {
        self.correct = correct
        self.total = total
    }
}

public struct SessionResult: Hashable, Sendable, Codable {
    public let total: Int
    public let correct: Int
    /// Rounded like the web (`Math.round(correct / total * 100)`).
    public let percent: Int
    /// nil when the session was unscored (practice).
    public let passed: Bool?
    /// Per-bank breakdown, the web mock exam's `byBank`.
    public let byBank: [String: BankScore]
    public let duration: TimeInterval
    public let finishedAt: Date

    public init(
        total: Int,
        correct: Int,
        percent: Int,
        passed: Bool?,
        byBank: [String: BankScore],
        duration: TimeInterval,
        finishedAt: Date
    ) {
        self.total = total
        self.correct = correct
        self.percent = percent
        self.passed = passed
        self.byBank = byBank
        self.duration = duration
        self.finishedAt = finishedAt
    }
}

/// The session state machine: `ready → active → finished`. Pure of IO — it never
/// touches storage or the clock on its own; callers pass `now` in (tests pass
/// fixed dates, the UI passes wall-clock ticks), and hand the final
/// `SessionResult` to PersistenceKit.
@Observable
public final class StudySession {
    public enum Phase: Hashable, Sendable {
        case ready
        case active
        case finished
    }

    public let config: SessionConfig
    public let questions: [Question]
    public private(set) var phase: Phase = .ready
    public private(set) var currentIndex = 0
    public private(set) var answers: [Int?]
    public private(set) var result: SessionResult?
    public private(set) var startedAt: Date?

    public init(questions: [Question], config: SessionConfig) {
        self.questions = questions
        self.config = config
        self.answers = Array(repeating: nil, count: questions.count)
    }

    public var current: Question? {
        questions.indices.contains(currentIndex) ? questions[currentIndex] : nil
    }

    public var currentAnswer: Int? {
        answers.indices.contains(currentIndex) ? answers[currentIndex] : nil
    }

    public var answeredCount: Int { answers.compactMap { $0 }.count }

    public var deadline: Date? {
        guard let startedAt, let timeLimit = config.timeLimit else { return nil }
        return startedAt.addingTimeInterval(timeLimit)
    }

    /// Seconds left on a timed session, clamped at 0; nil when untimed.
    public func remaining(now: Date) -> TimeInterval? {
        deadline.map { max(0, $0.timeIntervalSince(now)) }
    }

    public func isExpired(now: Date) -> Bool {
        guard let deadline else { return false }
        return now >= deadline
    }

    public func start(now: Date = Date()) {
        guard phase == .ready else { return }
        startedAt = now
        phase = .active
    }

    /// Record an answer for the current question (re-answering is allowed until
    /// submit, matching the web exam's change-your-answer behaviour).
    public func answer(_ choice: Int) {
        guard phase == .active, answers.indices.contains(currentIndex) else { return }
        answers[currentIndex] = choice
    }

    /// Move to the next question, or submit after the last one.
    public func advance(now: Date = Date()) {
        guard phase == .active else { return }
        if currentIndex + 1 < questions.count {
            currentIndex += 1
        } else {
            submit(now: now)
        }
    }

    /// Jump straight to a question (exam navigator).
    public func jump(to index: Int) {
        guard phase == .active, questions.indices.contains(index) else { return }
        currentIndex = index
    }

    /// Score and finish. Unanswered questions count as wrong — the timed exam's
    /// auto-submit path lands here when the clock runs out.
    public func submit(now: Date = Date()) {
        guard phase == .active else { return }
        var correct = 0
        var byBank: [String: BankScore] = [:]
        for (index, question) in questions.enumerated() {
            let isRight = answers[index] == question.correctIndex
            if isRight { correct += 1 }
            var score = byBank[question.bankID] ?? BankScore(correct: 0, total: 0)
            score.total += 1
            if isRight { score.correct += 1 }
            byBank[question.bankID] = score
        }
        let total = questions.count
        let percent = total == 0 ? 0 : Int((Double(correct) / Double(total) * 100).rounded())
        result = SessionResult(
            total: total,
            correct: correct,
            percent: percent,
            passed: config.passMark.map { percent >= $0 },
            byBank: byBank,
            duration: startedAt.map { now.timeIntervalSince($0) } ?? 0,
            finishedAt: now
        )
        phase = .finished
    }
}
