//
//  PeriodKey.swift
//  minus
//
//  Created by Isaac Emmanuel Serrano Altamirano on 08/05/26.
//

import Foundation

enum PeriodMappingNode {
    case activeBucket
    case calendarBucket
}

struct PeriodKey: Identifiable {
    let id: UUID
    let startDate: Date
    let endDate: Date?
    let mappingNode: PeriodMappingNode
}
