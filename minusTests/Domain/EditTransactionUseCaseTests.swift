//
//  EditTransactionUseCaseTests.swift
//  minusTests
//

import Testing
import Foundation
@testable import minus

struct EditTransactionUseCaseTests {
    @Test func throwsWhenTransactionDoesNotExist() async throws {
        let txRepo = InMemoryTransactionRepository()
        let useCase = EditTransactionUseCase(repository: txRepo)

        await #expect(throws: TransactionError.transactionNotFound) {
            try await useCase.execute(transactionId: UUID(), newAmount: 10)
        }
    }

    @Test func updatesOnlyProvidedFieldsAndPreservesTheRest() async throws {
        let txRepo = InMemoryTransactionRepository()
        let periodId = UUID()
        let original = Transaction(
            id: UUID(), amount: 100, createdAt: Date(),
            clientGeneratedId: UUID().uuidString, periodId: periodId,
            categoryId: UUID(), categoryName: "Groceries",
            isCreditCardCharge: true
        )
        try await txRepo.save(transaction: original)

        let useCase = EditTransactionUseCase(repository: txRepo)
        try await useCase.execute(transactionId: original.id, newAmount: 250, newCategoryName: "Supermarket")

        let updated = try await txRepo.getTransaction(id: original.id)
        #expect(updated?.amount == 250)
        #expect(updated?.categoryName == "Supermarket")
        #expect(updated?.periodId == periodId) // untouched
        #expect(updated?.isCreditCardCharge == true) // untouched
    }

    @Test func canFlipIsIncomeExplicitly() async throws {
        let txRepo = InMemoryTransactionRepository()
        let original = Transaction(
            id: UUID(), amount: 50, createdAt: Date(),
            clientGeneratedId: UUID().uuidString, periodId: UUID(),
            categoryId: UUID(), categoryName: "Refund"
        )
        try await txRepo.save(transaction: original)

        let useCase = EditTransactionUseCase(repository: txRepo)
        try await useCase.execute(transactionId: original.id, newIsIncome: true)

        let updated = try await txRepo.getTransaction(id: original.id)
        #expect(updated?.isIncome == true)
    }

    @Test func leavesTheNoteAloneWhenNoneIsPassed() async throws {
        let txRepo = InMemoryTransactionRepository()
        let original = Transaction(
            id: UUID(), amount: 80, createdAt: Date(),
            clientGeneratedId: UUID().uuidString, periodId: UUID(),
            categoryId: UUID(), categoryName: "Dinner",
            extraNote: "split with Sam"
        )
        try await txRepo.save(transaction: original)

        let useCase = EditTransactionUseCase(repository: txRepo)
        try await useCase.execute(transactionId: original.id, newAmount: 95)

        let updated = try await txRepo.getTransaction(id: original.id)
        #expect(updated?.extraNote == "split with Sam")
    }

    @Test func clearsTheNoteWhenAnEmptyOneIsPassed() async throws {
        let txRepo = InMemoryTransactionRepository()
        let original = Transaction(
            id: UUID(), amount: 80, createdAt: Date(),
            clientGeneratedId: UUID().uuidString, periodId: UUID(),
            categoryId: UUID(), categoryName: "Dinner",
            extraNote: "split with Sam"
        )
        try await txRepo.save(transaction: original)

        let useCase = EditTransactionUseCase(repository: txRepo)
        // An emptied field reaches the use case as .some(nil).
        try await useCase.execute(transactionId: original.id, newExtraNote: .some(String?.none))

        let updated = try await txRepo.getTransaction(id: original.id)
        #expect(updated?.extraNote == nil)
    }

    @Test func trimsAWhitespaceOnlyNoteToNothing() async throws {
        let txRepo = InMemoryTransactionRepository()
        let original = Transaction(
            id: UUID(), amount: 80, createdAt: Date(),
            clientGeneratedId: UUID().uuidString, periodId: UUID(),
            categoryId: UUID(), categoryName: "Dinner"
        )
        try await txRepo.save(transaction: original)

        let useCase = EditTransactionUseCase(repository: txRepo)
        try await useCase.execute(transactionId: original.id, newExtraNote: .some("   "))
        let afterBlank = try await txRepo.getTransaction(id: original.id)
        #expect(afterBlank?.extraNote == nil)

        try await useCase.execute(transactionId: original.id, newExtraNote: .some("  paid cash  "))
        let afterPadded = try await txRepo.getTransaction(id: original.id)
        #expect(afterPadded?.extraNote == "paid cash")
    }
}
