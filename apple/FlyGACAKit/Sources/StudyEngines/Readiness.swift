import CoreModels
import Foundation

/// Exam-readiness snapshot for a module — the number the analytics dashboard
/// leads with, blended from what actually predicts a pass: recent exam scores
/// (half), topic coverage and flashcard mastery (a quarter each). With no exams
/// taken yet the blend renormalizes over coverage + mastery so the score never
/// pretends precision it doesn't have.
public struct ModuleReadiness: Hashable, Sendable {
    /// Share of the module's banks with a recorded quiz score, 0…1.
    public let coverage: Double
    /// Share of seen flashcards at/above the Leitner mastery box, 0…1.
    public let mastery: Double
    /// Mean of the recent exam percents, 0…1; nil when no exams taken.
    public let examAverage: Double?
    /// The blended readiness score, 0…100.
    public let score: Int
}

public enum ReadinessAnalytics {
    public static func readiness(
        quizBest: [String: Int],
        bankIDs: [String],
        srs: [String: SrsEntry],
        cardCount: Int,
        examPercents: [Int]
    ) -> ModuleReadiness {
        let coverage = bankIDs.isEmpty
            ? 0
            : Double(bankIDs.filter { quizBest[$0] != nil }.count) / Double(bankIDs.count)
        let mastery = cardCount == 0
            ? 0
            : Double(Leitner.masteredCount(in: srs)) / Double(cardCount)
        let examAverage = examPercents.isEmpty
            ? nil
            : Double(examPercents.reduce(0, +)) / Double(examPercents.count) / 100

        let blend: Double
        if let examAverage {
            blend = examAverage * 0.5 + coverage * 0.25 + mastery * 0.25
        } else {
            blend = (coverage + mastery) / 2
        }
        return ModuleReadiness(
            coverage: coverage,
            mastery: mastery,
            examAverage: examAverage,
            score: Int((blend * 100).rounded())
        )
    }
}
