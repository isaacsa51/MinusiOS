//
//  AddNewExpenseUseCaseTests.swift
//  minusTests
//

import Testing
import Foundation
@testable import minus

struct AddNewExpenseUseCaseTests {
    @Test func rejectsNonPositiveAmount() async throws {
        let periodRepo = InMemoryPeriodRepository()
        let txRepo = InMemoryTransactionRepository()
        try await periodRepo.save(period: PeriodKey(
            id: UUID(), startDate: Date(), endDate: nil, mappingNode: .activeBucket,
            totalBudget: 1000, currency: "USD", remainingStrategy: .SPLIT_EQUALLY,
            periodType: .monthly, daysInPeriod: 30
        ))
        let useCase = AddNewExpenseUseCase(repository: txRepo, periodRepo: periodRepo)

        await #expect(throws: TransactionError.invalidAmount) {
            try await useCase.execute(amount: 0, categoryId: UUID(), categoryName: "Test")
        }
    }

    @Test func rejectsWhenNoActivePeriod() async throws {
        let periodRepo = InMemoryPeriodRepository()
        let txRepo = InMemoryTransactionRepository()
        let useCase = AddNewExpenseUseCase(repository: txRepo, periodRepo: periodRepo)

        await #expect(throws: TransactionError.noActivePeriod) {
            try await useCase.execute(amount: 10, categoryId: UUID(), categoryName: "Test")
        }
    }

    @Test func rejectsMonthlyRecurrenceWithoutValidSubscriptionDay() async throws {
        let periodRepo = InMemoryPeriodRepository()
        let txRepo = InMemoryTransactionRepository()
        try await periodRepo.save(period: PeriodKey(
            id: UUID(), startDate: Date(), endDate: nil, mappingNode: .activeBucket,
            totalBudget: 1000, currency: "USD", remainingStrategy: .SPLIT_EQUALLY,
            periodType: .monthly, daysInPeriod: 30
        ))
        let useCase = AddNewExpenseUseCase(repository: txRepo, periodRepo: periodRepo)

        await #expect(throws: TransactionError.invalidSubscriptionDay) {
            try await useCase.execute(
                amount: 10, categoryId: UUID(), categoryName: "Netflix",
                recurrentFrequency: .MONTHLY, subscriptionDay: nil
            )
        }
    }

    @Test func acceptsMonthlyRecurrenceWithValidSubscriptionDay() async throws {
        let periodRepo = InMemoryPeriodRepository()
        let txRepo = InMemoryTransactionRepository()
        try await periodRepo.save(period: PeriodKey(
            id: UUID(), startDate: Date(), endDate: nil, mappingNode: .activeBucket,
            totalBudget: 1000, currency: "USD", remainingStrategy: .SPLIT_EQUALLY,
            periodType: .monthly, daysInPeriod: 30
        ))
        let useCase = AddNewExpenseUseCase(repository: txRepo, periodRepo: periodRepo)

        try await useCase.execute(
            amount: 15, categoryId: UUID(), categoryName: "Netflix",
            recurrentFrequency: .MONTHLY, subscriptionDay: 15
        )

        let saved = try await txRepo.getAllTransactions()
        #expect(saved.first?.subscriptionDay == 15)
        #expect(saved.first?.isRecurrent == true)
    }

    @Test func savesTransactionAgainstActivePeriod() async throws {
        let periodRepo = InMemoryPeriodRepository()
        let txRepo = InMemoryTransactionRepository()
        let period = PeriodKey(
            id: UUID(), startDate: Date(), endDate: nil, mappingNode: .activeBucket,
            totalBudget: 1000, currency: "USD", remainingStrategy: .SPLIT_EQUALLY,
            periodType: .monthly, daysInPeriod: 30
        )
        try await periodRepo.save(period: period)
        let useCase = AddNewExpenseUseCase(repository: txRepo, periodRepo: periodRepo)

        try await useCase.execute(amount: 42, categoryId: UUID(), categoryName: "Coffee", isCreditCardCharge: true)

        let saved = try await txRepo.getAllTransactions()
        #expect(saved.count == 1)
        #expect(saved.first?.amount == 42)
        #expect(saved.first?.periodId == period.id)
        #expect(saved.first?.isCreditCardCharge == true)
        #expect(saved.first?.isIncome == false)
    }
}
