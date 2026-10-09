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
    
    /// `newExtraNote` is double-optional on purpose: `nil` leaves the existing
    /// note alone, `.some(nil)` clears it. Every other parameter follows the
    /// usual "nil means unchanged" rule.
    func execute(
        transactionId: UUID,
        newAmount: Decimal? = nil,
        newCategoryId: UUID? = nil,
        newCategoryName: String? = nil,
        newDate: Date? = nil,
        newIsIncome: Bool? = nil,
        newExtraNote: String?? = nil
    ) async throws {
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
            isIncome: newIsIncome ?? existingTransaction.isIncome,
            isCreditCardCharge: existingTransaction.isCreditCardCharge,
            isCreditCardPaid: existingTransaction.isCreditCardPaid,
            extraNote: newExtraNote.map(Self.normalized) ?? existingTransaction.extraNote
        )
        
        try await repository.save(transaction: updatedTransaction)
    }

    /// A blank note is no note — keeps whitespace out of the store.
    private static func normalized(_ note: String?) -> String? {
        let trimmed = note?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? nil : trimmed
    }
}
