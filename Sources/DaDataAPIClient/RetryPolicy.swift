//
//  RetryPolicy.swift
//  DaDataAPIClient
//
//  Created by Артем Денисов on 18.02.2026.
//

import Foundation


public struct RetryPolicy: Sendable {
    public var maxAttempts: Int
    public var baseDelay: TimeInterval
    public var maxDelay: TimeInterval

    public init(maxAttempts: Int, baseDelay: TimeInterval, maxDelay: TimeInterval) {
        self.maxAttempts = maxAttempts
        self.baseDelay = baseDelay
        self.maxDelay = maxDelay
    }

    public static let `default` = RetryPolicy(maxAttempts: 4, baseDelay: 0.4, maxDelay: 6.0)
}
