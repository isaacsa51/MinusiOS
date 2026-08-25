//
//  DeleteTransactionUseCaseTests.swift
//  minusTests
//

import Testing
import Foundation
@testable import minus

struct DeleteTransactionUseCaseTests {
    @Test func deletedTransactionsAreExcludedFromGetAll() async throws {
        let txRepo = InMemoryTransactionRepository()
        let transaction = Transaction(
            id: UUID(), amount: 20, createdAt: Date(),
            clientGeneratedId: UUID().uuidString, periodId: UUID(),
            categoryId: UUID(), categoryName: "Snacks"
        )
        try await txRepo.save(transaction: transaction)

        let useCase = DeleteTransactionUseCase(repository: txRepo)
        try await useCase.execute(transactionId: transaction.id)

        let remaining = try await txRepo.getAllTransactions()
        #expect(remaining.isEmpty)
    }

    @Test func deletingAnUnknownIdDoesNotThrow() async throws {
        let txRepo = InMemoryTransactionRepository()
        let useCase = DeleteTransactionUseCase(repository: txRepo)
        try await useCase.execute(transactionId: UUID())
    }
}
