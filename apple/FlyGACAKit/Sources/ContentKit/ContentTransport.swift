import Foundation

/// One HTTP round-trip's worth of what `ContentRefresher` needs — kept minimal
/// so tests can fake it without spinning up a real `URLSession`.
public struct ContentFetchResult: Sendable {
    public let statusCode: Int
    /// nil on a 304 (Not Modified) — there is nothing new to read.
    public let data: Data?
    public let etag: String?

    public init(statusCode: Int, data: Data?, etag: String?) {
        self.statusCode = statusCode
        self.data = data
        self.etag = etag
    }
}

/// The network seam `ContentRefresher` talks to. Pure Foundation — no Firebase —
/// so it lives in ContentKit itself rather than waiting on PlatformLive (Phase 4).
public protocol ContentTransporting: Sendable {
    func fetch(_ url: URL, ifNoneMatch etag: String?) async throws -> ContentFetchResult
}

/// The real transport: a conditional GET against `URLSession`.
public struct URLSessionContentTransport: ContentTransporting {
    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func fetch(_ url: URL, ifNoneMatch etag: String?) async throws -> ContentFetchResult {
        var request = URLRequest(url: url)
        if let etag {
            request.setValue(etag, forHTTPHeaderField: "If-None-Match")
        }
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw ContentRefreshError.malformedResponse
        }
        return ContentFetchResult(
            statusCode: http.statusCode,
            data: http.statusCode == 304 ? nil : data,
            etag: http.value(forHTTPHeaderField: "ETag")
        )
    }
}
