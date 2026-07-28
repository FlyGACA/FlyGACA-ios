import StudyEngines
import SwiftUI

/// The exam countdown. Renders the session's remaining time once a second and
/// drives the auto-submit when the clock hits zero — the session itself stays
/// clock-free (web parity: the mock exam auto-submits at 0:00).
public struct ExamTimerView: View {
    public let session: StudySession

    public init(session: StudySession) {
        self.session = session
    }

    public var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            if let remaining = session.remaining(now: context.date) {
                Text(Self.format(remaining))
                    .font(.headline)
                    .monospacedDigit()
                    .foregroundStyle(remaining <= 60 ? FGTheme.clay : .secondary)
                    .accessibilityLabel("Time remaining \(Self.format(remaining))")
                    .onChange(of: remaining <= 0) { _, expired in
                        if expired { session.submit(now: context.date) }
                    }
            }
        }
    }

    static func format(_ interval: TimeInterval) -> String {
        let seconds = Int(interval.rounded())
        return String(format: "%d:%02d", seconds / 60, seconds % 60)
    }
}
