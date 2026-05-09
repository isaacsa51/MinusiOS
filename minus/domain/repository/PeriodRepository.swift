//
//  PeriodRepository.swift
//  minus
//
//  Created by Isaac Emmanuel Serrano Altamirano on 08/05/26.
//

import Foundation

protocol PeriodRepository {
    func save(period: PeriodKey) async throws
    
    func getPeriod(id: UUID) async throws -> PeriodKey?
    
    func getActivePeriod() async throws -> PeriodKey?
    
    func getAllPeriods() async throws -> [PeriodKey]
    
    func closePeriod(id: UUID, finalEndDate: Date) async throws
}
