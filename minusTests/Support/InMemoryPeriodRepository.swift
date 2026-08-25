//
//  InMemoryPeriodRepository.swift
//  minusTests
//

import Foundation
@testable import minus

final class InMemoryPeriodRepository: PeriodRepository {
    private var storage: [UUID: PeriodKey] = [:]

    func save(period: PeriodKey) async throws {
        storage[period.id] = period
    }

    func getPeriod(id: UUID) async throws -> PeriodKey? {
        storage[id]
    }

    func getPeriod(byExternalId externalId: String) async throws -> PeriodKey? {
        storage.values.first { $0.externalId == externalId }
    }

    func getActivePeriod() async throws -> PeriodKey? {
        let now = Date()
        return storage.values
            .sorted { $0.startDate > $1.startDate }
            .first { $0.endDate == nil || $0.endDate! > now }
    }

    func getAllPeriods() async throws -> [PeriodKey] {
        storage.values.sorted { $0.startDate > $1.startDate }
    }

    func closePeriod(id: UUID, finalEndDate: Date) async throws {
        guard let existing = storage[id] else { return }
        storage[id] = PeriodKey(
            id: existing.id,
            startDate: existing.startDate,
            endDate: finalEndDate,
            mappingNode: existing.mappingNode,
            totalBudget: existing.totalBudget,
            currency: existing.currency,
            remainingStrategy: existing.remainingStrategy,
            periodType: existing.periodType,
            daysInPeriod: existing.daysInPeriod,
            carryOverAmount: existing.carryOverAmount,
            externalId: existing.externalId
        )
    }
}
