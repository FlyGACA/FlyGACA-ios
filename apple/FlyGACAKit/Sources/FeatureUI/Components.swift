import StudyEngines
import SwiftUI

/// One headline number on a results/analytics surface (web `ResultStat`).
public struct ResultStat: View {
    public let label: String
    public let value: String

    public init(label: String, value: String) {
        self.label = label
        self.value = value
    }

    public var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.title2.weight(.semibold))
                .monospacedDigit()
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

/// A single answer option row with reveal states.
struct ChoiceRow: View {
    enum Mark {
        case none
        case selected
        case correct
        case wrong
    }

    /// 0-based option index — rendered as an A/B/C/D badge before the text.
    let index: Int
    let text: String
    let mark: Mark
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Text(String(UnicodeScalar(65 + index)!))
                    .font(.caption.weight(.bold))
                    .foregroundStyle(badgeText)
                    .frame(width: 24, height: 24)
                    .background(Circle().fill(badgeFill))
                    .overlay(Circle().strokeBorder(borderColor, lineWidth: 1))
                Text(text)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                switch mark {
                case .correct: Image(systemName: "checkmark.circle.fill").foregroundStyle(FGTheme.sage)
                case .wrong: Image(systemName: "xmark.circle.fill").foregroundStyle(FGTheme.clay)
                case .selected: Image(systemName: "circle.inset.filled").foregroundStyle(FGTheme.teal)
                case .none: Image(systemName: "circle").foregroundStyle(.tertiary)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(borderColor, lineWidth: 1)
            )
            .contentShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }

    private var borderColor: Color {
        switch mark {
        case .correct: FGTheme.sage
        case .wrong: FGTheme.clay
        case .selected: FGTheme.teal
        case .none: FGTheme.mist
        }
    }

    private var badgeFill: Color {
        switch mark {
        case .correct: FGTheme.sage.opacity(0.18)
        case .wrong: FGTheme.clay.opacity(0.18)
        case .selected: FGTheme.teal.opacity(0.22)
        case .none: Color.clear
        }
    }

    private var badgeText: Color {
        switch mark {
        case .correct: FGTheme.sage
        case .wrong: FGTheme.clay
        case .selected: FGTheme.teal
        case .none: Color.secondary
        }
    }
}

/// End-of-session summary: score, pass/fail when scored, per-bank breakdown.
struct SessionResultView: View {
    let result: SessionResult
    let bankTitles: [String: String]

    var body: some View {
        List {
            Section {
                HStack {
                    ResultStat(label: Loc.t("result.score"), value: "\(result.percent)%")
                    ResultStat(label: Loc.t("result.correct"), value: "\(result.correct)/\(result.total)")
                    if let passed = result.passed {
                        ResultStat(
                            label: Loc.t("result.result"),
                            value: passed ? Loc.t("result.pass") : Loc.t("result.fail"))
                    }
                }
            }
            if result.byBank.count > 1 {
                Section {
                    ForEach(result.byBank.keys.sorted(), id: \.self) { bankID in
                        let score = result.byBank[bankID]!
                        HStack {
                            Text(bankTitles[bankID] ?? bankID)
                            Spacer()
                            Text("\(score.correct)/\(score.total)")
                                .monospacedDigit()
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Text(Loc.t("result.byTopic"))
                }
            }
            Section {
                Disclaimer()
            }
        }
    }
}

/// A thin progress bar for a running session — answered fraction fills teal.
struct SessionProgressBar: View {
    let answered: Int
    let total: Int

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(FGTheme.mist)
                Capsule()
                    .fill(FGTheme.teal)
                    .frame(width: geo.size.width * fraction)
                    .animation(.easeInOut(duration: 0.25), value: fraction)
            }
        }
        .frame(height: 4)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Loc.t("a11y.progress", answered, total))
    }

    private var fraction: CGFloat {
        total > 0 ? CGFloat(answered) / CGFloat(total) : 0
    }
}

/// One line of a radio exchange ("TOWER: cleared to land …") rendered
/// cockpit-style: speaker label in teal caps, the transmission in a monospaced
/// voice that reads like a CPDLC/transcript block. Used by `ScenarioCard`.
struct TranscriptLine: View {
    let line: String

    var body: some View {
        if let split = Self.split(line) {
            (Text(split.speaker.uppercased() + "  ")
                .font(.caption.weight(.bold))
                .foregroundStyle(FGTheme.teal)
             + Text(split.text)
                .font(.callout.monospaced()))
            .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            Text(line)
                .font(.callout.monospaced())
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    /// "TOWER: go around" → ("TOWER", "go around"); a line with no speaker
    /// prefix returns nil and renders as a plain line.
    static func split(_ line: String) -> (speaker: String, text: String)? {
        guard let colon = line.firstIndex(of: ":") else { return nil }
        let speaker = String(line[line.startIndex..<colon])
        let trimmed = speaker.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty,
              trimmed.count <= 12,
              trimmed.allSatisfy({ $0.isUppercase || $0.isNumber || $0 == " " || $0 == "/" }) else { return nil }
        return (trimmed, String(line[colon...].dropFirst()).trimmingCharacters(in: .whitespaces))
    }
}

/// The scenario surface for ELPT-style questions: the radio exchange sits in a
/// bordered card ("RADIO EXCHANGE") visually distinct from the question itself,
/// so a live-transmission scenario reads like the real test, not a wall of text.
struct ScenarioCard: View {
    let lines: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(Loc.t("quiz.transcript"), systemImage: "dot.radiowaves.left.and.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(FGTheme.teal)
            ForEach(lines, id: \.self) { line in
                TranscriptLine(line: line)
            }
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
    }
}
