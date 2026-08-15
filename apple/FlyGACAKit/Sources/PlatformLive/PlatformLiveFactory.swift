import AppServices
import CoreModels
import Foundation

/// Factory helper providing live PlatformLive instances for injection at the app root.
public enum PlatformLiveFactory {
    public static func makeAuth(userID: String? = nil) -> any AuthProviding {
        FirebaseAuthService(userID: userID)
    }

    public static func makeProgressSync(
        projectID: String = "flygaca-app",
        authProvider: any AuthProviding
    ) -> any ProgressSyncing {
        FirebaseProgressSync(projectID: projectID, authProvider: authProvider)
    }

    public static func makeChatClient(
        endpoint: URL = URL(string: "https://flygaca.com/api/chat")!
    ) -> any ChatClient {
        CaptainAdelSSEClient(baseURL: endpoint)
    }

    public static func makePaymentService(apiKey: String) -> any PaymentProviding {
        MoyasarPaymentService(apiKey: apiKey)
    }
}

