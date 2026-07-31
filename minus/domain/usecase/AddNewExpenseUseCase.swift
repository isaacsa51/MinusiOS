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
    
    func execute(
        amount: Decimal,
        categoryId: UUID,
        categoryName: String?,
        isCredit: Bool = false,
        recurrentFrequency: RecurrentFrequency? = nil,
        recurrentEndDate: Date? = nil,
        subscriptionDay: Int? = nil
    ) async throws {
        guard amount > 0 else {
            throw TransactionError.invalidAmount
        }
        
        guard let activePeriod = try await periodRepository.getActivePeriod() else {
            throw TransactionError.noActivePeriod
        }

        if recurrentFrequency == .MONTHLY {
            guard let day = subscriptionDay, (1...31).contains(day) else {
                throw TransactionError.invalidSubscriptionDay
            }
        }
    
        let transaction = Transaction(
            id: UUID(),
            amount: amount,
            createdAt: Date(),
            clientGeneratedId: UUID().uuidString,
            periodId: activePeriod.id,
            isDeleted: false,
            recurrentFrequency: recurrentFrequency,
            recurrentEndDate: recurrentEndDate,
            subscriptionDay: subscriptionDay,
            categoryId: categoryId,
            categoryName: categoryName,
            isCredit: isCredit,
        )
        
        try await repository.save(transaction: transaction)

        if let frequency = recurrentFrequency {
            RecurringNotificationService.schedule(
                transactionId: transaction.id,
                amount: amount,
                categoryName: categoryName,
                frequency: frequency,
                startDate: transaction.createdAt,
                endDate: recurrentEndDate,
                subscriptionDay: subscriptionDay
            )
        }
    }
}
