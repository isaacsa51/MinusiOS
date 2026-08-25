//
//  CreateBudgetPeriodUseCaseTests.swift
//  minusTests
//

import Testing
import Foundation
@testable import minus

struct CreateBudgetPeriodUseCaseTests {
    @Test func firstPeriodHasNoCarryOver() async throws {
        let periodRepo = InMemoryPeriodRepository()
        let txRepo = InMemoryTransactionRepository()
        let useCase = CreateBudgetPeriodUseCase(repository: periodRepo, transactionRepository: txRepo)

        let settings = BudgetSettings(totalBudget: 1000, period: .monthly, startDate: Date(), daysInPeriod: 30)
        let period = try await useCase.execute(settings: settings)

        #expect(period.totalBudget == 1000)
        #expect(period.carryOverAmount == 0)
    }

    @Test func splitEquallyFoldsRemainingBudgetIntoTotalWithoutBonus() async throws {
        let periodRepo = InMemoryPeriodRepository()
        let txRepo = InMemoryTransactionRepository()

        let previousStart = Date(timeIntervalSince1970: 0)
        let previous = PeriodKey(
            id: UUID(), startDate: previousStart, endDate: nil, mappingNode: .activeBucket,
            totalBudget: 1000, currency: "USD", remainingStrategy: .SPLIT_EQUALLY,
            periodType: .monthly, daysInPeriod: 30
        )
        try await periodRepo.save(period: previous)
        try await txRepo.save(transaction: Transaction(
            id: UUID(), amount: 400, createdAt: previousStart,
            clientGeneratedId: UUID().uuidString, periodId: previous.id,
            categoryId: UUID(), categoryName: "Groceries"
        ))

        let useCase = CreateBudgetPeriodUseCase(repository: periodRepo, transactionRepository: txRepo)
        let settings = BudgetSettings(totalBudget: 500, period: .monthly, startDate: Date(), daysInPeriod: 30)
        let newPeriod = try await useCase.execute(settings: settings)

        #expect(newPeriod.totalBudget == 1100)
        #expect(newPeriod.carryOverAmount == 0)
    }

    @Test func addToFirstDayKeepsCarryOverAsSeparateBonus() async throws {
        let periodRepo = InMemoryPeriodRepository()
        let txRepo = InMemoryTransactionRepository()

        let previousStart = Date(timeIntervalSince1970: 0)
        let previous = PeriodKey(
            id: UUID(), startDate: previousStart, endDate: nil, mappingNode: .activeBucket,
            totalBudget: 1000, currency: "USD", remainingStrategy: .ADD_TO_FIRST_DAY,
            periodType: .monthly, daysInPeriod: 30
        )
        try await periodRepo.save(period: previous)
        try await txRepo.save(transaction: Transaction(
            id: UUID(), amount: 700, createdAt: previousStart,
            clientGeneratedId: UUID().uuidString, periodId: previous.id,
            categoryId: UUID(), categoryName: "Rent"
        ))

        let useCase = CreateBudgetPeriodUseCase(repository: periodRepo, transactionRepository: txRepo)
        let settings = BudgetSettings(totalBudget: 500, period: .monthly, startDate: Date(), daysInPeriod: 30)
        let newPeriod = try await useCase.execute(settings: settings)

        #expect(newPeriod.totalBudget == 800)
        #expect(newPeriod.carryOverAmount == 300)
    }

    @Test func askAlwaysDiscardsCarryOverWhenDeclined() async throws {
        let periodRepo = InMemoryPeriodRepository()
        let txRepo = InMemoryTransactionRepository()

        let previousStart = Date(timeIntervalSince1970: 0)
        let previous = PeriodKey(
            id: UUID(), startDate: previousStart, endDate: nil, mappingNode: .activeBucket,
            totalBudget: 1000, currency: "USD", remainingStrategy: .ASK_ALWAYS,
            periodType: .monthly, daysInPeriod: 30
        )
        try await periodRepo.save(period: previous)
        try await txRepo.save(transaction: Transaction(
            id: UUID(), amount: 200, createdAt: previousStart,
            clientGeneratedId: UUID().uuidString, periodId: previous.id,
            categoryId: UUID(), categoryName: "Misc"
        ))

        let useCase = CreateBudgetPeriodUseCase(repository: periodRepo, transactionRepository: txRepo)
        let settings = BudgetSettings(totalBudget: 500, period: .monthly, startDate: Date(), daysInPeriod: 30)
        let newPeriod = try await useCase.execute(settings: settings, carryOverDecision: false)

        #expect(newPeriod.totalBudget == 500)
        #expect(newPeriod.carryOverAmount == 0)
    }

