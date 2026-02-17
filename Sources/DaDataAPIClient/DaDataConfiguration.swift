//
//  DaDataConfiguration.swift
//  DaDataAPIClient
//
//  Created by Артем Денисов on 18.02.2026.
//

import Foundation


public struct DaDataConfiguration: Sendable {
    public var token: String
    public var baseURL: URL
    public var timeout: TimeInterval
    public var retryPolicy: RetryPolicy

    public init(
        token: String,
        baseURL: URL = URL(string: "https://suggestions.dadata.ru")!,
        timeout: TimeInterval = 15,
        retryPolicy: RetryPolicy = .default
    ) {
        self.token = token
        self.baseURL = baseURL
        self.timeout = timeout
        self.retryPolicy = retryPolicy
    }
}
