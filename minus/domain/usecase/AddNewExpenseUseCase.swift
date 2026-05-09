//
//  AddNewExpenseUseCase.swift
//  minus
//
//  Created by Isaac Emmanuel Serrano Altamirano on 08/05/26.
//

import Foundation

enum TransactionError: Error {
    case invalidAmount
}

class AddNewExpenseUseCase {
    private let repository: TransactionRepository
    
    // init the "constructor" of the repo, while inyecting on the variable repository itself
    init(repository: TransactionRepository) {
        self.repository = repository
    }
    
    func execute(amount: Double, category: String) async throws {
        guard amount > 0 else {
            throw TransactionError.invalidAmount
        }
        
        let transaction = Transaction(
            id: UUID(),
            amount: amount,
            date: Date(),
            
        )
        
        try await repository.save(transaction: transaction)
    }
}
