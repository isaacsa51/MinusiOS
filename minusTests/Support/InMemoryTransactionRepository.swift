//
//  InMemoryTransactionRepository.swift
//  minusTests
//

import Foundation
@testable import minus

final class InMemoryTransactionRepository: TransactionRepository {
    private var storage: [UUID: Transaction] = [:]

    func save(transaction: Transaction) async throws {
        storage[transaction.id] = transaction
    }

    func delete(transactionId: UUID) async throws {
        storage[transactionId]?.isDeleted = true
    }

    func getTransaction(id: UUID) async throws -> Transaction? {
        storage[id]
    }

    func getTransaction(byClientGeneratedId clientGeneratedId: String) async throws -> Transaction? {
        storage.values.first { $0.clientGeneratedId == clientGeneratedId }
    }

    func getAllTransactions() async throws -> [Transaction] {
        storage.values
            .filter { !$0.isDeleted }
            .sorted { $0.createdAt > $1.createdAt }
    }

    func getTransactions(forPeriod periodId: UUID) async throws -> [Transaction] {
        storage.values
            .filter { $0.periodId == periodId && !$0.isDeleted }
            .sorted { $0.createdAt > $1.createdAt }
    }

    func getTransactions(forCategory categoryId: UUID) async throws -> [Transaction] {
        storage.values
            .filter { $0.categoryId == categoryId && !$0.isDeleted }
            .sorted { $0.createdAt > $1.createdAt }
    }

    func getTransactions(between startDate: Date, and endDate: Date) async throws -> [Transaction] {
        storage.values
            .filter { $0.createdAt >= startDate && $0.createdAt <= endDate && !$0.isDeleted }
            .sorted { $0.createdAt > $1.createdAt }
    }
}
