//
//  AddNewExpenseUseCase.swift
//  minus
//
//  Created by Isaac Emmanuel Serrano Altamirano on 08/05/26.
//

import Foundation

class AddNewExpenseUseCase {
    private let repository: TransactionRepository
    private let periodRepository: PeriodRepository
    
    // init the "constructor" of the repo, while inyecting on the variable repository itself
    init(repository: TransactionRepository, periodRepo: PeriodRepository) {
        self.repository = repository
        self.periodRepository = periodRepo
    }
    
    func execute(amount: Double, categoryId: UUID, categoryName: String?) async throws {
        
        // first we check if the users isn't saving an empty transactions
        // then we guard that the user has a current active budget period
        guard amount > 0 else {
            throw TransactionError.invalidAmount
        }
        
        guard let activePeriod = try await periodRepository.getActivePeriod() else {
            throw TransactionError.noActivePeriod
        }
    
        let transaction = Transaction(
            id: UUID(),
            amount: amount,
            createdAt: Date(),
            clientGeneratedId: UUID().uuidString,
            periodId: activePeriod.id,
            isDeleted: false,
            recurrentFrequency: nil,
            recurrentEndDate: nil,
            subscriptionDay: nil,
            categoryId: categoryId,
            categoryName: categoryName,
            isCredit: false,
        )
        
        try await repository.save(transaction: transaction)
    }
}
