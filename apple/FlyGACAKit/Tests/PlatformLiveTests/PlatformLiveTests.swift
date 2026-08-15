import AppServices
import CoreModels
@testable import PlatformLive
import XCTest

final class PlatformLiveTests: XCTestCase {

    func testFirestoreDocumentEncoderFormatsProgressSummaryCorrectly() {
        let now = Date()
        let summary = ProgressSummary(
            quizBest: ["bank_1": 95, "bank_2": 80],
            examBest: 92,
            examCount: 3,
            gsDone: ["lesson_1", "lesson_2"],
            updatedAt: now
        )

        let document = FirestoreDocumentEncoder.encode(summary)
        guard let fields = document["fields"] as? [String: Any] else {
            XCTFail("Missing 'fields' dictionary in encoded document")
            return
        }

        // Validate quizBest
        guard let quizBestDict = fields["quizBest"] as? [String: Any],
              let mapValue = quizBestDict["mapValue"] as? [String: Any],
              let quizFields = mapValue["fields"] as? [String: Any] else {
            XCTFail("Invalid quizBest structure")
            return
        }
        XCTAssertEqual((quizFields["bank_1"] as? [String: Any])?["integerValue"] as? String, "95")
        XCTAssertEqual((quizFields["bank_2"] as? [String: Any])?["integerValue"] as? String, "80")

        // Validate examBest & examCount
        XCTAssertEqual((fields["examBest"] as? [String: Any])?["integerValue"] as? String, "92")
        XCTAssertEqual((fields["examCount"] as? [String: Any])?["integerValue"] as? String, "3")

        // Validate gsDone
        guard let gsDoneDict = fields["gsDone"] as? [String: Any],
              let arrayValue = gsDoneDict["arrayValue"] as? [String: Any],
              let values = arrayValue["values"] as? [[String: String]] else {
            XCTFail("Invalid gsDone structure")
            return
        }
        XCTAssertEqual(values.count, 2)
        XCTAssertEqual(values[0]["stringValue"], "lesson_1")
        XCTAssertEqual(values[1]["stringValue"], "lesson_2")
    }

    func testFirebaseAuthServiceManagesUserID() async throws {
        let auth = FirebaseAuthService(userID: "user_123")
        let currentID = await auth.currentUserID
        XCTAssertEqual(currentID, "user_123")

        try await auth.signOut()
        let afterSignOut = await auth.currentUserID
        XCTAssertNil(afterSignOut)
    }

    func testPlatformLiveFactoryConstructsServices() async throws {
        let auth = PlatformLiveFactory.makeAuth(userID: "test_user")
        XCTAssertEqual(auth.currentUserID, "test_user")

        let sync = PlatformLiveFactory.makeProgressSync(projectID: "flygaca-app", authProvider: auth)
        XCTAssertNotNil(sync)

        let chat = PlatformLiveFactory.makeChatClient()
        XCTAssertNotNil(chat)

        let payment = PlatformLiveFactory.makePaymentService(apiKey: "pk_test_123")
        XCTAssertNotNil(payment)
    }

    func testPaymentRequestCalculatesHalalasCorrectlyForAppsAndBundle() async throws {
        let appPayment = PaymentRequest(amountHalalas: 7900, description: "Fly GACA ELPT App")
        XCTAssertEqual(appPayment.amountHalalas, 7900)
        XCTAssertEqual(appPayment.currency, "SAR")

        let bundlePayment = PaymentRequest(amountHalalas: 13900, description: "Saudi Pilot Study Pack Bundle")
        XCTAssertEqual(bundlePayment.amountHalalas, 13900)

        let mock = MockPayment()
        let response = try await mock.createPayment(appPayment)
        XCTAssertEqual(response.amount, 7900)
        XCTAssertEqual(response.status, "paid")
    }
}

