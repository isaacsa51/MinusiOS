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
    var totalBudget: Double
    var currency: String
    var remainingStrategy: String
    var periodType: String
    var daysInPeriod: Int
    
    init(
        id: UUID,
        startDate: Date,
        endDate: Date? = nil,
        mappingMode: String,
        totalBudget: Double = 0,
        currency: String = "USD",
        remainingStrategy: String = "ASK_ALWAYS",
        periodType: String = "monthly",
        daysInPeriod: Int = 30
    ) {
        self.id = id
        self.startDate = startDate
        self.endDate = endDate
        self.mappingMode = mappingMode
        self.totalBudget = totalBudget
        self.currency = currency
        self.remainingStrategy = remainingStrategy
        self.periodType = periodType
        self.daysInPeriod = daysInPeriod
    }
}
