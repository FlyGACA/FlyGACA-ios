import Foundation

/// The app's slice of groundschool.json (lessons for Study mode). Decoded
/// tolerantly — only the fields the app renders; unknown web fields are ignored.
public struct GroundSchoolFile: Sendable, Decodable {
    public let title: String?
    public let intro: String?
    public let modules: [GSModule]
}

public struct GSModule: Identifiable, Hashable, Sendable, Decodable {
    public let id: String
    public let title: String
    public let summary: String
    /// Linked quiz bank id, when the module has a matching bank.
    public let quiz: String?
    public let lessons: [GSLesson]
}

public struct GSLesson: Identifiable, Hashable, Sendable, Decodable {
    public let id: String
    public let title: String
    public let objective: String
    /// Ready-made Captain Adel prompt for this lesson (used once chat ships).
    public let adel: String?
}
