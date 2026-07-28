import CoreModels
import XCTest

@testable import ContentKit

final class ContentLoaderTests: XCTestCase {
    private var directory: URL!

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("flygaca-content-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: directory)
    }

    private func write(_ name: String, _ json: String) throws {
        try Data(json.utf8).write(to: directory.appendingPathComponent(name))
    }

    private func writeFixtureModule(exam: String = "") throws {
        try write(
            "module.json",
            """
            { "contentVersion": "v1", "module": {
              "id": "aip", "kind": "subject", "status": "live", "access": "paid",
              "bankIds": ["aip-ais"]\(exam) } }
            """)
        try write(
            "quiz.json",
            """
            { "generated": "v1",
              "exam": { "questions": 25, "minutes": 30, "passMark": 75 },
              "banks": [ { "id": "aip-ais", "title": "AIP & AIS", "desc": "", "questions": [
                { "q": "One?", "options": ["A", "B"], "answer": 0, "explain": "e" }
              ] } ] }
            """)
    }

    func testLoadsModuleAndQuizWithoutOptionalFiles() throws {
        try writeFixtureModule()
        let content = try ContentLoader.load(from: directory)
        XCTAssertEqual(content.manifest.id, "aip")
        XCTAssertEqual(content.contentVersion, "v1")
        XCTAssertEqual(content.quiz.banks.count, 1)
        XCTAssertNil(content.groundSchool)
        XCTAssertNil(content.paths)
        XCTAssertEqual(content.exam.passMark, 75)
    }

    func testManifestExamOverrideAppliesToContent() throws {
        try writeFixtureModule(exam: #", "exam": { "questions": 10, "minutes": 15 }"#)
        let content = try ContentLoader.load(from: directory)
        XCTAssertEqual(content.exam.questionCount, 10)
        XCTAssertEqual(content.exam.minutes, 15)
        XCTAssertEqual(content.exam.passMark, 75) // unset override falls back
    }

    func testMissingQuizFailsLoudly() throws {
        try write("module.json", #"{ "module": { "id": "x", "kind": "subject", "status": "live", "access": "free" } }"#)
        XCTAssertThrowsError(try ContentLoader.load(from: directory)) { error in
            XCTAssertEqual(error as? ContentError, .missingResource("quiz.json"))
        }
    }

    func testStoreRejectsContentForAnotherModule() throws {
        try writeFixtureModule()
        let store = ContentStore(bundledDirectory: directory, moduleID: "ppl-exam")
        XCTAssertThrowsError(try store.load()) { error in
            XCTAssertEqual(error as? ContentError, .moduleMismatch(found: "aip", expected: "ppl-exam"))
        }
    }

    func testStoreLoadsWhenModuleMatches() throws {
        try writeFixtureModule()
        let store = ContentStore(bundledDirectory: directory, moduleID: "aip")
        XCTAssertEqual(try store.load().manifest.id, "aip")
    }
}
