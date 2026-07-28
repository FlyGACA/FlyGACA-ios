import SwiftUI

/// The Falcon palette — ported from src/styles/tokens.css, the design-token
/// source of truth. Add colors here only when tokens.css has them; never
/// hard-code a hex in a view.
public enum FGTheme {
    /// Primary dark canvas.
    public static let night = Color(hex: 0x0A0E12)
    /// Elevated card on dark.
    public static let deep = Color(hex: 0x0F1A24)
    /// Dividers, subtle borders.
    public static let mist = Color(hex: 0x1A2A38)
    /// Primary brand — buttons, fills.
    public static let teal = Color(hex: 0x2D6E8A)
    /// Secondary accent, success.
    public static let sage = Color(hex: 0x8FC9A8)
    /// Heritage accent — used sparingly.
    public static let gold = Color(hex: 0xC8A04A)
    /// Warm clay — caution / "hold" states.
    public static let clay = Color(hex: 0xCF6B52)
}

extension Color {
    init(hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: 1
        )
    }
}
