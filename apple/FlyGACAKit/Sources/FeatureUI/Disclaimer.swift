import SwiftUI

/// The not-affiliated / verify-against-GACA notice — load-bearing product copy
/// that must appear on every study surface, byte-identical to the web's
/// `<Disclaimer />` (src/i18n `disclaimer.strong` / `disclaimer.body`). The text
/// itself lives in Resources/{en,ar}.lproj/Localizable.strings, copied verbatim
/// from the monorepo's en.json / ar.json. Never inline or reword it anywhere.
public struct Disclaimer: View {
    public init() {}

    public var body: some View {
        (Text(Self.strong).bold() + Text(" ") + Text(Self.copy))
            .font(.footnote)
            .foregroundStyle(.secondary)
            .accessibilityLabel("\(Self.strong) \(Self.copy)")
    }

    static var strong: String { Loc.t("disclaimer.strong") }
    static var copy: String { Loc.t("disclaimer.body") }
}
