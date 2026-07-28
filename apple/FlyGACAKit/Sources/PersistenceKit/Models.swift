import Foundation
import SwiftData

// SwiftData models are deliberately FLAT (scalars + Data blobs for nested
// payloads) — flat models keep lightweight migration on the table as the schema
// grows, and the blobs (per-bank breakdowns, id lists) are read-modify-write
// values the store owns, never queried against.
//
// All models live in the shared App Group container (see Persistence.container)
// so streaks, SRS state and attempts carry across every app in the family.

/// One finished scored session (mock or timed exam).
@Model
public final class ExamAttemptRecord {
    public var moduleID: String
    public var date: Date
    public var scorePercent: Int
    public var passed: Bool
    public var durationSeconds: Int
    /// JSON-encoded [String: BankScore] — the per-bank breakdown.
    public var byBankData: Data?

    public init(
        moduleID: String,
        date: Date,
        scorePercent: Int,
        passed: Bool,
        durationSeconds: Int,
        byBankData: Data?
    ) {
        self.moduleID = moduleID
        self.date = date
        self.scorePercent = scorePercent
        self.passed = passed
        self.durationSeconds = durationSeconds
        self.byBankData = byBankData
    }
}

/// One flashcard's Leitner state. Dual-keyed on purpose:
///  - `key` = "bankID|cardKey" (web index-string keying — progress parity), and
///  - `questionID` = the stable content hash, so when a refreshed corpus shifts
///    indices the row is reconciled by hash instead of being orphaned.
@Model
public final class CardSRSRecord {
    @Attribute(.unique) public var key: String
    public var bankID: String
    /// The web card key — question index as a string.
    public var cardKey: String
    public var questionID: String
    public var box: Int
    /// UTC "yyyy-mm-dd" (string compare = due check; web parity).
    public var dueDay: String

    public init(key: String, bankID: String, cardKey: String, questionID: String, box: Int, dueDay: String) {
        self.key = key
        self.bankID = bankID
        self.cardKey = cardKey
        self.questionID = questionID
        self.box = box
        self.dueDay = dueDay
    }
}

/// Per-module rollup: best quiz score per bank, lessons done, flagged questions.
@Model
public final class ModuleProgressRecord {
    @Attribute(.unique) public var moduleID: String
    /// JSON-encoded [String: Int] — bankID → best percent.
    public var quizBestData: Data
    /// JSON-encoded [String] — completed lesson ids.
    public var lessonsDoneData: Data
    /// JSON-encoded [String: [Int]] — bankID → flagged question indices.
    public var flaggedData: Data

    public init(moduleID: String, quizBestData: Data, lessonsDoneData: Data, flaggedData: Data) {
        self.moduleID = moduleID
        self.quizBestData = quizBestData
        self.lessonsDoneData = lessonsDoneData
        self.flaggedData = flaggedData
    }
}

/// The family-wide daily streak (single row, key "streak").
@Model
public final class StreakRecord {
    @Attribute(.unique) public var key: String
    public var day: String
    public var count: Int

    public init(key: String = "streak", day: String, count: Int) {
        self.key = key
        self.day = day
        self.count = count
    }
}
