//
//  ImportBackupUseCaseTests.swift
//  minusTests
//

import Testing
import Foundation
@testable import minus

struct ImportBackupUseCaseTests {
    private static let header = "date,amount,comment,is_recurrent,frequency,end_date,sub_day,id,is_credit,is_credit_paid,period_id,created_at,budget_total,budget_period,budget_start_date,budget_end_date,currency_code,days_in_period,rollover_enabled,rollover_carry_forward,remaining_budget_strategy,current_period_started_at_millis,current_period_id,credit_card_cutoff_day,split_mode"

    @Test func throwsOnEmptyFile() async throws {
        let useCase = ImportBackupUseCase(periodRepository: InMemoryPeriodRepository(), transactionRepository: InMemoryTransactionRepository())
        await #expect(throws: ImportBackupError.emptyFile) {
            try await useCase.execute(csv: "")
        }
    }

    @Test func throwsOnUnrecognizedHeader() async throws {
        let useCase = ImportBackupUseCase(periodRepository: InMemoryPeriodRepository(), transactionRepository: InMemoryTransactionRepository())
        await #expect(throws: ImportBackupError.missingHeader) {
            try await useCase.execute(csv: "not,a,minus,backup\n1,2,3,4")
        }
    }

    @Test func importsRealAndroidShapedBackup() async throws {
        // A condensed version of a real Android export: one __META__ row for the
        // active biweekly period, one transaction in that period, one legacy
        // transaction from before period tracking existed (period_id "0"), and
        // one recurring monthly charge flagged as a credit card charge.
        let csv = """
        \(Self.header)
        __META__,,,,,,,,,,,,11200.00,BIWEEKLY,2026-07-30,2026-08-13,MXN,15,0,0,SPLIT_EQUALLY,1785463401095,1785463401095,3,DYNAMIC
        2026-08-06 20:39,50,antojos,0,,,,98020724,0,0,1785463401095,1786073997765,,,,,,,,,,,,,
        2026-07-28 19:28,4450,cerrajero,0,,,,98020718,0,0,0,1785463330563,,,,,,,,,,,,,
        2026-07-25 22:43,200,plan cel,1,MONTHLY,2026-09-30,22,287,1,0,0,1785463330563,,,,,,,,,,,,,
        """

        let periodRepo = InMemoryPeriodRepository()
        let txRepo = InMemoryTransactionRepository()
        let useCase = ImportBackupUseCase(periodRepository: periodRepo, transactionRepository: txRepo)

        let result = try await useCase.execute(csv: csv)

        #expect(result.importedTransactions == 3)
        #expect(result.updatedTransactions == 0)
        #expect(result.createdPeriods == 2) // the active biweekly period + the "0" legacy bucket
        #expect(result.creditCardCutoffDay == 3)
        #expect(result.splitMode == nil) // "DYNAMIC" has no iOS equivalent — left unset, not guessed

        let allPeriods = try await periodRepo.getAllPeriods()
        #expect(allPeriods.count == 2)

        let activePeriod = try await periodRepo.getPeriod(byExternalId: "1785463401095")
        #expect(activePeriod?.totalBudget == 11200)
        #expect(activePeriod?.periodType == .biweekly)
        #expect(activePeriod?.currency == "MXN")

        let legacyPeriod = try await periodRepo.getPeriod(byExternalId: "0")
        #expect(legacyPeriod != nil)

        let antojos = try await txRepo.getTransaction(byClientGeneratedId: "98020724")
        #expect(antojos?.amount == 50)
        #expect(antojos?.periodId == activePeriod?.id)
        #expect(antojos?.isIncome == false)

        let recurring = try await txRepo.getTransaction(byClientGeneratedId: "287")
        #expect(recurring?.isRecurrent == true)
        #expect(recurring?.recurrentFrequency == .MONTHLY)
        #expect(recurring?.subscriptionDay == 22)
        #expect(recurring?.isCreditCardCharge == true)
        #expect(recurring?.periodId == legacyPeriod?.id)
    }

    @Test func reimportingTheSameFileUpdatesInsteadOfDuplicating() async throws {
        let csv = """
        \(Self.header)
        2026-08-06 20:39,50,antojos,0,,,,98020724,0,0,0,1786073997765,,,,,,,,,,,,,
        """
        let periodRepo = InMemoryPeriodRepository()
        let txRepo = InMemoryTransactionRepository()
        let useCase = ImportBackupUseCase(periodRepository: periodRepo, transactionRepository: txRepo)

        let first = try await useCase.execute(csv: csv)
        #expect(first.importedTransactions == 1)
        #expect(first.updatedTransactions == 0)

        let second = try await useCase.execute(csv: csv)
        #expect(second.importedTransactions == 0)
        #expect(second.updatedTransactions == 1)

        let all = try await txRepo.getAllTransactions()
        #expect(all.count == 1)
    }

    @Test func reimportingWithAChangedAmountUpdatesTheExistingTransaction() async throws {
        let periodRepo = InMemoryPeriodRepository()
        let txRepo = InMemoryTransactionRepository()
        let useCase = ImportBackupUseCase(periodRepository: periodRepo, transactionRepository: txRepo)

        let original = """
        \(Self.header)
        2026-08-06 20:39,50,antojos,0,,,,98020724,0,0,0,1786073997765,,,,,,,,,,,,,
        """
        _ = try await useCase.execute(csv: original)

        let revised = """
        \(Self.header)
        2026-08-06 20:39,75,antojos,0,,,,98020724,0,0,0,1786073997765,,,,,,,,,,,,,
        """
        _ = try await useCase.execute(csv: revised)

        let updated = try await txRepo.getTransaction(byClientGeneratedId: "98020724")
        #expect(updated?.amount == 75)
    }

    @Test func skipsRowsWithUnparsableDateOrAmount() async throws {
        let csv = """
        \(Self.header)
        not-a-date,50,antojos,0,,,,1,0,0,0,0,,,,,,,,,,,,,
        2026-08-06 20:39,not-a-number,antojos,0,,,,2,0,0,0,0,,,,,,,,,,,,,
        2026-08-06 20:39,50,antojos,0,,,,3,0,0,0,0,,,,,,,,,,,,,
        """
        let periodRepo = InMemoryPeriodRepository()
        let txRepo = InMemoryTransactionRepository()
        let useCase = ImportBackupUseCase(periodRepository: periodRepo, transactionRepository: txRepo)

        let result = try await useCase.execute(csv: csv)
        #expect(result.importedTransactions == 1)

        let all = try await txRepo.getAllTransactions()
        #expect(all.count == 1)
        #expect(all.first?.clientGeneratedId == "3")
    }

    @Test func emptyCommentImportsAsNilCategoryName() async throws {
        let csv = """
        \(Self.header)
        2026-05-16 10:13,2460,,0,,,,219,0,0,0,0,,,,,,,,,,,,,
        """
        let periodRepo = InMemoryPeriodRepository()
        let txRepo = InMemoryTransactionRepository()
        let useCase = ImportBackupUseCase(periodRepository: periodRepo, transactionRepository: txRepo)

        _ = try await useCase.execute(csv: csv)
        let imported = try await txRepo.getTransaction(byClientGeneratedId: "219")
        #expect(imported?.categoryName == nil)
    }

    @Test func creditCardFieldsRoundTripThroughImport() async throws {
        let csv = """
        \(Self.header)
        2026-07-01 02:32,9387.27,tdc,0,,,,313,1,1,0,0,,,,,,,,,,,,,
        """
        let periodRepo = InMemoryPeriodRepository()
        let txRepo = InMemoryTransactionRepository()
        let useCase = ImportBackupUseCase(periodRepository: periodRepo, transactionRepository: txRepo)

        _ = try await useCase.execute(csv: csv)
        let imported = try await txRepo.getTransaction(byClientGeneratedId: "313")
        #expect(imported?.isCreditCardCharge == true)
        #expect(imported?.isCreditCardPaid == true)
    }

    // MARK: - Current Android format (26 columns, "category" + "extra_note" + __ARCHIVED__)

    private static let androidHeader = "date,amount,category,extra_note,is_recurrent,frequency,end_date,sub_day,id,is_credit,is_credit_paid,period_id,created_at,budget_total,budget_period,budget_start_date,budget_end_date,currency_code,days_in_period,rollover_enabled,rollover_carry_forward,remaining_budget_strategy,current_period_started_at_millis,current_period_id,credit_card_cutoff_day,split_mode"

    /// Trimmed straight from a real device export: the active period, two
    /// closed periods, and transactions belonging to each.
    private static let androidBackup = """
    \(Self.androidHeader)
    __META__,,,,,,,,,,,,,8027.00,BIWEEKLY,2026-10-01,2026-10-15,MXN,15,0,0,SPLIT_EQUALLY,1790841769120,1790841769120,1,CARRY_OVER
    __ARCHIVED__,5673.94,,,,,,,,,,1789492997582,1790841769097,11250.00,BIWEEKLY,2026-09-15,2026-09-30,MXN,,,,,,,,
    __ARCHIVED__,16453.77,,,,,,,,,,1787995454124,1789492997576,15213.50,BIWEEKLY,2026-08-29,2026-09-14,MXN,,,,,,,,
    2026-10-03 23:00,369,salida,cena con ani,0,,,,98020858,0,0,1790841769120,1791093633122,,,,,,,,,,,,,
    2026-09-28 08:37,269,netflix,,0,,,,98020851,0,0,1789492997582,1790609861825,,,,,,,,,,,,,
    2026-09-14 18:25,200,gasolina,,0,,,,98020825,1,1,1787995454124,1790579210511,,,,,,,,,,,,,
    2026-05-15 01:53,400,gym,,1,MONTHLY,2026-12-30,11,212,0,0,1777618800000,1790579210512,,,,,,,,,,,,,
    """

    @Test func readsCategoryAndExtraNoteFromTheAndroidFormat() async throws {
        let periodRepo = InMemoryPeriodRepository()
        let txRepo = InMemoryTransactionRepository()
        let useCase = ImportBackupUseCase(periodRepository: periodRepo, transactionRepository: txRepo)

        _ = try await useCase.execute(csv: Self.androidBackup)

        let salida = try await txRepo.getTransaction(byClientGeneratedId: "98020858")
        #expect(salida?.categoryName == "salida")
        #expect(salida?.extraNote == "cena con ani")

        // A blank extra_note column is absence, not an empty string.
        let netflix = try await txRepo.getTransaction(byClientGeneratedId: "98020851")
        #expect(netflix?.categoryName == "netflix")
        #expect(netflix?.extraNote == nil)
    }

    @Test func archivedRowsBecomeRealPastPeriods() async throws {
        let periodRepo = InMemoryPeriodRepository()
        let txRepo = InMemoryTransactionRepository()
        let useCase = ImportBackupUseCase(periodRepository: periodRepo, transactionRepository: txRepo)

        let result = try await useCase.execute(csv: Self.androidBackup)

        // Active + two archived + the one period only referenced by the gym row.
        #expect(result.createdPeriods == 4)

        let september = try await periodRepo.getPeriod(byExternalId: "1789492997582")
        #expect(september?.totalBudget == 11250)
        #expect(september?.periodType == .biweekly)
        #expect(september?.currency == "MXN")
        // Sep 15 through Sep 30 inclusive — archived rows carry no days_in_period.
        #expect(september?.daysInPeriod == 16)

        let calendar = Calendar.current
        let start = calendar.dateComponents([.year, .month, .day], from: september!.startDate)
        #expect(start.year == 2026 && start.month == 9 && start.day == 15)

        // Transactions attach to the archived period, not to a placeholder.
        let netflix = try await txRepo.getTransaction(byClientGeneratedId: "98020851")
        #expect(netflix?.periodId == september?.id)

        let august = try await periodRepo.getPeriod(byExternalId: "1787995454124")
        #expect(august?.totalBudget == Decimal(string: "15213.50"))
    }

    @Test func periodsWithoutAnArchivedRowStillGetABucket() async throws {
        let periodRepo = InMemoryPeriodRepository()
        let txRepo = InMemoryTransactionRepository()
        let useCase = ImportBackupUseCase(periodRepository: periodRepo, transactionRepository: txRepo)

        _ = try await useCase.execute(csv: Self.androidBackup)

        // The gym row references a period the file never describes, so it falls
        // back to a placeholder rather than being dropped.
        let orphan = try await periodRepo.getPeriod(byExternalId: "1777618800000")
        #expect(orphan != nil)

        let gym = try await txRepo.getTransaction(byClientGeneratedId: "212")
        #expect(gym?.periodId == orphan?.id)
        #expect(gym?.recurrentFrequency == .MONTHLY)
        #expect(gym?.subscriptionDay == 11)
    }

    @Test func androidSplitModeValueIsIgnoredRatherThanMisread() async throws {
        let useCase = ImportBackupUseCase(
            periodRepository: InMemoryPeriodRepository(),
            transactionRepository: InMemoryTransactionRepository()
        )

        let result = try await useCase.execute(csv: Self.androidBackup)

        // Android writes its daily-budget strategy here ("CARRY_OVER"), which is
        // not one of the iOS pill windows. Better unset than wrong.
        #expect(result.splitMode == nil)
        #expect(result.creditCardCutoffDay == 1)
    }

    @Test func exportedFileCanBeReadBackIn() async throws {
        let sourcePeriods = InMemoryPeriodRepository()
        let sourceTx = InMemoryTransactionRepository()

        let active = PeriodKey(
            id: UUID(), startDate: Calendar.current.date(byAdding: .day, value: -2, to: Date())!,
            endDate: Calendar.current.date(byAdding: .day, value: 12, to: Date())!,
            mappingNode: .activeBucket, totalBudget: 8027, currency: "MXN",
            remainingStrategy: .SPLIT_EQUALLY, periodType: .biweekly, daysInPeriod: 15,
            externalId: "active-1"
        )
        let past = PeriodKey(
            id: UUID(), startDate: Calendar.current.date(byAdding: .day, value: -30, to: Date())!,
            endDate: Calendar.current.date(byAdding: .day, value: -16, to: Date())!,
            mappingNode: .activeBucket, totalBudget: 11250, currency: "MXN",
            remainingStrategy: .SPLIT_EQUALLY, periodType: .biweekly, daysInPeriod: 15,
            externalId: "past-1"
        )
        try await sourcePeriods.save(period: active)
        try await sourcePeriods.save(period: past)
        try await sourceTx.save(transaction: Transaction(
            id: UUID(), amount: 369, createdAt: Date(), clientGeneratedId: "rt-1",
            periodId: active.id, categoryId: UUID(), categoryName: "salida",
            extraNote: "cena con ani"
        ))

        let csv = try await ExportBackupUseCase(
            periodRepository: sourcePeriods, transactionRepository: sourceTx
        ).execute(creditCardCutoffDay: 1)

        let destPeriods = InMemoryPeriodRepository()
        let destTx = InMemoryTransactionRepository()
        let result = try await ImportBackupUseCase(
            periodRepository: destPeriods, transactionRepository: destTx
        ).execute(csv: csv)

        #expect(result.importedTransactions == 1)
        #expect(result.createdPeriods == 2)
        #expect(result.creditCardCutoffDay == 1)

        let restored = try await destTx.getTransaction(byClientGeneratedId: "rt-1")
        #expect(restored?.categoryName == "salida")
        #expect(restored?.extraNote == "cena con ani")

        let restoredPast = try await destPeriods.getPeriod(byExternalId: "past-1")
        #expect(restoredPast?.totalBudget == 11250)
        #expect(restoredPast?.currency == "MXN")
        #expect(restoredPast?.periodType == .biweekly)
    }
}
