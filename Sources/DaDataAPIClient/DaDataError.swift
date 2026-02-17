//
//  DaDataError.swift
//  DaDataAPIClient
//
//  Created by Артем Денисов on 18.02.2026.
//


import Foundation

public enum DaDataError: Error, Sendable {
    case invalidResponse
    case transport(Error)

    case http(statusCode: Int, body: Data, retryAfter: TimeInterval?)
    case decoding(underlying: Error, body: Data)

    case unknown

    public static func isRetryableTransport(_ error: Error) -> Bool {
        // Conservative: common transient URL errors
        let ns = error as NSError
        guard ns.domain == NSURLErrorDomain else { return false }

        switch ns.code {
        case NSURLErrorTimedOut,
             NSURLErrorCannotFindHost,
             NSURLErrorCannotConnectToHost,
             NSURLErrorNetworkConnectionLost,
             NSURLErrorDNSLookupFailed,
             NSURLErrorNotConnectedToInternet:
            return true
        default:
            return false
        }
    }
}

public extension DaDataError {
    /// Safe short description for logs/UI.
    var message: String {
        switch self {
        case .invalidResponse:
            return "Invalid HTTP response."
        case .transport(let error):
            return "Transport error: \(error.localizedDescription)"
        case .http(let status, _, let retryAfter):
            if let retryAfter = retryAfter {
                return "HTTP \(status). Retry after \(retryAfter)s."
            }
            return "HTTP \(status)."
        case .decoding(let underlying, _):
            return "Decoding error: \(underlying.localizedDescription)"
        case .unknown:
            return "Unknown error."
        }
    }

    /// Debug helper (do NOT show raw body to end-user in production).
    func bodyString(maxBytes: Int = 8_192) -> String? {
        let data: Data
        switch self {
        case .http(_, let body, _): data = body
        case .decoding(_, let body): data = body
        default: return nil
        }
        let clipped = data.prefix(maxBytes)
        return String(data: clipped, encoding: .utf8)
    }
}
