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

private struct SplitModePreferenceRepositoryKey: EnvironmentKey {
    static let defaultValue: (any SplitModePreferenceRepository)? = nil
}

private struct CreditCardPreferenceRepositoryKey: EnvironmentKey {
    static let defaultValue: (any CreditCardPreferenceRepository)? = nil
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

    var splitModePreferenceRepository: (any SplitModePreferenceRepository)? {
        get { self[SplitModePreferenceRepositoryKey.self] }
        set { self[SplitModePreferenceRepositoryKey.self] = newValue }
    }

    var creditCardPreferenceRepository: (any CreditCardPreferenceRepository)? {
        get { self[CreditCardPreferenceRepositoryKey.self] }
        set { self[CreditCardPreferenceRepositoryKey.self] = newValue }
    }
}
