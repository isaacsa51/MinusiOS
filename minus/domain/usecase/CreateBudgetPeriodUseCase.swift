//
//  CreateBudgetPeriodUseCase.swift
//  minus
//

import Foundation

class CreateBudgetPeriodUseCase {
    private let repository: PeriodRepository
    
    init(repository: PeriodRepository) {
        self.repository = repository
    }
    
    func execute(settings: BudgetSettings) async throws -> PeriodKey {
        // Close any existing active period
        if let current = try await repository.getActivePeriod() {
            try await repository.closePeriod(id: current.id, finalEndDate: Date())
        }
        
        let newPeriod = PeriodKey(
            id: UUID(),
            startDate: settings.startDate,
            endDate: nil,
            mappingNode: .activeBucket,
            totalBudget: settings.totalBudget,
            currency: settings.currency,
            remainingStrategy: settings.remainingBudgetStrategy,
            periodType: settings.period,
            daysInPeriod: settings.getDaysForPeriod()
        )
        
        try await repository.save(period: newPeriod)
        return newPeriod
    }
}
