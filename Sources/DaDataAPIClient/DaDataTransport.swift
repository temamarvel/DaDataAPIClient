//
//  DaDataTransport.swift
//  DaDataAPIClient
//
//  Created by Артем Денисов on 18.02.2026.
//

import Foundation


public protocol DaDataTransport: Sendable {
    func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse)
}

/// Default transport that works on macOS 10.15+ (no async URLSession APIs required).
public final class URLSessionTransport: DaDataTransport {
    private let session: URLSession

    public init(configuration: URLSessionConfiguration = .ephemeral) {
        configuration.waitsForConnectivity = true
        self.session = URLSession(configuration: configuration)
    }

    public func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        try await withCheckedThrowingContinuation { continuation in
            let task = session.dataTask(with: request) { data, response, error in
                if let error = error {
                    continuation.resume(throwing: DaDataError.transport(error))
                    return
                }
                guard let http = response as? HTTPURLResponse else {
                    continuation.resume(throwing: DaDataError.invalidResponse)
                    return
                }
                continuation.resume(returning: (data ?? Data(), http))
            }
            task.resume()
        }
    }
}
