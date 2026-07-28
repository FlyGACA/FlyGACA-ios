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

    let text: String
    let mark: Mark
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
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
}

/// End-of-session summary: score, pass/fail when scored, per-bank breakdown.
struct SessionResultView: View {
    let result: SessionResult
    let bankTitles: [String: String]

    var body: some View {
        List {
            Section {
                HStack {
                    ResultStat(label: "Score", value: "\(result.percent)%")
                    ResultStat(label: "Correct", value: "\(result.correct)/\(result.total)")
                    if let passed = result.passed {
                        ResultStat(label: "Result", value: passed ? "Pass" : "Fail")
                    }
                }
            }
            if result.byBank.count > 1 {
                Section("By topic") {
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
                }
            }
            Section {
                Disclaimer()
            }
        }
    }
}
