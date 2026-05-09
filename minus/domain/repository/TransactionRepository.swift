//
//  TransactionRepository.swift
//  minus
//
//  Created by Isaac Emmanuel Serrano Altamirano on 08/05/26.
//

import Foundation

// interfaces on swift are protocols
protocol TransactionRepository {
    // generate crud functions, async defines that the function is "suspended" (unidirectional)
    // throws defines that this function can fail
    func save(transaction: Transaction) async throws
    
    func delete(transactionId: UUID) async throws
   
    func getTransaction(id: UUID) async throws -> Transaction?
    
    func getAllTransactions() async throws -> [Transaction]
    
    func getTransactions(forPeriod periodId: UUID) async throws -> [Transaction]
    
    func getTransactions(forCategory categoryId: UUID) async throws -> [Transaction]
    
    func getTransactions(between startDate: Date, and endDate: Date) async throws -> [Transaction]
}
