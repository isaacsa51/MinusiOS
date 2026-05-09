//
//  PeriodReportRepositoryImpl.swift
//  minus
//
//  Created by Isaac Emmanuel Serrano Altamirano on 09/05/26.
//

import Foundation
import SwiftData

class PeriodReportRepositoryImpl: PeriodRepository {
    private let context: ModelContext
    
    init(context: ModelContext) {
        self.context = context
    }

    func save(period: PeriodKey) async throws {
        let entity = PeriodEntity(
            id: period.id,
            startDate: period.startDate,
            endDate: period.endDate,
            mappingMode: period.mappingNode.rawValue
        )
        
        context.insert(entity)
        try context.save()
    }
    
    func getPeriod(id: UUID) async throws -> PeriodKey? {
        let predicate = #Predicate<PeriodEntity> { $0.id == id }
        var descriptor = FetchDescriptor<PeriodEntity>(predicate: predicate)
        descriptor.fetchLimit = 1
        
        if let entity = try context.fetch(descriptor).first {
            return mapToDomain(entity)
        }
        return nil
    }
    
    func getActivePeriod() async throws -> PeriodKey? {
        let predicate = #Predicate<PeriodEntity> { $0.endDate == nil }
        
        var descriptor = FetchDescriptor<PeriodEntity>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.startDate, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        
        if let entity = try context.fetch(descriptor).first {
            return mapToDomain(entity)
        }
        return nil
    }
    
    func getAllPeriods() async throws -> [PeriodKey] {
        let descriptor = FetchDescriptor<PeriodEntity>(
            sortBy: [SortDescriptor(\.startDate, order: .reverse)]
        )
        
        let entities = try context.fetch(descriptor)
        return entities.map { mapToDomain($0) }
    }
    
    func closePeriod(id: UUID, finalEndDate: Date) async throws {
        let predicate = #Predicate<PeriodEntity> { $0.id == id }
        var descriptor = FetchDescriptor<PeriodEntity>(predicate: predicate)
        descriptor.fetchLimit = 1
        
        if let entity = try context.fetch(descriptor).first {
            entity.endDate = finalEndDate
            try context.save()
        }
    }
    
    private func mapToDomain(_ entity: PeriodEntity) -> PeriodKey {
        return PeriodKey(
            id: entity.id,
            startDate: entity.startDate,
            endDate: entity.endDate,
            mappingNode: PeriodMappingNode(rawValue: entity.mappingMode) ?? .activeBucket
        )
    }
}
