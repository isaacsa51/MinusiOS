    //
    //  EditTransactionUseCase.swift
    //  minus
    //
    //  Created by Isaac Emmanuel Serrano Altamirano on 08/05/26.
    //

import Foundation

class EditTransactionUseCase {
    private let repository: TransactionRepository
    
    init(repository: TransactionRepository) {
        self.repository = repository
    }
    
    func execute(transactionId: UUID, newAmount: Double? = nil, newCategoryId: UUID? = nil) async throws {
        guard let existingTransaction = try await repository.getTransaction(id: transactionId) else {
            throw TransactionError.transactionNotFound
        }
        
        let updatedTransaction = Transaction(
            id: existingTransaction.id,
            amount: newAmount ?? existingTransaction.amount,
            createdAt: existingTransaction.createdAt,
            clientGeneratedId: existingTransaction.clientGeneratedId,
            periodId: existingTransaction.periodId,
            categoryId: existingTransaction.categoryId,
        )
        
    
        try await repository.save(transaction: updatedTransaction)
    }
}
