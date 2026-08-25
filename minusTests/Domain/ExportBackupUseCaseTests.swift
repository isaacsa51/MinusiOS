//
//  ExportBackupUseCaseTests.swift
//  minusTests
//

import Testing
import Foundation
@testable import minus

struct ExportBackupUseCaseTests {
    @Test func exportOmitsMetaRowWhenThereIsNoActivePeriod() async throws {
        let periodRepo = InMemoryPeriodRepository()
        let txRepo = InMemoryTransactionRepository()
        let useCase = ExportBackupUseCase(periodRepository: periodRepo, transactionRepository: txRepo)

        let csv = try await useCase.execute()
        let lines = csv.components(separatedBy: "\r\n")

        #expect(lines.count == 1)
        #expect(!csv.contains("__META__"))
    }

    @Test func metaRowCarriesActivePeriodBudgetFields() async throws {
        let periodRepo = InMemoryPeriodRepository()
        let txRepo = InMemoryTransactionRepository()

        let period = PeriodKey(
            id: UUID(), startDate: Date(timeIntervalSince1970: 1_700_000_000),
            endDate: Date(timeIntervalSince1970: 1_701_000_000),
            mappingNode: .activeBucket, totalBudget: 5000, currency: "MXN",
            remainingStrategy: .SPLIT_EQUALLY, periodType: .biweekly, daysInPeriod: 15
        )
        try await periodRepo.save(period: period)

        let useCase = ExportBackupUseCase(periodRepository: periodRepo, transactionRepository: txRepo)
        let csv = try await useCase.execute(creditCardCutoffDay: 5)

        let lines = csv.components(separatedBy: "\r\n")
        let header = lines[0].components(separatedBy: ",")
        let metaFields = lines[1].components(separatedBy: ",")
        let field: (String) -> String = { name in
            guard let index = header.firstIndex(of: name) else { return "" }
            return metaFields[index]
        }

        #expect(field("date") == "__META__")
        #expect(field("budget_total") == "5000.00")
        #expect(field("budget_period") == "BIWEEKLY")
        #expect(field("currency_code") == "MXN")
        #expect(field("days_in_period") == "15")
        #expect(field("remaining_budget_strategy") == "SPLIT_EQUALLY")
        #expect(field("credit_card_cutoff_day") == "5")
        #expect(field("split_mode") == "")
    }

    @Test func transactionRowCarriesCreditCardAndRecurrenceFields() async throws {
        let periodRepo = InMemoryPeriodRepository()
        let txRepo = InMemoryTransactionRepository()
        let periodId = UUID()

        try await txRepo.save(transaction: Transaction(
            id: UUID(), amount: 123.45, createdAt: Date(timeIntervalSince1970: 1_700_100_000),
            clientGeneratedId: "csv-id-1", periodId: periodId,
            recurrentFrequency: .MONTHLY, subscriptionDay: 10,
            categoryId: UUID(), categoryName: "Netflix",
            isCreditCardCharge: true, isCreditCardPaid: true
        ))

        let useCase = ExportBackupUseCase(periodRepository: periodRepo, transactionRepository: txRepo)
        let csv = try await useCase.execute()

        let lines = csv.components(separatedBy: "\r\n")
        let header = lines[0].components(separatedBy: ",")
        let row = lines[1].components(separatedBy: ",")
        let field: (String) -> String = { name in
            guard let index = header.firstIndex(of: name) else { return "" }
            return row[index]
        }

        #expect(field("id") == "csv-id-1")
        #expect(field("amount") == "123.45")
        #expect(field("comment") == "Netflix")
        #expect(field("is_recurrent") == "1")
        #expect(field("frequency") == "MONTHLY")
        #expect(field("sub_day") == "10")
        #expect(field("is_credit") == "1")
        #expect(field("is_credit_paid") == "1")
        #expect(field("period_id") == periodId.uuidString)
    }

    @Test func categoryNamesWithCommasAreQuoted() async throws {
        let periodRepo = InMemoryPeriodRepository()
        let txRepo = InMemoryTransactionRepository()
        try await txRepo.save(transaction: Transaction(
            id: UUID(), amount: 10, createdAt: Date(), clientGeneratedId: "csv-id-2",
            periodId: UUID(), categoryId: UUID(), categoryName: "Snacks, drinks"
        ))

        let useCase = ExportBackupUseCase(periodRepository: periodRepo, transactionRepository: txRepo)
        let csv = try await useCase.execute()

        #expect(csv.contains("\"Snacks, drinks\""))
    }

    @Test func exportUsesExternalIdForPeriodsThatWereImported() async throws {
        let periodRepo = InMemoryPeriodRepository()
        let txRepo = InMemoryTransactionRepository()

        let period = PeriodKey(
            id: UUID(), startDate: Date(), endDate: nil, mappingNode: .activeBucket,
            totalBudget: 1000, currency: "USD", remainingStrategy: .SPLIT_EQUALLY,
            periodType: .monthly, daysInPeriod: 30, externalId: "android-123"
        )
        try await periodRepo.save(period: period)
        try await txRepo.save(transaction: Transaction(
            id: UUID(), amount: 10, createdAt: Date(), clientGeneratedId: "csv-id-3",
            periodId: period.id, categoryId: UUID(), categoryName: "Test"
        ))

        let useCase = ExportBackupUseCase(periodRepository: periodRepo, transactionRepository: txRepo)
        let csv = try await useCase.execute()

        #expect(csv.contains("android-123"))
        #expect(!csv.contains(period.id.uuidString))
    }
}
