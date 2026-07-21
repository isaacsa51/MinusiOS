//
//  FinishPeriodEarlyUseCase.swift
//  minus
//
//  Created by Isaac Emmanuel Serrano Altamirano on 09/05/26.
//

import Foundation

class FinishPeriodEarlyUseCase {
    private let repository: PeriodRepository
    
    init(repository: PeriodRepository) {
        self.repository = repository
    }
    
    func execute() async throws {
       let now = Date()
        
        guard let currentPeriod = try await repository.getActivePeriod() else {
            throw TransactionError.transactionNotFound
        }
        
        try await repository.closePeriod(id: currentPeriod.id, finalEndDate: now)
        
        let newPeriod = PeriodKey(
            id: UUID(),
            startDate: now,
            endDate: nil,
            mappingNode: currentPeriod.mappingNode,
            totalBudget: currentPeriod.totalBudget,
            currency: currentPeriod.currency,
            remainingStrategy: currentPeriod.remainingStrategy,
            periodType: currentPeriod.periodType,
            daysInPeriod: currentPeriod.daysInPeriod
        )
        
        try await repository.save(period: newPeriod)
    }
}
