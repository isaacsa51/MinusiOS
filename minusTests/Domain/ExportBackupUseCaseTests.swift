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
            id: UUID(),
            startDate: Calendar.current.date(byAdding: .day, value: -5, to: Date())!,
            endDate: Calendar.current.date(byAdding: .day, value: 10, to: Date())!,
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
        #expect(field("category") == "Netflix")
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

    @Test func headerMatchesTheAndroidColumnContract() async throws {
        // Byte-for-byte the header the Android app writes and reads. Reordering
        // or dropping a column here silently corrupts cross-device imports.
        let expected = "date,amount,category,extra_note,is_recurrent,frequency,end_date,sub_day,"
            + "id,is_credit,is_credit_paid,period_id,created_at,"
            + "budget_total,budget_period,budget_start_date,budget_end_date,"
            + "currency_code,days_in_period,rollover_enabled,rollover_carry_forward,"
            + "remaining_budget_strategy,current_period_started_at_millis,current_period_id,"
            + "credit_card_cutoff_day,split_mode"

        let useCase = ExportBackupUseCase(
            periodRepository: InMemoryPeriodRepository(),
            transactionRepository: InMemoryTransactionRepository()
        )
        let csv = try await useCase.execute()

        #expect(csv.components(separatedBy: "\r\n")[0] == expected)
        #expect(expected.components(separatedBy: ",").count == 26)
    }

    @Test func everyRowHasTheFullColumnCount() async throws {
        let periodRepo = InMemoryPeriodRepository()
        let txRepo = InMemoryTransactionRepository()

        let active = PeriodKey(
            id: UUID(), startDate: Date(),
            endDate: Calendar.current.date(byAdding: .day, value: 10, to: Date())!,
            mappingNode: .activeBucket, totalBudget: 8027, currency: "MXN",
            remainingStrategy: .SPLIT_EQUALLY, periodType: .biweekly, daysInPeriod: 15
        )
        let past = PeriodKey(
            id: UUID(),
            startDate: Calendar.current.date(byAdding: .day, value: -30, to: Date())!,
            endDate: Calendar.current.date(byAdding: .day, value: -16, to: Date())!,
            mappingNode: .activeBucket, totalBudget: 11250, currency: "MXN",
            remainingStrategy: .SPLIT_EQUALLY, periodType: .biweekly, daysInPeriod: 15
        )
        try await periodRepo.save(period: active)
        try await periodRepo.save(period: past)
        try await txRepo.save(transaction: Transaction(
            id: UUID(), amount: 100, createdAt: Date(), clientGeneratedId: "a",
            periodId: active.id, categoryId: UUID(), categoryName: "comida"
        ))

        let useCase = ExportBackupUseCase(periodRepository: periodRepo, transactionRepository: txRepo)
        let lines = try await useCase.execute().components(separatedBy: "\r\n")

        #expect(lines.count == 4) // header + __META__ + __ARCHIVED__ + one transaction
        for line in lines {
            #expect(line.components(separatedBy: ",").count == 26)
        }
    }

    @Test func pastPeriodsAreWrittenAsArchivedRows() async throws {
        let periodRepo = InMemoryPeriodRepository()
        let txRepo = InMemoryTransactionRepository()

        let active = PeriodKey(
            id: UUID(), startDate: Date(),
            endDate: Calendar.current.date(byAdding: .day, value: 10, to: Date())!,
            mappingNode: .activeBucket, totalBudget: 8027, currency: "MXN",
            remainingStrategy: .SPLIT_EQUALLY, periodType: .biweekly, daysInPeriod: 15
        )
        let past = PeriodKey(
            id: UUID(),
            startDate: Calendar.current.date(byAdding: .day, value: -30, to: Date())!,
            endDate: Calendar.current.date(byAdding: .day, value: -16, to: Date())!,
            mappingNode: .activeBucket, totalBudget: 11250, currency: "MXN",
            remainingStrategy: .SPLIT_EQUALLY, periodType: .biweekly, daysInPeriod: 15,
            externalId: "1789492997582"
        )
        try await periodRepo.save(period: active)
        try await periodRepo.save(period: past)

        // 300 spent, 50 of it income, so the archived total is the net 250.
        try await txRepo.save(transaction: Transaction(
            id: UUID(), amount: 300, createdAt: past.startDate, clientGeneratedId: "p1",
            periodId: past.id, categoryId: UUID(), categoryName: "comida"
        ))
        try await txRepo.save(transaction: Transaction(
            id: UUID(), amount: 50, createdAt: past.startDate, clientGeneratedId: "p2",
            periodId: past.id, categoryId: UUID(), categoryName: "refund", isIncome: true
        ))

        let useCase = ExportBackupUseCase(periodRepository: periodRepo, transactionRepository: txRepo)
        let lines = try await useCase.execute().components(separatedBy: "\r\n")
        let header = lines[0].components(separatedBy: ",")
        let archived = lines.first { $0.hasPrefix("__ARCHIVED__") }!.components(separatedBy: ",")
        let field: (String) -> String = { name in
            guard let index = header.firstIndex(of: name) else { return "" }
            return archived[index]
        }

        #expect(field("amount") == "250.00")
        #expect(field("period_id") == "1789492997582")
        #expect(field("budget_total") == "11250.00")
        #expect(field("budget_period") == "BIWEEKLY")
        #expect(field("currency_code") == "MXN")
        // The active period is described by __META__, never duplicated here.
        #expect(lines.filter { $0.hasPrefix("__ARCHIVED__") }.count == 1)
    }

    @Test func transactionRowCarriesTheExtraNote() async throws {
        let txRepo = InMemoryTransactionRepository()
        try await txRepo.save(transaction: Transaction(
            id: UUID(), amount: 80, createdAt: Date(), clientGeneratedId: "note-1",
            periodId: UUID(), categoryId: UUID(), categoryName: "comida",
            extraNote: "split with Sam"
        ))

        let useCase = ExportBackupUseCase(
            periodRepository: InMemoryPeriodRepository(), transactionRepository: txRepo
        )
        let lines = try await useCase.execute().components(separatedBy: "\r\n")
        let header = lines[0].components(separatedBy: ",")
        let row = lines[1].components(separatedBy: ",")

        #expect(row[header.firstIndex(of: "extra_note")!] == "split with Sam")
        #expect(row[header.firstIndex(of: "category")!] == "comida")
    }
}
