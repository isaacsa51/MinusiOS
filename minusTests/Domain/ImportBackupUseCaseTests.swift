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
}
