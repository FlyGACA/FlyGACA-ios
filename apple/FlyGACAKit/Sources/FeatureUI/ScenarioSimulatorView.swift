import CoreModels
import PersistenceKit
import StudyEngines
import SwiftUI

/// The Scenario Simulator — an ICAO ELPT-style check-ride. A briefing card
/// sets the scene, then a shuffled run of live-radio scenario questions plays
/// through the shared QuizView (transcript cards included) in mock-exam mode —
/// no mid-run answer reveals, a scored debrief at the end.
///
/// Scenario questions are detected by CONTENT (a prompt that opens with a
/// radio exchange), never by hard-coded bank ids, so any module grows a
/// simulator automatically the day scenario content lands in its banks.
struct ScenarioSimulatorView: View {
    /// The full scenario pool across all of the module's banks.
    let questions: [Question]
    /// The module's exam settings — reused so the run scores like the mock.
    let exam: ExamConfig
    let bankTitles: [String: String]
    let moduleID: String
    let store: StudyStore?
    /// Questions per run; a check-ride is a short, intense sample, not the pool.
    let runLength: Int

    @State private var session: StudySession?
    /// The drawn run — kept for per-bank score persistence on finish.
    @State private var drawn: [Question] = []

    init(
        questions: [Question],
        exam: ExamConfig,
        bankTitles: [String: String],
        moduleID: String,
        store: StudyStore?,
        runLength: Int = 10
    ) {
        self.questions = questions
        self.exam = exam
        self.bankTitles = bankTitles
        self.moduleID = moduleID
        self.store = store
        self.runLength = runLength
    }

    /// True when the prompt opens with a radio exchange — the same rule
    /// QuizView uses to render the ScenarioCard.
    static func isScenario(_ question: Question) -> Bool {
        let blocks = question.prompt.components(separatedBy: "\n\n")
        guard blocks.count > 1, let first = blocks.first else { return false }
        let lines = first.components(separatedBy: "\n").filter { !$0.isEmpty }
        return !lines.isEmpty && lines.allSatisfy { TranscriptLine.split($0) != nil }
    }

    var body: some View {
        Group {
            if let session {
                QuizView(
                    session: session,
                    bankTitles: bankTitles,
                    onFinished: persist,
                    onFlag: flag
                )
            } else {
                briefing
            }
        }
        .navigationTitle(Loc.t("sim.title"))
    }

    private var briefing: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Label(Loc.t("sim.brief.title"), systemImage: "headphones")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(FGTheme.gold)
                    Text(Loc.t("sim.brief.body"))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(FGTheme.deep)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(FGTheme.mist, lineWidth: 1)
                )

                HStack {
                    ResultStat(
                        label: Loc.t("sim.brief.pool"),
                        value: "\(questions.count)")
                    ResultStat(
                        label: Loc.t("sim.brief.run"),
                        value: "\(min(runLength, questions.count))")
                    ResultStat(
                        label: Loc.t("sim.brief.passMark"),
                        value: "\(exam.passMark)%")
                }

                Button(Loc.t("sim.brief.start")) {
                    start()
                }
                .buttonStyle(.borderedProminent)
                .tint(FGTheme.teal)
                .frame(maxWidth: .infinity)
            }
            .padding()
        }
    }

    private func start() {
        drawn = Array(questions.shuffled().prefix(runLength))
        session = StudySession(questions: drawn, config: .mock(exam))
    }

    private func persist(_ result: SessionResult) {
        guard let store else { return }
        Task {
            // A run drawn entirely from one bank counts as that bank's best
            // quiz score; a mixed run still counts toward the streak.
            let bankIDs = Set(drawn.map(\.bankID))
            if bankIDs.count == 1, let bankID = bankIDs.first {
                try? await store.recordQuizScore(
                    moduleID: moduleID, bankID: bankID, percent: result.percent)
            }
            try? await store.touchStreak()
        }
    }

    private func flag(_ question: Question, flagged: Bool) {
        guard let store else { return }
        Task {
            try? await store.setFlag(
                moduleID: moduleID, bankID: question.bankID, index: question.index, flagged: flagged)
        }
    }
}
