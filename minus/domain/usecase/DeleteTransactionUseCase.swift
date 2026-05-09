//
//  DeleteTransactionUseCase.swift
//  minus
//
//  Created by Isaac Emmanuel Serrano Altamirano on 08/05/26.
//

import Foundation

class DeleteTransactionUseCase {
    private let repository: TransactionRepository
    
    init(repository: TransactionRepository) {
        self.repository = repository
    }
    
    func execute(transactionId: UUID) async throws {
        try await repository.getTransaction(id: transactionId)
    }
}
