import Foundation

/// Localized UI chrome for FeatureUI, resolved from this SPM module's own bundle.
///
/// Every white-label app in the family ships the same FeatureUI, so the strings
/// live here (Resources/{en,ar}.lproj/Localizable.strings) rather than in each
/// app target. We resolve them through `Bundle.module` **explicitly**: SwiftUI's
/// implicit `LocalizedStringKey` lookup (a bare `Text("…")`) targets the *app*
/// bundle, which has none of these keys — so it would render the raw key. Going
/// through `Bundle.module.localizedString` is deterministic and toolchain-neutral
/// (no String Catalog build step), which matters because `swift test` on CI is
/// the only place this package compiles.
///
/// Only interface chrome is localized. Question prompts, answer choices, bank
/// titles and citations are **content** — authored in English in the monorepo,
/// synced here as read-only snapshots — and are shown verbatim in every locale.
enum Loc {
    /// A localized string for `key`, from the current app language's `.lproj`.
    /// Falls back to the key itself if a translation is missing (so a stray key
    /// surfaces as English text in dev, never an empty label).
    static func t(_ key: String) -> String {
        Bundle.module.localizedString(forKey: key, value: key, table: nil)
    }

    /// A localized format string filled with `args` (e.g. `"%1$lld of %2$lld"`).
    /// Arabic entries may reorder with positional specifiers.
    static func t(_ key: String, _ args: CVarArg...) -> String {
        let format = Bundle.module.localizedString(forKey: key, value: key, table: nil)
        return String(format: format, locale: .current, arguments: args)
    }
}