    @Test func askAlwaysKeepsCarryOverWhenAccepted() async throws {
        let periodRepo = InMemoryPeriodRepository()
        let txRepo = InMemoryTransactionRepository()

        let previousStart = Date(timeIntervalSince1970: 0)
        let previous = PeriodKey(
            id: UUID(), startDate: previousStart, endDate: nil, mappingNode: .activeBucket,
            totalBudget: 1000, currency: "USD", remainingStrategy: .ASK_ALWAYS,
            periodType: .monthly, daysInPeriod: 30
        )
        try await periodRepo.save(period: previous)
        try await txRepo.save(transaction: Transaction(
            id: UUID(), amount: 200, createdAt: previousStart,
            clientGeneratedId: UUID().uuidString, periodId: previous.id,
            categoryId: UUID(), categoryName: "Misc"
        ))

        let useCase = CreateBudgetPeriodUseCase(repository: periodRepo, transactionRepository: txRepo)
        let settings = BudgetSettings(totalBudget: 500, period: .monthly, startDate: Date(), daysInPeriod: 30)
        let newPeriod = try await useCase.execute(settings: settings, carryOverDecision: true)

        #expect(newPeriod.totalBudget == 1300)
    }

    @Test func previewCarryOverReturnsNilWhenPreviousPeriodWasOverspent() async throws {
        let periodRepo = InMemoryPeriodRepository()
        let txRepo = InMemoryTransactionRepository()

        let previous = PeriodKey(
            id: UUID(), startDate: Date(), endDate: nil, mappingNode: .activeBucket,
            totalBudget: 100, currency: "USD", remainingStrategy: .SPLIT_EQUALLY,
            periodType: .monthly, daysInPeriod: 30
        )
        try await periodRepo.save(period: previous)
        try await txRepo.save(transaction: Transaction(
            id: UUID(), amount: 150, createdAt: Date(),
            clientGeneratedId: UUID().uuidString, periodId: previous.id,
            categoryId: UUID(), categoryName: "Overspent"
        ))

        let useCase = CreateBudgetPeriodUseCase(repository: periodRepo, transactionRepository: txRepo)
        let preview = try await useCase.previewCarryOver()
        #expect(preview == nil)
    }

    @Test func incomeTransactionsReduceSpendWhenComputingCarryOver() async throws {
        let periodRepo = InMemoryPeriodRepository()
        let txRepo = InMemoryTransactionRepository()

        let previous = PeriodKey(
            id: UUID(), startDate: Date(), endDate: nil, mappingNode: .activeBucket,
            totalBudget: 500, currency: "USD", remainingStrategy: .SPLIT_EQUALLY,
            periodType: .monthly, daysInPeriod: 30
        )
        try await periodRepo.save(period: previous)
        try await txRepo.save(transaction: Transaction(
            id: UUID(), amount: 300, createdAt: Date(),
            clientGeneratedId: UUID().uuidString, periodId: previous.id,
            categoryId: UUID(), categoryName: "Groceries"
        ))
        try await txRepo.save(transaction: Transaction(
            id: UUID(), amount: 100, createdAt: Date(),
            clientGeneratedId: UUID().uuidString, periodId: previous.id,
            categoryId: UUID(), categoryName: "Refund", isIncome: true
        ))

        let useCase = CreateBudgetPeriodUseCase(repository: periodRepo, transactionRepository: txRepo)
        let preview = try await useCase.previewCarryOver()

        #expect(preview?.amount == 300)
    }
}
