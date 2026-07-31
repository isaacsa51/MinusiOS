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
    
    func execute(transactionId: UUID, newAmount: Decimal? = nil, newCategoryId: UUID? = nil, newCategoryName: String? = nil, newDate: Date? = nil, newIsCredit: Bool? = nil) async throws {
        guard let existingTransaction = try await repository.getTransaction(id: transactionId) else {
            throw TransactionError.transactionNotFound
        }
        
        let updatedTransaction = Transaction(
            id: existingTransaction.id,
            amount: newAmount ?? existingTransaction.amount,
            createdAt: newDate ?? existingTransaction.createdAt,
            clientGeneratedId: existingTransaction.clientGeneratedId,
            periodId: existingTransaction.periodId,
            recurrentFrequency: existingTransaction.recurrentFrequency,
            recurrentEndDate: existingTransaction.recurrentEndDate,
            subscriptionDay: existingTransaction.subscriptionDay,
            categoryId: newCategoryId ?? existingTransaction.categoryId,
            categoryName: newCategoryName ?? existingTransaction.categoryName,
            isCredit: newIsCredit ?? existingTransaction.isCredit
        )
        
        try await repository.save(transaction: updatedTransaction)
    }
}
