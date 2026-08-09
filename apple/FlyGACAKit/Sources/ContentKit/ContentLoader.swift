import CoreModels
import Foundation

/// Everything one app's module ships: its manifest plus its verbatim slice of
/// the shared corpus (emitted by scripts/build-ios-content.mjs).
public struct ModuleContent: Sendable {
    public let manifest: ModuleManifest
    public let contentVersion: String?
    public let quiz: QuizFile
    public let groundSchool: GroundSchoolFile?
    public let paths: PathsFile?

    /// The module's effective timed-exam settings (pack overrides over the
    /// corpus default — same overlay as the web mock exam).
    public var exam: ExamConfig {
        manifest.resolvedExam(base: quiz.exam)
    }

    public init(
        manifest: ModuleManifest,
        contentVersion: String?,
        quiz: QuizFile,
        groundSchool: GroundSchoolFile? = nil,
        paths: PathsFile? = nil
    ) {
        self.manifest = manifest
        self.contentVersion = contentVersion
        self.quiz = quiz
        self.groundSchool = groundSchool
        self.paths = paths
    }
}

public enum ContentError: Error, Equatable {
    case missingResource(String)
    /// The bundle's content is for a different module than the app expects —
    /// a build-configuration mistake (wrong Content folder on the target).
    case moduleMismatch(found: String, expected: String)
}

public enum ContentLoader {
    /// The blue "Content" folder reference on the app target. nil in unit tests
    /// and previews — pass an explicit directory there instead.
    public static func bundledContentDirectory(in bundle: Bundle = .main) -> URL? {
        bundle.url(forResource: "Content", withExtension: nil)
    }

    /// Load a module's content from a directory laid out by the bundler:
    /// module.json + quiz.json required; groundschool.json / paths-index.json
    /// optional (not every pack has lessons or reading paths).
    public static func load(from directory: URL) throws -> ModuleContent {
        let moduleFile = try JSONDecoder().decode(ModuleFile.self, from: data("module.json", in: directory))
        var quiz = try QuizFile.decode(data("quiz.json", in: directory))
        // Additive, app-local bank packs (`quiz-extra.json`, same wire schema)
        // are appended after the synced corpus banks. The active directory is
        // tried first and the bundle is the fallback, so a remote-refresh cache
        // snapshot (which carries only quiz.json + module.json) can never
        // silently drop an app-local pack.
        if let extra = extraBanks(activeDirectory: directory) {
            quiz = QuizFile(generated: quiz.generated, exam: quiz.exam, banks: quiz.banks + extra)
        }
        let groundSchool = try? JSONDecoder().decode(
            GroundSchoolFile.self, from: data("groundschool.json", in: directory))
        let paths = try? JSONDecoder().decode(
            PathsFile.self, from: data("paths-index.json", in: directory))
        return ModuleContent(
            manifest: moduleFile.module,
            contentVersion: moduleFile.contentVersion,
            quiz: quiz,
            groundSchool: groundSchool,
            paths: paths
        )
    }

    /// The banks of an optional `quiz-extra.json`, from the active directory or
    /// (falling back) the app bundle. Returns nil when the file is absent;
    /// a malformed pack also returns nil — additive content must never block
    /// the synced corpus from loading.
    private static func extraBanks(activeDirectory: URL) -> [Bank]? {
        var candidates = [activeDirectory]
        if let bundled = bundledContentDirectory(), bundled != activeDirectory {
            candidates.append(bundled)
        }
        for directory in candidates {
            let url = directory.appendingPathComponent("quiz-extra.json")
            guard let data = try? Data(contentsOf: url) else { continue }
            if let decoded = try? QuizFile.decode(data) {
                return decoded.banks
            }
        }
        return nil
    }

    private static func data(_ name: String, in directory: URL) throws -> Data {
        let url = directory.appendingPathComponent(name)
        guard let data = try? Data(contentsOf: url) else {
            throw ContentError.missingResource(name)
        }
        return data
    }
}
