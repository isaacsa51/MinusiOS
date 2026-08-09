//
//  GetPeriodUseCase.swift
//  minus
//

import Foundation

class GetPeriodUseCase {
    private let repository: PeriodRepository

    init(repository: PeriodRepository) {
        self.repository = repository
    }

    func execute(id: UUID) async throws -> PeriodKey? {
        try await repository.getPeriod(id: id)
    }
}
