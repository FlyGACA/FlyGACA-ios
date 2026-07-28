import ContentKit
import PersistenceKit
import SwiftUI

/// The entire root of every white-label app. The ~20-line app shell passes the
/// module id its xcconfig pinned (FGModuleID) plus the shared study store, and
/// this view does the rest: load the bundled content, verify it belongs to this
/// app, mount the shared module home. Adding a new App Store app never adds view
/// code.
public struct SingleModuleRootView: View {
    public let moduleID: String?
    /// The durable study store (nil when persistence is unavailable — see
    /// FlyGACAApp). Threaded to every screen that reads/writes progress.
    public let store: StudyStore?

    @State private var state = LoadState.loading

    enum LoadState {
        case loading
        case failed(String)
        case loaded(ModuleContent)
    }

    public init(moduleID: String? = nil, store: StudyStore? = nil) {
        self.moduleID = moduleID
        self.store = store
    }

    public var body: some View {
        NavigationStack {
            switch state {
            case .loading:
                ProgressView()
            case .failed(let message):
                ContentUnavailableView(
                    "Content unavailable",
                    systemImage: "exclamationmark.triangle",
                    description: Text(message)
                )
            case .loaded(let content):
                ModuleHomeView(content: content, store: store)
                    .navigationTitle(Self.displayName(for: content.manifest.id))
            }
        }
        .task { load() }
    }

    private func load() {
        guard let directory = ContentLoader.bundledContentDirectory() else {
            state = .failed("The app bundle has no Content folder — run scripts/build-ios-content.mjs and add the folder to this target.")
            return
        }
        do {
            let store = ContentStore(bundledDirectory: directory, moduleID: moduleID)
            state = .loaded(try store.load())
        } catch {
            state = .failed(String(describing: error))
        }
    }

    /// "ppl-exam" → "PPL Exam". Product display names live in the target's
    /// xcconfig (CFBundleDisplayName); this is only the in-app fallback title.
    static func displayName(for moduleID: String) -> String {
        let acronyms: Set<String> = ["ppl", "cpl", "ir", "ifr", "atpl", "aip", "elp", "elpt", "foi", "agi"]
        return moduleID
            .split(separator: "-")
            .map { part in
                let word = String(part)
                return acronyms.contains(word) ? word.uppercased() : word.capitalized
            }
            .joined(separator: " ")
    }
}
