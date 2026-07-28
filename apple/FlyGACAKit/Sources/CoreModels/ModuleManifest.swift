import Foundation

/// The module this app is — one exam-prep pack from src/lib/prepCatalog.ts,
/// serialized into the app's Content/module.json by scripts/build-ios-content.mjs.
/// Coding keys keep the web's field names (`bankIds`, `moduleIds`, …) so the
/// manifest format never forks; adding a new App Store app (IFR, FOI, AGI, …) is
/// a new manifest + content folder, zero new Swift.
public struct ModuleManifest: Identifiable, Hashable, Sendable, Decodable {
    public enum Kind: String, Hashable, Sendable, Decodable {
        case certificate
        case subject
    }

    public enum Status: String, Hashable, Sendable, Decodable {
        case live
        case soon
    }

    public enum Access: String, Hashable, Sendable, Decodable {
        case free
        case paid
    }

    public let id: String
    public let kind: Kind
    public let status: Status
    public let access: Access
    /// Quiz banks — also the pool for the module's combined quiz + timed exam.
    public let bankIDs: [String]
    /// Ground-school module ids (groundschool.json).
    public let lessonModuleIDs: [String]
    /// Reading-path ids (paths-index.json).
    public let pathIDs: [String]
    /// Study-sheet PDF slugs (pdfs-index.json).
    public let sheetSlugs: [String]
    /// Deeper corpus reading (reference-index.json slugs).
    public let librarySlugs: [String]
    /// Per-module timed-exam overrides; unset falls back to the corpus default.
    public let exam: ExamOverride?

    public init(
        id: String,
        kind: Kind,
        status: Status,
        access: Access,
        bankIDs: [String],
        lessonModuleIDs: [String] = [],
        pathIDs: [String] = [],
        sheetSlugs: [String] = [],
        librarySlugs: [String] = [],
        exam: ExamOverride? = nil
    ) {
        self.id = id
        self.kind = kind
        self.status = status
        self.access = access
        self.bankIDs = bankIDs
        self.lessonModuleIDs = lessonModuleIDs
        self.pathIDs = pathIDs
        self.sheetSlugs = sheetSlugs
        self.librarySlugs = librarySlugs
        self.exam = exam
    }

    enum CodingKeys: String, CodingKey {
        case id, kind, status, access, exam
        case bankIDs = "bankIds"
        case lessonModuleIDs = "moduleIds"
        case pathIDs = "pathIds"
        case sheetSlugs
        case librarySlugs
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        kind = try c.decode(Kind.self, forKey: .kind)
        status = try c.decode(Status.self, forKey: .status)
        access = try c.decode(Access.self, forKey: .access)
        bankIDs = try c.decodeIfPresent([String].self, forKey: .bankIDs) ?? []
        lessonModuleIDs = try c.decodeIfPresent([String].self, forKey: .lessonModuleIDs) ?? []
        pathIDs = try c.decodeIfPresent([String].self, forKey: .pathIDs) ?? []
        sheetSlugs = try c.decodeIfPresent([String].self, forKey: .sheetSlugs) ?? []
        librarySlugs = try c.decodeIfPresent([String].self, forKey: .librarySlugs) ?? []
        exam = try c.decodeIfPresent(ExamOverride.self, forKey: .exam)
    }

    /// The module's effective exam settings (its overrides over the corpus default).
    public func resolvedExam(base: ExamConfig) -> ExamConfig {
        exam?.resolved(over: base) ?? base
    }
}

/// Content/module.json — the manifest plus the corpus stamp it was built from.
public struct ModuleFile: Sendable, Decodable {
    public let contentVersion: String?
    public let module: ModuleManifest

    public init(contentVersion: String?, module: ModuleManifest) {
        self.contentVersion = contentVersion
        self.module = module
    }
}
