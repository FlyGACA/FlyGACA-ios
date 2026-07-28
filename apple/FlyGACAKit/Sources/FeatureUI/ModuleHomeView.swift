import ContentKit
import CoreModels
import PersistenceKit
import StudyEngines
import SwiftUI

/// The home screen every app in the family shares: the module's five core
/// features (study, quiz, flashcards, mock, timed exam) built entirely from the
/// module's content. There is no per-module UI code anywhere — this screen IS
/// the white-label surface.
struct ModuleHomeView: View {
    let content: ModuleContent
    /// Durable study store (nil ⇒ persistence disabled; the UI still works, it
    /// just doesn't save). Threaded to every screen that records progress.
    let store: StudyStore?

    private var bankTitles: [String: String] {
        Dictionary(uniqueKeysWithValues: content.quiz.banks.map { ($0.id, $0.title) })
    }

    private var moduleID: String { content.manifest.id }

    var body: some View {
        List {
            if let groundSchool = content.groundSchool {
                Section("Study") {
                    ForEach(groundSchool.modules) { module in
                        NavigationLink(module.title) {
                            LessonListScreen(module: module, store: store, moduleID: moduleID)
                        }
                    }
                }
            }
            Section("Quiz by topic") {
                ForEach(content.quiz.banks) { bank in
                    NavigationLink {
                        QuizScreen(
                            title: bank.title,
                            session: StudySession(questions: bank.questions, config: .practice),
                            bankTitles: bankTitles,
                            moduleID: moduleID,
                            store: store,
                            bankID: bank.id
                        )
                    } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(bank.title)
                            Text("\(bank.questions.count) questions")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            Section("Flashcards") {
                ForEach(content.quiz.banks) { bank in
                    NavigationLink(bank.title) {
                        FlashcardsScreen(bank: bank, store: store)
                    }
                }
            }
            Section("Exam") {
                NavigationLink("Mock exam (untimed)") {
                    QuizScreen(
                        title: "Mock exam",
                        session: StudySession(
                            questions: QuestionSampler.draw(
                                from: content.quiz.banks, count: content.exam.questionCount),
                            config: .mock(content.exam)),
                        bankTitles: bankTitles,
                        moduleID: moduleID,
                        store: store,
                        bankID: nil
                    )
                }
                NavigationLink("Timed exam — \(content.exam.minutes) min, pass \(content.exam.passMark)%") {
                    ExamScreen(content: content, bankTitles: bankTitles, moduleID: moduleID, store: store)
                }
            }
            Section {
                Disclaimer()
            }
        }
    }
}

/// Read-only lesson list with a per-lesson "mark complete" toggle. Full lesson
/// bodies + Captain Adel hooks come in a later phase; completion state is durable
/// today (persisted via StudyStore, family-wide).
struct LessonListScreen: View {
    let module: GSModule
    let store: StudyStore?
    let moduleID: String

    @State private var doneIDs: Set<String> = []

    var body: some View {
        List {
            Section {
                Text(module.summary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            ForEach(module.lessons) { lesson in
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(lesson.title).font(.headline)
                        Text(lesson.objective)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button {
                        markDone(lesson)
                    } label: {
                        Image(systemName: doneIDs.contains(lesson.id) ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(doneIDs.contains(lesson.id) ? FGTheme.sage : Color.secondary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(doneIDs.contains(lesson.id) ? "Completed" : "Mark complete")
                }
                .padding(.vertical, 2)
            }
        }
        .navigationTitle(module.title)
        .task { await loadDone() }
    }

    private func loadDone() async {
        guard let store else { return }
        if let done = try? await store.lessonsDone(moduleID: moduleID) {
            doneIDs = Set(done)
        }
    }

    private func markDone(_ lesson: GSLesson) {
        guard !doneIDs.contains(lesson.id) else { return }
        doneIDs.insert(lesson.id)
        guard let store else { return }
        Task {
            try? await store.markLessonDone(moduleID: moduleID, lessonID: lesson.id)
            try? await store.touchStreak()
        }
    }
}

struct QuizScreen: View {
    let title: String
    @State var session: StudySession
    let bankTitles: [String: String]
    let moduleID: String
    let store: StudyStore?
    /// Non-nil for a single-topic quiz (the bank's id → best-per-bank score);
    /// nil for the multi-bank mock exam (recorded as an exam attempt).
    let bankID: String?

    var body: some View {
        QuizView(session: session, bankTitles: bankTitles, onFinished: persist, onFlag: flag)
            .navigationTitle(title)
    }

    private func persist(_ result: SessionResult) {
        guard let store else { return }
        Task {
            if let bankID {
                try? await store.recordQuizScore(
                    moduleID: moduleID, bankID: bankID, percent: result.percent)
            } else {
                try? await store.recordExam(moduleID: moduleID, result: result)
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

struct ExamScreen: View {
    let content: ModuleContent
    let bankTitles: [String: String]
    let moduleID: String
    let store: StudyStore?
    @State private var session: StudySession

    init(content: ModuleContent, bankTitles: [String: String], moduleID: String, store: StudyStore?) {
        self.content = content
        self.bankTitles = bankTitles
        self.moduleID = moduleID
        self.store = store
        _session = State(
            initialValue: StudySession(
                questions: QuestionSampler.draw(
                    from: content.quiz.banks, count: content.exam.questionCount),
                config: .exam(content.exam)
            ))
    }

    var body: some View {
        QuizView(session: session, bankTitles: bankTitles, onFinished: persist, onFlag: flag)
            .navigationTitle(content.exam.title ?? "Timed exam")
            .toolbar {
                ToolbarItem(placement: .principal) {
                    ExamTimerView(session: session)
                }
            }
    }

    private func persist(_ result: SessionResult) {
        guard let store else { return }
        Task {
            try? await store.recordExam(moduleID: moduleID, result: result)
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

/// Flip-card runner over one bank. Grading updates a local snapshot for the
/// instant "Deck complete" mastery count AND persists the durable Leitner
/// schedule + streak through StudyStore (family-wide, survives relaunch).
struct FlashcardsScreen: View {
    let bank: Bank
    let store: StudyStore?
    @State private var index = 0
    @State private var srs: [String: SrsEntry] = [:]
    /// The cards due for review, in bank order — snapshotted once per session so
    /// grading a card mid-deck doesn't reshuffle the remaining queue.
    @State private var deck: [Question] = []

    var body: some View {
        VStack {
            if let question = card {
                Text("\(index + 1) of \(deck.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                FlashcardView(
                    front: question.prompt,
                    back: "\(question.correctChoice)\n\n\(question.explanation)"
                ) { correct in
                    grade(question: question, correct: correct)
                }
            } else {
                ContentUnavailableView(
                    "Deck complete",
                    systemImage: "checkmark.seal",
                    description: Text("\(Leitner.masteredCount(in: srs)) cards on track")
                )
            }
        }
        .navigationTitle(bank.title)
        .task { await loadInitialSRS() }
    }

    private var card: Question? {
        deck.indices.contains(index) ? deck[index] : nil
    }

    private func loadInitialSRS() async {
        if let store, let entries = try? await store.srsEntries(bankID: bank.id) {
            srs = entries
        }
        // Unseen cards are always due, so a fresh deck (no store, or no history
        // yet) still surfaces every card — this only narrows the deck once SRS
        // history exists.
        let due = Set(
            Leitner.dueKeys(in: srs, allKeys: bank.questions.map(\.legacyKey), now: Date()))
        deck = bank.questions.filter { due.contains($0.legacyKey) }
    }

    private func grade(question: Question, correct: Bool) {
        // Instant local feedback for the mastery count, even if persistence is off.
        srs[question.legacyKey] = Leitner.schedule(
            srs[question.legacyKey], correct: correct, now: Date())
        index += 1
        guard let store else { return }
        Task {
            _ = try? await store.grade(question: question, correct: correct)
            try? await store.touchStreak()
        }
    }
}
