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
}
