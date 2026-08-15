import AppServices
import CoreModels
import Foundation

/// Production implementation of `PaymentProviding` communicating with Moyasar Payment Gateway API
/// (`https://api.moyasar.com/v1/payments`). Supports Mada, Apple Pay, and Credit Card payments in SAR.
public struct MoyasarPaymentService: PaymentProviding, Sendable {
    public let apiKey: String
    public let baseURL: URL
    private let urlSession: URLSession

    public init(
        apiKey: String,
        baseURL: URL = URL(string: "https://api.moyasar.com/v1/payments")!,
        urlSession: URLSession = .shared
    ) {
        self.apiKey = apiKey
        self.baseURL = baseURL
        self.urlSession = urlSession
    }

    public func createPayment(_ request: PaymentRequest) async throws -> PaymentResponse {
        var urlRequest = URLRequest(url: baseURL)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // HTTP Basic Auth with Moyasar API Key (API Key as username, empty password)
        let loginData = Data("\(apiKey):".utf8)
        let base64LoginData = loginData.base64EncodedString()
        urlRequest.setValue("Basic \(base64LoginData)", forHTTPHeaderField: "Authorization")

        let body: [String: Any] = [
            "amount": request.amountHalalas,
            "currency": request.currency,
            "description": request.description,
            "callback_url": request.callbackURL
        ]
        urlRequest.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await urlSession.data(for: urlRequest)
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }

        return try decodePaymentResponse(from: data)
    }

    public func verifyPayment(id: String) async throws -> PaymentResponse {
        let fetchURL = baseURL.appendingPathComponent(id)
        var urlRequest = URLRequest(url: fetchURL)
        urlRequest.httpMethod = "GET"

        let loginData = Data("\(apiKey):".utf8)
        let base64LoginData = loginData.base64EncodedString()
        urlRequest.setValue("Basic \(base64LoginData)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await urlSession.data(for: urlRequest)
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }

        return try decodePaymentResponse(from: data)
    }

    private func decodePaymentResponse(from data: Data) throws -> PaymentResponse {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let id = json["id"] as? String,
              let status = json["status"] as? String,
              let amount = json["amount"] as? Int else {
            throw URLError(.cannotParseResponse)
        }

        let fee = json["fee"] as? Int
        let source = json["source"] as? [String: Any]
        let transactionUrl = source?["transaction_url"] as? String

        return PaymentResponse(
            id: id,
            status: status,
            amount: amount,
            fee: fee,
            transactionUrl: transactionUrl
        )
    }
}
