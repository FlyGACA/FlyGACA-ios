import Foundation

/// The app's slice of paths-index.json (ordered reading paths for Study mode).
public struct PathsFile: Sendable, Decodable {
    public let paths: [ReadingPath]
}

public struct ReadingPath: Identifiable, Hashable, Sendable, Decodable {
    public let id: String
    public let title: String
    public let desc: String?
    public let steps: [PathStep]
}

/// One step — a labelled link into the regulatory corpus (web `PathStep`).
public struct PathStep: Hashable, Sendable, Decodable {
    public let label: String
    public let note: String?
    public let kind: String?
    public let id: String?
    public let anchor: String?
}
