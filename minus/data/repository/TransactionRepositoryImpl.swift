//
//  TransactionRepositoryImpl.swift
//  minus
//
//  Created by Isaac Emmanuel Serrano Altamirano on 09/05/26.
//

import Foundation
import SwiftData

class TransactionRepositoryImpl: TransactionRepository {
    private let context: ModelContext
   
    // init "constructor" to initialize the injected context instance
    init(context: ModelContext) {
        self.context = context
    }
    
    func save(
        transaction: Transaction
    ) async throws {
        let entity = TransactionEntity(
            id: transaction.id,
            amount: transaction.amount,
            createdAt: transaction.createdAt,
            clientGeneratedId: transaction.clientGeneratedId,
            periodId: transaction.periodId,
            isDeleted: transaction.isDeleted,
            isCredit: transaction.isCredit,
            categoryId: transaction.categoryId
        )
        
        context.insert(entity)
        
        try context.save()
    }
    
    // for each query that needs the exact value we get the first 
    
    func delete(transactionId: UUID) async throws {
        let predicate = #Predicate<TransactionEntity> { $0.id == transactionId }
        let descriptor = FetchDescriptor<TransactionEntity>(predicate: predicate)
        
        if let entity = try context.fetch(descriptor).first {
            entity.isDeleted = true
            try context.save()
        }
    }
    
    func getTransaction(id: UUID) async throws -> Transaction? {
        // WHERE id == id sql condition
        let predicate = #Predicate<TransactionEntity> { $0.id == id}
       
        var descriptor = FetchDescriptor<TransactionEntity>(predicate: predicate)
        descriptor.fetchLimit = 1
        
        if let entity = try context.fetch(descriptor).first {
            return mapToDomain(entity)
        }
        
        return nil
    }
    
    func getAllTransactions() async throws -> [Transaction] {
        let predicate = #Predicate<TransactionEntity> { $0.isDeleted == false }
        
        let descriptor = FetchDescriptor<TransactionEntity>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        
        let entities = try context.fetch(descriptor)
        
        return entities.map { mapToDomain($0) }
    }
    
    func getTransactions(forPeriod periodId: UUID) async throws -> [Transaction] {
        let predicate = #Predicate<TransactionEntity> {
            $0.periodId == periodId && $0.isDeleted == false
        }
        
        let descriptor = FetchDescriptor<TransactionEntity>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        
        let entities = try context.fetch(descriptor)
        return entities.map { mapToDomain($0) }
    }
    
    func getTransactions(forCategory categoryId: UUID) async throws -> [Transaction] {
        let predicate = #Predicate<TransactionEntity> {
            $0.categoryId == categoryId && $0.isDeleted == false
        }
        
        let descriptor = FetchDescriptor<TransactionEntity>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        
        let entities = try context.fetch(descriptor)
        return entities.map { mapToDomain($0) }
    }
    
    func getTransactions(between startDate: Date, and endDate: Date) async throws -> [Transaction] {
        let predicate = #Predicate<TransactionEntity> {
            $0.createdAt >= startDate && $0.createdAt <= endDate && $0.isDeleted == false
        }
        
        let descriptor = FetchDescriptor<TransactionEntity>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        
        let entities = try context.fetch(descriptor)
        return entities.map { mapToDomain($0) }
    }
    
    private func mapToDomain(_ entity: TransactionEntity) -> Transaction {
        return Transaction(
            id: entity.id,
            amount: entity.amount,
            createdAt: entity.createdAt,
            clientGeneratedId: entity.clientGeneratedId,
            periodId: entity.periodId,
            categoryId: entity.categoryId
        )
    }
}
