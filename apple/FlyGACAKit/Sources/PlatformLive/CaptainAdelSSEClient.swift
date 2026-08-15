import AppServices
import CoreModels
import Foundation

/// Production implementation of `ChatClient` calling the Captain Adel AI endpoint via SSE streaming.
public struct CaptainAdelSSEClient: ChatClient, Sendable {
    public let baseURL: URL
    private let urlSession: URLSession

    public init(
        baseURL: URL = URL(string: "https://flygaca.com/api/chat")!,
        urlSession: URLSession = .shared
    ) {
        self.baseURL = baseURL
        self.urlSession = urlSession
    }

    public func send(_ message: String, history: [ChatTurn]) async throws -> AsyncThrowingStream<String, any Error> {
        var request = URLRequest(url: baseURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("text/event-stream", forHTTPHeaderField: "Accept")

        var turns = history
        turns.append(ChatTurn(role: "user", text: message))

        let body: [String: Any] = [
            "messages": turns.map { ["role": $0.role, "content": $0.text] }
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (bytes, response) = try await urlSession.bytes(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }

        return AsyncThrowingStream { continuation in
            Task {
                do {
                    for try await line in bytes.lines {
                        if line.hasPrefix("data: ") {
                            let text = String(line.dropFirst(6))
                            if text == "[DONE]" {
                                break
                            }
                            continuation.yield(text)
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
}
