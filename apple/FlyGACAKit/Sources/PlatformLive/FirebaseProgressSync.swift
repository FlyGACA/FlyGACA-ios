import AppServices
import CoreModels
import Foundation

/// Uploads progress summaries to Firestore at `users/{uid}/progress/summary`,
/// matching the web app's `ProgressSummary` data contract.
public struct FirebaseProgressSync: ProgressSyncing, Sendable {
    public let projectID: String
    public let authProvider: any AuthProviding
    private let urlSession: URLSession

    public init(
        projectID: String = "flygaca-app",
        authProvider: any AuthProviding,
        urlSession: URLSession = .shared
    ) {
        self.projectID = projectID
        self.authProvider = authProvider
        self.urlSession = urlSession
    }

    public func upload(_ summary: ProgressSummary) async throws {
        guard let uid = authProvider.currentUserID, !uid.isEmpty else {
            // Unauthenticated users store progress locally; upload is best-effort.
            return
        }

        let endpoint = URL(string: "https://firestore.googleapis.com/v1/projects/\(projectID)/databases/(default)/documents/users/\(uid)/progress/summary")!
        var request = URLRequest(url: endpoint)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let payload = FirestoreDocumentEncoder.encode(summary)
        request.httpBody = try JSONSerialization.data(withJSONObject: payload, options: [])

        let (_, response) = try await urlSession.data(for: request)
        if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
            throw URLError(.badServerResponse)
        }
    }
}

/// Utility for converting `ProgressSummary` into Firestore REST API document field structure.
public enum FirestoreDocumentEncoder {
    public static func encode(_ summary: ProgressSummary) -> [String: Any] {
        var fields: [String: Any] = [:]

        // quizBest: mapValue
        var quizMap: [String: [String: Any]] = [:]
        for (key, val) in summary.quizBest {
            quizMap[key] = ["integerValue": String(val)]
        }
        fields["quizBest"] = ["mapValue": ["fields": quizMap]]

        // examBest: integerValue or nullValue
        if let best = summary.examBest {
            fields["examBest"] = ["integerValue": String(best)]
        } else {
            fields["examBest"] = ["nullValue": NSNull()]
        }

        // examCount: integerValue
        fields["examCount"] = ["integerValue": String(summary.examCount)]

        // gsDone: arrayValue
        let doneValues = summary.gsDone.map { ["stringValue": $0] }
        fields["gsDone"] = ["arrayValue": ["values": doneValues]]

        // updatedAt: timestampValue (ISO8601 string)
        let formatter = ISO8601DateFormatter()
        fields["updatedAt"] = ["timestampValue": formatter.string(from: summary.updatedAt)]

        return ["fields": fields]
    }
}
