import SwiftUI

/// One flip card + grade buttons. Grading semantics (Leitner boxes, due dates)
/// live in StudyEngines/PersistenceKit — this view only reports correct/wrong.
public struct FlashcardView: View {
    public let front: String
    public let back: String
    public let onGrade: (Bool) -> Void

    @State private var revealed = false

    public init(front: String, back: String, onGrade: @escaping (Bool) -> Void) {
        self.front = front
        self.back = back
        self.onGrade = onGrade
    }

    public var body: some View {
        VStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(FGTheme.deep)
                Text(revealed ? back : front)
                    .font(revealed ? .body : .headline)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .padding(20)
            }
            .frame(maxWidth: .infinity, minHeight: 220)
            .onTapGesture {
                withAnimation(.spring(duration: 0.3)) { revealed.toggle() }
            }
            .accessibilityAddTraits(.isButton)
            .accessibilityLabel(revealed ? back : front)

            if revealed {
                HStack(spacing: 12) {
                    Button("Again") { grade(false) }
                        .buttonStyle(.bordered)
                        .tint(FGTheme.clay)
                    Button("Got it") { grade(true) }
                        .buttonStyle(.borderedProminent)
                        .tint(FGTheme.teal)
                }
            } else {
                Text("Tap the card to reveal")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
    }

    private func grade(_ correct: Bool) {
        revealed = false
        onGrade(correct)
    }
}
