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
        guard let currentPeriod = try await repository.getActivePeriod() else {
            throw TransactionError.transactionNotFound
        }

        try await repository.closePeriod(id: currentPeriod.id, finalEndDate: Date())
    }
}
