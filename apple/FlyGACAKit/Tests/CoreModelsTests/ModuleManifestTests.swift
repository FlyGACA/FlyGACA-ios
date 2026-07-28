import XCTest

@testable import CoreModels

final class ModuleManifestTests: XCTestCase {
    /// The exact shape scripts/build-ios-content.mjs writes to Content/module.json
    /// — a prepCatalog.ts pack, web field names untouched.
    func testDecodesBundlerModuleJSON() throws {
        let data = Data(
            """
            {
              "contentVersion": "2026-07-01T00:00:00.000Z",
              "module": {
                "id": "elp",
                "kind": "certificate",
                "status": "live",
                "access": "paid",
                "bankIds": ["radio-elpt"],
                "sheetSlugs": ["saelpt-study-sheet"]
              }
            }
            """.utf8)
        let file = try JSONDecoder().decode(ModuleFile.self, from: data)
        XCTAssertEqual(file.contentVersion, "2026-07-01T00:00:00.000Z")
        XCTAssertEqual(file.module.id, "elp")
        XCTAssertEqual(file.module.kind, .certificate)
        XCTAssertEqual(file.module.status, .live)
        XCTAssertEqual(file.module.access, .paid)
        XCTAssertEqual(file.module.bankIDs, ["radio-elpt"])
        XCTAssertEqual(file.module.sheetSlugs, ["saelpt-study-sheet"])
        // Absent optional lists default to empty — packs omit what they don't use.
        XCTAssertEqual(file.module.lessonModuleIDs, [])
        XCTAssertEqual(file.module.pathIDs, [])
        XCTAssertEqual(file.module.librarySlugs, [])
        XCTAssertNil(file.module.exam)
    }

    func testExamOverrideResolvesOverBase() throws {
        let data = Data(
            """
            {
              "id": "aip", "kind": "subject", "status": "live", "access": "paid",
              "bankIds": ["aip-ais"],
              "exam": { "questions": 40, "passMark": 80 }
            }
            """.utf8)
        let manifest = try JSONDecoder().decode(ModuleManifest.self, from: data)
        let resolved = manifest.resolvedExam(base: .standard)
        XCTAssertEqual(resolved.questionCount, 40)
        XCTAssertEqual(resolved.minutes, 30) // unset override falls back
        XCTAssertEqual(resolved.passMark, 80)

        let noOverride = ModuleManifest(
            id: "x", kind: .subject, status: .live, access: .free, bankIDs: [])
        XCTAssertEqual(noOverride.resolvedExam(base: .standard), .standard)
    }
}
