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
        let quiz = try QuizFile.decode(data("quiz.json", in: directory))
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

    private static func data(_ name: String, in directory: URL) throws -> Data {
        let url = directory.appendingPathComponent(name)
        guard let data = try? Data(contentsOf: url) else {
            throw ContentError.missingResource(name)
        }
        return data
    }
}
