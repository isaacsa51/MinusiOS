//
//  GetPeriodAnalyticsUseCaseTests.swift
//  minusTests
//

import Testing
import Foundation
@testable import minus

struct GetPeriodAnalyticsUseCaseTests {
    @Test func emptyPeriodReturnsEmptyAnalytics() async throws {
        let txRepo = InMemoryTransactionRepository()
        let useCase = GetPeriodAnalyticsUseCase(transactionRepository: txRepo)
        let analytics = try await useCase.execute(periodId: UUID())
        #expect(analytics.transactionCount == 0)
        #expect(analytics.totalSpent == 0)
    }

    @Test func excludesIncomeTransactionsFromSpendTotals() async throws {
        let txRepo = InMemoryTransactionRepository()
        let periodId = UUID()
        try await txRepo.save(transaction: Transaction(
            id: UUID(), amount: 100, createdAt: Date(), clientGeneratedId: UUID().uuidString,
            periodId: periodId, categoryId: UUID(), categoryName: "Groceries"
        ))
        try await txRepo.save(transaction: Transaction(
            id: UUID(), amount: 50, createdAt: Date(), clientGeneratedId: UUID().uuidString,
            periodId: periodId, categoryId: UUID(), categoryName: "Refund", isIncome: true
        ))

        let useCase = GetPeriodAnalyticsUseCase(transactionRepository: txRepo)
        let analytics = try await useCase.execute(periodId: periodId)

        #expect(analytics.transactionCount == 1)
        #expect(analytics.totalSpent == 100)
    }

    @Test func splitsRecurringFromOneTimeSpend() async throws {
        let txRepo = InMemoryTransactionRepository()
        let periodId = UUID()
        try await txRepo.save(transaction: Transaction(
            id: UUID(), amount: 60, createdAt: Date(), clientGeneratedId: UUID().uuidString,
            periodId: periodId, recurrentFrequency: .MONTHLY, categoryId: UUID(), categoryName: "Netflix"
        ))
        try await txRepo.save(transaction: Transaction(
            id: UUID(), amount: 40, createdAt: Date(), clientGeneratedId: UUID().uuidString,
            periodId: periodId, categoryId: UUID(), categoryName: "Coffee"
        ))

        let useCase = GetPeriodAnalyticsUseCase(transactionRepository: txRepo)
        let analytics = try await useCase.execute(periodId: periodId)

        #expect(analytics.recurringSpent == 60)
        #expect(analytics.oneTimeSpent == 40)
        #expect(analytics.recurringSpent + analytics.oneTimeSpent == analytics.totalSpent)
    }

    @Test func identifiesMinAndMaxTransactions() async throws {
        let txRepo = InMemoryTransactionRepository()
        let periodId = UUID()
        let small = Transaction(
            id: UUID(), amount: 5, createdAt: Date(), clientGeneratedId: UUID().uuidString,
            periodId: periodId, categoryId: UUID(), categoryName: "Snack"
        )
        let big = Transaction(
            id: UUID(), amount: 500, createdAt: Date(), clientGeneratedId: UUID().uuidString,
            periodId: periodId, categoryId: UUID(), categoryName: "Rent"
        )
        try await txRepo.save(transaction: small)
        try await txRepo.save(transaction: big)

        let useCase = GetPeriodAnalyticsUseCase(transactionRepository: txRepo)
        let analytics = try await useCase.execute(periodId: periodId)

        #expect(analytics.minTransaction?.id == small.id)
        #expect(analytics.maxTransaction?.id == big.id)
    }

    @Test func groupsCategoryBreakdownByTrimmedNameNotId() async throws {
        let txRepo = InMemoryTransactionRepository()
        let periodId = UUID()
        // Two "Coffee" transactions with different throwaway categoryIds should
        // still fold into a single breakdown row, since grouping is by name.
        try await txRepo.save(transaction: Transaction(
            id: UUID(), amount: 30, createdAt: Date(), clientGeneratedId: UUID().uuidString,
            periodId: periodId, categoryId: UUID(), categoryName: "Coffee"
        ))
        try await txRepo.save(transaction: Transaction(
            id: UUID(), amount: 20, createdAt: Date(), clientGeneratedId: UUID().uuidString,
            periodId: periodId, categoryId: UUID(), categoryName: "  Coffee  "
        ))
        try await txRepo.save(transaction: Transaction(
            id: UUID(), amount: 10, createdAt: Date(), clientGeneratedId: UUID().uuidString,
            periodId: periodId, categoryId: UUID(), categoryName: nil
        ))

        let useCase = GetPeriodAnalyticsUseCase(transactionRepository: txRepo)
        let analytics = try await useCase.execute(periodId: periodId)

        let coffee = analytics.categoryBreakdown.first { $0.name == "Coffee" }
        #expect(coffee?.amount == 50)

        let uncategorized = analytics.categoryBreakdown.first { $0.name != "Coffee" }
        #expect(uncategorized?.amount == 10)
    }

    @Test func foldsOverflowCategoriesIntoOther() async throws {
        let txRepo = InMemoryTransactionRepository()
        let periodId = UUID()
        for index in 0..<9 {
            try await txRepo.save(transaction: Transaction(
                id: UUID(), amount: Decimal(index + 1) * 10, createdAt: Date(),
                clientGeneratedId: UUID().uuidString, periodId: periodId,
                categoryId: UUID(), categoryName: "Category \(index)"
            ))
        }

        let useCase = GetPeriodAnalyticsUseCase(transactionRepository: txRepo)
        let analytics = try await useCase.execute(periodId: periodId)

        #expect(analytics.categoryBreakdown.count == 8)
        #expect(analytics.categoryBreakdown.last?.name == "Other")
    }
}
