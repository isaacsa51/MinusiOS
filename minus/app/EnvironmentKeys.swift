//
//  EnvironmentKeys.swift
//  minus
//

import SwiftUI

private struct TransactionRepositoryKey: EnvironmentKey {
    static let defaultValue: (any TransactionRepository)? = nil
}

private struct PeriodRepositoryKey: EnvironmentKey {
    static let defaultValue: (any PeriodRepository)? = nil
}

extension EnvironmentValues {
    var transactionRepository: (any TransactionRepository)? {
        get { self[TransactionRepositoryKey.self] }
        set { self[TransactionRepositoryKey.self] = newValue }
    }

    var periodRepository: (any PeriodRepository)? {
        get { self[PeriodRepositoryKey.self] }
        set { self[PeriodRepositoryKey.self] = newValue }
    }
}
