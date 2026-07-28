import CoreModels
import Foundation
import StudyEngines
import SwiftData

/// A finished exam as read back for history/analytics (a value copy — model
/// objects never escape the store actor).
public struct PastExam: Hashable, Sendable {
    public let date: Date
    public let percent: Int
    public let passed: Bool
    public let durationSeconds: Int
    public let byBank: [String: BankScore]
}

/// The single write path for user study state. Engines stay pure and hand their
/// results here; views read value snapshots back. Runs on its own actor so
/// grading/saving never blocks the UI.
@ModelActor
public actor StudyStore {
    /// Web parity: exam history is capped at the 10 most recent per module.
    public static let examHistoryLimit = 10

    /// Cross-module entry point — the @ModelActor-generated init is not
    /// guaranteed public across toolchains.
    public init(container: ModelContainer) {
        self.init(modelContainer: container)
    }

    // ── Exams ──

    public func recordExam(moduleID: String, result: SessionResult) throws {
        modelContext.insert(
            ExamAttemptRecord(
                moduleID: moduleID,
                date: result.finishedAt,
                scorePercent: result.percent,
                passed: result.passed ?? false,
                durationSeconds: Int(result.duration),
                byBankData: try? JSONEncoder().encode(result.byBank)
            ))
        let all = try fetchExams(moduleID: moduleID)
        for stale in all.dropFirst(Self.examHistoryLimit) {
            modelContext.delete(stale)
        }
        try modelContext.save()
    }

    /// Most-recent-first exam history for the module.
    public func examHistory(moduleID: String) throws -> [PastExam] {
        try fetchExams(moduleID: moduleID).map { record in
            PastExam(
                date: record.date,
                percent: record.scorePercent,
                passed: record.passed,
                durationSeconds: record.durationSeconds,
                byBank: record.byBankData
                    .flatMap { try? JSONDecoder().decode([String: BankScore].self, from: $0) } ?? [:]
            )
        }
    }

    private func fetchExams(moduleID: String) throws -> [ExamAttemptRecord] {
        var descriptor = FetchDescriptor<ExamAttemptRecord>(
            predicate: #Predicate { $0.moduleID == moduleID })
        descriptor.sortBy = [SortDescriptor(\.date, order: .reverse)]
        return try modelContext.fetch(descriptor)
    }

    // ── Flashcards / SRS ──

    /// Grade a card and persist its new schedule; returns the new entry.
    public func grade(question: Question, correct: Bool, now: Date = Date()) throws -> SrsEntry {
        let key = "\(question.bankID)|\(question.legacyKey)"
        let record = try fetchCard(key: key)
        let previous = record.map { SrsEntry(box: $0.box, due: $0.dueDay) }
        let entry = Leitner.schedule(previous, correct: correct, now: now)
        if let record {
            record.box = entry.box
            record.dueDay = entry.due
            record.questionID = question.id
        } else {
            modelContext.insert(
                CardSRSRecord(
                    key: key,
                    bankID: question.bankID,
                    cardKey: question.legacyKey,
                    questionID: question.id,
                    box: entry.box,
                    dueDay: entry.due
                ))
        }
        try modelContext.save()
        return entry
    }

    /// All SRS entries for a bank, keyed by web card key (index string).
    public func srsEntries(bankID: String) throws -> [String: SrsEntry] {
        let descriptor = FetchDescriptor<CardSRSRecord>(
            predicate: #Predicate { $0.bankID == bankID })
        let records = try modelContext.fetch(descriptor)
        return Dictionary(
            uniqueKeysWithValues: records.map { ($0.cardKey, SrsEntry(box: $0.box, due: $0.dueDay)) })
    }

    private func fetchCard(key: String) throws -> CardSRSRecord? {
        var descriptor = FetchDescriptor<CardSRSRecord>(predicate: #Predicate { $0.key == key })
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }

    // ── Quiz bests ──

    /// Record a topic-quiz score, keeping the best per bank (web `quizBest`).
    public func recordQuizScore(moduleID: String, bankID: String, percent: Int) throws {
        let record = try fetchProgress(moduleID: moduleID)
        var best = decode([String: Int].self, record.quizBestData) ?? [:]
        if percent > (best[bankID] ?? -1) {
            best[bankID] = percent
            record.quizBestData = encode(best)
            try modelContext.save()
        }
    }

    public func quizBest(moduleID: String) throws -> [String: Int] {
        decode([String: Int].self, try fetchProgress(moduleID: moduleID).quizBestData) ?? [:]
    }

    // ── Lessons ──

    public func markLessonDone(moduleID: String, lessonID: String) throws {
        let record = try fetchProgress(moduleID: moduleID)
        var done = decode([String].self, record.lessonsDoneData) ?? []
        guard !done.contains(lessonID) else { return }
        done.append(lessonID)
        record.lessonsDoneData = encode(done)
        try modelContext.save()
    }

    public func lessonsDone(moduleID: String) throws -> [String] {
        decode([String].self, try fetchProgress(moduleID: moduleID).lessonsDoneData) ?? []
    }

    // ── Flags ──

    /// Toggle a question's flagged state within its bank (web parity: flagged
    /// question indices, per module).
    public func setFlag(moduleID: String, bankID: String, index: Int, flagged: Bool) throws {
        let record = try fetchProgress(moduleID: moduleID)
        var byBank = decode([String: [Int]].self, record.flaggedData) ?? [:]
        var indices = byBank[bankID] ?? []
        if flagged {
            if !indices.contains(index) { indices.append(index) }
        } else {
            indices.removeAll { $0 == index }
        }
        byBank[bankID] = indices
        record.flaggedData = encode(byBank)
        try modelContext.save()
    }

    /// Flagged question indices for one bank within a module.
    public func flaggedIndices(moduleID: String, bankID: String) throws -> [Int] {
        let byBank = decode([String: [Int]].self, try fetchProgress(moduleID: moduleID).flaggedData) ?? [:]
        return byBank[bankID] ?? []
    }

    private func fetchProgress(moduleID: String) throws -> ModuleProgressRecord {
        var descriptor = FetchDescriptor<ModuleProgressRecord>(
            predicate: #Predicate { $0.moduleID == moduleID })
        descriptor.fetchLimit = 1
        if let existing = try modelContext.fetch(descriptor).first {
            return existing
        }
        let fresh = ModuleProgressRecord(
            moduleID: moduleID,
            quizBestData: encode([String: Int]()),
            lessonsDoneData: encode([String]()),
            flaggedData: encode([String: [Int]]())
        )
        modelContext.insert(fresh)
        return fresh
    }

    // ── Content refresh reconciliation (Phase 4) ──

    /// After `ContentRefresher` pulls a newer corpus slice, a bank's question
    /// order can shift. Rewrite each row's `cardKey`/`key` to the question's new
    /// position, matched by the stable content hash (`questionID`) — so Leitner
    /// progress survives reordering instead of silently regrading the wrong
    /// question. Rows whose question no longer exists in the refreshed bank are
    /// left untouched (orphaned, not deleted — the corpus edit may be reverted).
    public func reconcileSRS(bankID: String, quiz: QuizFile) throws {
        guard let bank = quiz.bank(id: bankID) else { return }
        // uniquingKeysWith rather than uniqueKeysWithValues: two questions
        // sharing a stable id (identical prompt text) must never crash
        // reconciliation — keep the first and let the rest resolve on their
        // own accord next pass.
        let byQuestionID = Dictionary(bank.questions.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })

        let descriptor = FetchDescriptor<CardSRSRecord>(predicate: #Predicate { $0.bankID == bankID })
        let records = try modelContext.fetch(descriptor)
        var liveKeys = Set(records.map(\.key))

        var changed = false
        for record in records {
            guard let question = byQuestionID[record.questionID], question.legacyKey != record.cardKey else {
                continue
            }
            let newKey = "\(bankID)|\(question.legacyKey)"
            // Guard against a (should-never-happen) collision with another
            // record's current key rather than violate the unique constraint.
            guard !liveKeys.contains(newKey) else { continue }
            liveKeys.remove(record.key)
            record.cardKey = question.legacyKey
            record.key = newKey
            liveKeys.insert(newKey)
            changed = true
        }
        if changed {
            try modelContext.save()
        }
    }

    // ── Streak ──

    /// Advance the family-wide streak for a study event now.
    @discardableResult
    public func touchStreak(now: Date = Date()) throws -> Streak {
        var descriptor = FetchDescriptor<StreakRecord>(predicate: #Predicate { $0.key == "streak" })
        descriptor.fetchLimit = 1
        let record = try modelContext.fetch(descriptor).first
        let previous = record.map { Streak(day: $0.day, count: $0.count) } ?? .none
        let next = Streaks.next(previous, now: now)
        if let record {
            record.day = next.day
            record.count = next.count
        } else {
            modelContext.insert(StreakRecord(day: next.day, count: next.count))
        }
        try modelContext.save()
        return next
    }

    // ── Blob helpers ──

    private func encode(_ value: some Encodable) -> Data {
        (try? JSONEncoder().encode(value)) ?? Data()
    }

    private func decode<T: Decodable>(_ type: T.Type, _ data: Data) -> T? {
        try? JSONDecoder().decode(type, from: data)
    }
}
