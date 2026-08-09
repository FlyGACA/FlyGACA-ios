import CoreModels
import StudyEngines
import SwiftUI

/// The one question-answering surface shared by practice quiz, mock and timed
/// exam — behaviour differences (feedback timing, scoring, clock) come entirely
/// from the session's `SessionConfig`, never from per-module view code.
public struct QuizView: View {
    public let session: StudySession
    /// Bank id → display title, for the results breakdown.
    public let bankTitles: [String: String]
    public let onFinished: ((SessionResult) -> Void)?
    /// Called when the current question's flagged state is toggled — QuizView
    /// stays decoupled from StudyStore (same pattern as `onFinished`); the
    /// caller is responsible for persisting it.
    public let onFlag: ((Question, Bool) -> Void)?
    @State private var flaggedIDs: Set<String> = []

    public init(
        session: StudySession,
        bankTitles: [String: String] = [:],
        onFinished: ((SessionResult) -> Void)? = nil,
        onFlag: ((Question, Bool) -> Void)? = nil
    ) {
        self.session = session
        self.bankTitles = bankTitles
        self.onFinished = onFinished
        self.onFlag = onFlag
    }

    public var body: some View {
        Group {
            switch session.phase {
            case .ready:
                ProgressView()
            case .active:
                active
            case .finished:
                if let result = session.result {
                    SessionResultView(result: result, bankTitles: bankTitles)
                }
            }
        }
        .onAppear { session.start() }
        .onChange(of: session.phase) { _, phase in
            if phase == .finished, let result = session.result {
                onFinished?(result)
            }
        }
    }

    @ViewBuilder
    private var active: some View {
        if let question = session.current {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text(Loc.t("quiz.questionProgress", session.currentIndex + 1, session.questions.count))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Button {
                            toggleFlag(question)
                        } label: {
                            Image(systemName: flaggedIDs.contains(question.id) ? "flag.fill" : "flag")
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(flaggedIDs.contains(question.id) ? FGTheme.clay : Color.secondary)
                        .accessibilityLabel(
                            Loc.t(flaggedIDs.contains(question.id) ? "a11y.unflagQuestion" : "a11y.flagQuestion"))
                    }
                    SessionProgressBar(
                        answered: session.currentIndex,
                        total: session.questions.count
                    )
                    if let scenario = scenarioParts(of: question.prompt) {
                        ScenarioCard(lines: scenario.transcript)
                        Text(scenario.question)
                            .font(.headline)
                    } else {
                        Text(question.prompt)
                            .font(.headline)
                    }
                    ForEach(question.choices.indices, id: \.self) { index in
                        ChoiceRow(
                            index: index,
                            text: question.choices[index],
                            mark: mark(for: index, in: question)
                        ) {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                session.answer(index)
                            }
                        }
                    }
                    if session.config.revealsAnswers, session.currentAnswer != nil {
                        feedback(for: question)
                    }
                    Button(Loc.t(session.currentIndex + 1 < session.questions.count ? "common.next" : "common.finish")) {
                        session.advance()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(FGTheme.teal)
                    .disabled(session.currentAnswer == nil)
                }
                .padding()
            }
        }
    }

    /// ELPT-style scenario prompts carry a radio exchange before the question
    /// ("TOWER: …\nPILOT: …\n\nWhat should the pilot do?"). When the first
    /// block is a transcript (any line with an ALL-CAPS speaker prefix), it is
    /// split out for the cockpit-style ScenarioCard; anything else renders as
    /// one plain prompt.
    private func scenarioParts(of prompt: String) -> (transcript: [String], question: String)? {
        let blocks = prompt.components(separatedBy: "\n\n")
        guard blocks.count > 1 else { return nil }
        // Leading blocks whose lines are ALL speaker-prefixed are transcript;
        // the first block with a non-prefixed line starts the question prose.
        var transcript: [String] = []
        var questionStart = blocks.count
        for (offset, block) in blocks.enumerated() {
            let lines = block.components(separatedBy: "\n").filter { !$0.isEmpty }
            if !lines.isEmpty, lines.allSatisfy({ TranscriptLine.split($0) != nil }) {
                transcript.append(contentsOf: lines)
            } else {
                questionStart = offset
                break
            }
        }
        guard !transcript.isEmpty, questionStart < blocks.count else { return nil }
        return (transcript, blocks[questionStart...].joined(separator: "\n\n"))
    }

    private func toggleFlag(_ question: Question) {
        let flagged = !flaggedIDs.contains(question.id)
        if flagged {
            flaggedIDs.insert(question.id)
        } else {
            flaggedIDs.remove(question.id)
        }
        onFlag?(question, flagged)
    }

    private func mark(for index: Int, in question: Question) -> ChoiceRow.Mark {
        let picked = session.currentAnswer
        if session.config.revealsAnswers, picked != nil {
            if index == question.correctIndex { return .correct }
            if index == picked { return .wrong }
            return .none
        }
        return index == picked ? .selected : .none
    }

    @ViewBuilder
    private func feedback(for question: Question) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(Loc.t(session.currentAnswer == question.correctIndex ? "quiz.correct" : "quiz.notQuite"))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(
                    session.currentAnswer == question.correctIndex ? FGTheme.sage : FGTheme.clay)
            Text(question.explanation)
                .font(.subheadline)
            if let citation = question.citation {
                Text(citation)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 10).strokeBorder(FGTheme.mist, lineWidth: 1))
    }
}
