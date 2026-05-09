//
//  PeriodEntity.swift
//  minus
//
//  Created by Isaac Emmanuel Serrano Altamirano on 09/05/26.
//

import Foundation
import SwiftData

@Model
class PeriodEntity {
    @Attribute(.unique) var id: UUID
    var startDate: Date
    var endDate: Date?
    var mappingMode: String
    
    init(id: UUID, startDate: Date, endDate: Date? = nil, mappingMode: String) {
        self.id = id
        self.startDate = startDate
        self.endDate = endDate
        self.mappingMode = mappingMode
    }
}
