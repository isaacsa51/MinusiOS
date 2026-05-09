//
//  GetCurrentPeriodIdIUseCase.swift
//  minus
//
//  Created by Isaac Emmanuel Serrano Altamirano on 09/05/26.
//

import Foundation

class GetCurrentPeriodIdIUseCase {
    private let repository: PeriodRepository
    
    init(repository: PeriodRepository) {
        self.repository = repository
    }
    
    func execute() async throws -> PeriodKey? {
        return try await repository.getActivePeriod()
    }
}
