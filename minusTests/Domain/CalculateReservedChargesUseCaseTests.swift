//
//  CalculateReservedChargesUseCaseTests.swift
//  minusTests
//

import Testing
import Foundation
@testable import minus

struct CalculateReservedChargesUseCaseTests {
    private let calendar = Calendar.current

    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day))!
    }

    /// October 2026, so every case below shares one window.
    private func makePeriod(id: UUID = UUID(), endDate: Date? = nil) -> PeriodKey {
        PeriodKey(
            id: id,
            startDate: date(2026, 10, 1),
            endDate: endDate ?? date(2026, 10, 31),
            mappingNode: .activeBucket,
            totalBudget: 15000,
            currency: "MXN",
            remainingStrategy: .SPLIT_EQUALLY,
            periodType: .monthly,
            daysInPeriod: 31
        )
    }

    private func makeTransaction(
        amount: Decimal,
        createdAt: Date,
        periodId: UUID,
        categoryName: String? = nil,
        frequency: RecurrentFrequency? = nil,
        recurrentEndDate: Date? = nil,
        subscriptionDay: Int? = nil,
        isIncome: Bool = false,
        isDeleted: Bool = false
    ) -> Transaction {
        Transaction(
            id: UUID(),
            amount: amount,
            createdAt: createdAt,
            clientGeneratedId: UUID().uuidString,
            periodId: periodId,
            isDeleted: isDeleted,
            recurrentFrequency: frequency,
            recurrentEndDate: recurrentEndDate,
            subscriptionDay: subscriptionDay,
            categoryId: UUID(),
            categoryName: categoryName,
            isIncome: isIncome
        )
    }

    private func makeUseCase(
        _ transactions: [Transaction]
    ) async throws -> CalculateReservedChargesUseCase {
        let repository = InMemoryTransactionRepository()
        for transaction in transactions {
            try await repository.save(transaction: transaction)
        }
        return CalculateReservedChargesUseCase(transactionRepository: repository)
    }

    // MARK: -

    @Test func reservesARecurringChargeDueLaterInThePeriod() async throws {
        let period = makePeriod()
        let useCase = try await makeUseCase([
            makeTransaction(
                amount: 400, createdAt: date(2026, 8, 20), periodId: period.id,
                categoryName: "gym", frequency: .MONTHLY, subscriptionDay: 20
            )
        ])

        let breakdown = try await useCase.execute(period: period, referenceDate: date(2026, 10, 9))

        #expect(breakdown.total == 400)
        #expect(breakdown.charges.count == 1)
        #expect(breakdown.charges.first?.name == "gym")
        #expect(breakdown.charges.first?.occurrences == [date(2026, 10, 20)])
    }

    @Test func excludesAChargeDueToday() async throws {
        let period = makePeriod()
        let useCase = try await makeUseCase([
            makeTransaction(
                amount: 15, createdAt: date(2026, 8, 9), periodId: period.id,
                categoryName: "netflix", frequency: .MONTHLY, subscriptionDay: 9
            )
        ])

        let breakdown = try await useCase.execute(period: period, referenceDate: date(2026, 10, 9))

        #expect(breakdown.charges.isEmpty)
        #expect(breakdown.total == 0)
    }

    @Test func includesTemplatesCreatedInAnEarlierPeriod() async throws {
        let period = makePeriod()
        let useCase = try await makeUseCase([
            makeTransaction(
                amount: 400, createdAt: date(2026, 8, 20), periodId: UUID(),
                categoryName: "gym", frequency: .MONTHLY, subscriptionDay: 20
            )
        ])

        let breakdown = try await useCase.execute(period: period, referenceDate: date(2026, 10, 9))

        #expect(breakdown.total == 400)
    }

    @Test func sumsEveryOccurrenceOfTheSameTemplate() async throws {
        let period = makePeriod()
        let useCase = try await makeUseCase([
            makeTransaction(
                amount: 50, createdAt: date(2026, 10, 2), periodId: period.id,
                categoryName: "coffee", frequency: .WEEKLY
            )
        ])

        let breakdown = try await useCase.execute(period: period, referenceDate: date(2026, 10, 9))

        // Oct 16, 23 and 30 — Oct 9 is today, so it stays spendable.
        #expect(breakdown.charges.first?.occurrences.count == 3)
        #expect(breakdown.total == 150)
    }

    @Test func ignoresIncomeDeletedAndOneOffTransactions() async throws {
        let period = makePeriod()
        let useCase = try await makeUseCase([
            makeTransaction(
                amount: 900, createdAt: date(2026, 8, 20), periodId: period.id,
                categoryName: "salary", frequency: .MONTHLY, subscriptionDay: 20, isIncome: true
            ),
            makeTransaction(
                amount: 300, createdAt: date(2026, 8, 20), periodId: period.id,
                categoryName: "cancelled gym", frequency: .MONTHLY, subscriptionDay: 20, isDeleted: true
            ),
            makeTransaction(
                amount: 120, createdAt: date(2026, 10, 3), periodId: period.id,
                categoryName: "groceries"
            )
        ])

        let breakdown = try await useCase.execute(period: period, referenceDate: date(2026, 10, 9))

        #expect(breakdown.charges.isEmpty)
        #expect(breakdown.total == 0)
    }

    @Test func stopsAtThePeriodEnd() async throws {
        let period = makePeriod(endDate: date(2026, 10, 15))
        let useCase = try await makeUseCase([
            makeTransaction(
                amount: 400, createdAt: date(2026, 8, 20), periodId: period.id,
                categoryName: "gym", frequency: .MONTHLY, subscriptionDay: 20
            )
        ])

        let breakdown = try await useCase.execute(period: period, referenceDate: date(2026, 10, 9))

        #expect(breakdown.charges.isEmpty)
    }

    @Test func respectsTheRecurrenceEndDate() async throws {
        let period = makePeriod()
        let useCase = try await makeUseCase([
            makeTransaction(
                amount: 10, createdAt: date(2026, 10, 1), periodId: period.id,
                categoryName: "trial", frequency: .DAILY, recurrentEndDate: date(2026, 10, 12)
            )
        ])

        let breakdown = try await useCase.execute(period: period, referenceDate: date(2026, 10, 9))

        // Oct 10, 11 and 12 only.
        #expect(breakdown.total == 30)
    }

    @Test func isEmptyOnThePeriodsLastDay() async throws {
        let period = makePeriod()
        let useCase = try await makeUseCase([
            makeTransaction(
                amount: 400, createdAt: date(2026, 8, 20), periodId: period.id,
                categoryName: "gym", frequency: .MONTHLY, subscriptionDay: 20
            )
        ])

        let breakdown = try await useCase.execute(period: period, referenceDate: date(2026, 10, 31))

        #expect(breakdown.charges.isEmpty)
    }

    @Test func ordersChargesByTheirFirstDueDate() async throws {
        let period = makePeriod()
        let useCase = try await makeUseCase([
            makeTransaction(
                amount: 400, createdAt: date(2026, 8, 25), periodId: period.id,
                categoryName: "gym", frequency: .MONTHLY, subscriptionDay: 25
            ),
            makeTransaction(
                amount: 15, createdAt: date(2026, 8, 12), periodId: period.id,
                categoryName: "netflix", frequency: .MONTHLY, subscriptionDay: 12
            )
        ])

        let breakdown = try await useCase.execute(period: period, referenceDate: date(2026, 10, 9))

        #expect(breakdown.charges.map(\.name) == ["netflix", "gym"])
        #expect(breakdown.total == 415)
    }

    @Test func fallsBackToAPlaceholderNameForUncategorizedCharges() async throws {
        let period = makePeriod()
        let useCase = try await makeUseCase([
            makeTransaction(
                amount: 80, createdAt: date(2026, 8, 20), periodId: period.id,
                categoryName: "   ", frequency: .MONTHLY, subscriptionDay: 20
            )
        ])

        let breakdown = try await useCase.execute(period: period, referenceDate: date(2026, 10, 9))

        #expect(breakdown.charges.first?.name.isEmpty == false)
        #expect(breakdown.charges.first?.name != "   ")
    }
}
