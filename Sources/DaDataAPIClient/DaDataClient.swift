//
//  DaDataClient.swift
//  DaDataAPIClient
//
//  Created by Артем Денисов on 18.02.2026.
//

import Foundation



public final class DaDataClient: Sendable {
    private let config: DaDataConfiguration
    private let transport: DaDataTransport
    private let jsonDecoder: JSONDecoder
    private let jsonEncoder: JSONEncoder

    public init(
        configuration: DaDataConfiguration,
        transport: DaDataTransport = URLSessionTransport()
    ) {
        self.config = configuration
        self.transport = transport

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .useDefaultKeys
        self.jsonDecoder = decoder

        let encoder = JSONEncoder()
        encoder.outputFormatting = []
        self.jsonEncoder = encoder
    }

    /// Finds organization by INN (or OGRN).
    /// - Parameters:
    ///   - innOrOgrn: INN (10/12) or OGRN.
    ///   - count: suggestions count (default 1).
    public func findParty(
        innOrOgrn: String,
        count: Int = 1
    ) async throws -> [DaDataSuggestion<DaDataParty>] {
        let endpoint = config.baseURL
            .appendingPathComponent("suggestions")
            .appendingPathComponent("api")
            .appendingPathComponent("4_1")
            .appendingPathComponent("rs")
            .appendingPathComponent("findById")
            .appendingPathComponent("party")

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.timeoutInterval = config.timeout
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Token \(config.token)", forHTTPHeaderField: "Authorization")

        let payload = DaDataFindByIdRequest(query: innOrOgrn, count: count)
        request.httpBody = try jsonEncoder.encode(payload)

        let response: DaDataSuggestionsResponse<DaDataParty> = try await sendWithRetry(request)
        return response.suggestions
    }

    /// Convenience: returns the first suggestion or nil.
    public func findPartyFirst(innOrOgrn: String) async throws -> DaDataSuggestion<DaDataParty>? {
        try await findParty(innOrOgrn: innOrOgrn, count: 1).first
    }

    // MARK: - Internals

    private func sendWithRetry<T: Decodable>(_ request: URLRequest) async throws -> T {
        var attempt = 0
        var lastError: Error?

        while attempt < max(1, config.retryPolicy.maxAttempts) {
            attempt += 1
            do {
                let (data, http) = try await transport.send(request)

                if (200...299).contains(http.statusCode) {
                    do {
                        return try jsonDecoder.decode(T.self, from: data)
                    } catch {
                        throw DaDataError.decoding(underlying: error, body: data)
                    }
                }

                // Parse rate limit / retry hints
                let retryAfter = parseRetryAfter(http)

                // Decide retryability
                if isRetryable(statusCode: http.statusCode) && attempt < config.retryPolicy.maxAttempts {
                    let delay = computeDelay(attempt: attempt, retryAfter: retryAfter)
                    try await sleep(delay)
                    continue
                }

                // Non-retryable or last attempt
                throw DaDataError.http(
                    statusCode: http.statusCode,
                    body: data,
                    retryAfter: retryAfter
                )
            } catch {
                lastError = error

                // Transport errors may be transient; retry if attempts left.
                if attempt < config.retryPolicy.maxAttempts,
                   DaDataError.isRetryableTransport(error) {
                    let delay = computeDelay(attempt: attempt, retryAfter: nil)
                    try await sleep(delay)
                    continue
                }

                throw error
            }
        }

        throw lastError ?? DaDataError.unknown
    }

    private func isRetryable(statusCode: Int) -> Bool {
        statusCode == 429 || (500...599).contains(statusCode)
    }

    private func parseRetryAfter(_ response: HTTPURLResponse) -> TimeInterval? {
        guard let value = response.value(forHTTPHeaderField: "Retry-After") else { return nil }
        // Retry-After can be seconds. (HTTP-date is possible, but rare here)
        if let seconds = TimeInterval(value.trimmingCharacters(in: .whitespacesAndNewlines)) {
            return max(0, seconds)
        }
        return nil
    }

    private func computeDelay(attempt: Int, retryAfter: TimeInterval?) -> TimeInterval {
        if let retryAfter = retryAfter { return min(retryAfter, config.retryPolicy.maxDelay) }

        // Exponential backoff with jitter
        let exp = min(config.retryPolicy.maxDelay,
                      config.retryPolicy.baseDelay * pow(2.0, Double(attempt - 1)))
        let jitter = Double.random(in: 0...(exp * 0.25))
        return min(config.retryPolicy.maxDelay, exp + jitter)
    }

    private func sleep(_ seconds: TimeInterval) async throws {
        let ns = UInt64(max(0, seconds) * 1_000_000_000)
        try await Task.sleep(nanoseconds: ns)
    }
}
