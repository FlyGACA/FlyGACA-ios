import FeatureUI
import PersistenceKit
import SwiftUI

// The ENTIRE app shell, shared source-for-source by every target in the family
// (PPL, ELPT, AIP, …). Which app this binary is comes from build configuration,
// not code: each target's xcconfig pins FG_MODULE_ID (surfaced in Info.plist as
// FGModuleID) plus its bundle id, display name, icon and Content folder.
// Adding a new App Store app must never require editing this file.
@main
struct FlyGACAApp: App {
    private let moduleID = Bundle.main.object(forInfoDictionaryKey: "FGModuleID") as? String

    /// The single write path for user study state, backed by the shared App Group
    /// SwiftData container. If the container can't be opened (corrupt store, disk
    /// full, missing entitlement in a dev build), `store` is nil and the app stays
    /// fully usable — persistence is best-effort, never a hard dependency, matching
    /// the app's local-first "degrade to a no-op" philosophy.
    private let store: StudyStore?

    init() {
        store = (try? Persistence.container(appGroup: Persistence.appGroupID))
            .map { StudyStore(container: $0) }
    }

    var body: some Scene {
        WindowGroup {
            SingleModuleRootView(moduleID: moduleID, store: store)
        }
    }
}
