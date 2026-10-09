//
//  AppDependencies.swift
//  minus
//

import Foundation
import SwiftData

struct AppDependencies {
    let transactionRepository: any TransactionRepository
    let periodRepository: any PeriodRepository
    let splitModePreferenceRepository: any SplitModePreferenceRepository
    let creditCardPreferenceRepository: any CreditCardPreferenceRepository
    let reservedChargesPreferenceRepository: any ReservedChargesPreferenceRepository
}

extension AppDependencies {
    static func preview(
        transactionRepository: (any TransactionRepository)? = nil,
        periodRepository: (any PeriodRepository)? = nil
    ) -> AppDependencies {
        let container = ModelContainerProvider.makeInMemoryContainer()
        return AppDependencies(
            transactionRepository: transactionRepository ?? TransactionRepositoryImpl(context: container.mainContext),
            periodRepository: periodRepository ?? PeriodReportRepositoryImpl(context: container.mainContext),
            splitModePreferenceRepository: UserDefaultsSplitModePreferenceRepository(),
            creditCardPreferenceRepository: UserDefaultsCreditCardPreferenceRepository(),
            reservedChargesPreferenceRepository: UserDefaultsReservedChargesPreferenceRepository()
        )
    }
}
