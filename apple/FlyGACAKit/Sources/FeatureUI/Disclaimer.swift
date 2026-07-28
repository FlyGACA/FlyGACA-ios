import SwiftUI

/// The not-affiliated / verify-against-GACA notice — load-bearing product copy
/// that must appear on every study surface, byte-identical to the web's
/// `<Disclaimer />` (src/i18n en.json `disclaimer.strong` / `disclaimer.body`).
/// Never inline or reword this text anywhere else.
public struct Disclaimer: View {
    public init() {}

    public var body: some View {
        (Text(Self.strong).bold() + Text(" ") + Text(Self.copy))
            .font(.footnote)
            .foregroundStyle(.secondary)
            .accessibilityLabel("\(Self.strong) \(Self.copy)")
    }

    static let strong = "Fly GACA is an independent educational platform."
    static let copy =
        "It is not affiliated with, endorsed by, or operated by the General Authority of Civil Aviation (GACA) or the Government of the Kingdom of Saudi Arabia. The official and authoritative source for all civil aviation regulations, publications, and aeronautical information is always GACA. Always verify against the latest official GACA publication at gaca.gov.sa."
}
