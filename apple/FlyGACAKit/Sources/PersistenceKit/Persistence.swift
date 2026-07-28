import Foundation
import SwiftData

public enum Persistence {
    /// The shared container every app target declares in its App Groups
    /// capability — one store for the whole family, so sign-in-free continuity
    /// (streaks, SRS, attempts) works across PPL/ELPT/AIP/… on the same device.
    public static let appGroupID = "group.com.flygaca.study"

    public static let schema = Schema([
        ExamAttemptRecord.self,
        CardSRSRecord.self,
        ModuleProgressRecord.self,
        StreakRecord.self,
    ])

    /// App targets pass `appGroup: Persistence.appGroupID`; tests and previews
    /// use `inMemory: true`; plain `container()` (default store location) keeps
    /// `swift test` runnable on a Mac with no entitlements.
    public static func container(appGroup: String? = nil, inMemory: Bool = false) throws -> ModelContainer {
        let configuration: ModelConfiguration
        if inMemory {
            configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        } else if let appGroup {
            configuration = ModelConfiguration(schema: schema, groupContainer: .identifier(appGroup))
        } else {
            configuration = ModelConfiguration(schema: schema)
        }
        return try ModelContainer(for: schema, configurations: [configuration])
    }
}
