//
//  PeriodKey.swift
//  minus
//
//  Created by Isaac Emmanuel Serrano Altamirano on 08/05/26.
//

import Foundation

enum PeriodMappingNode: String {
    case activeBucket
    case calendarBucket
}

struct PeriodKey: Identifiable {
    let id: UUID
    let startDate: Date
    let endDate: Date?
    let mappingNode: PeriodMappingNode
    let totalBudget: Decimal
    let currency: String
    let remainingStrategy: RemainingBudgetStrategy
    let periodType: BudgetPeriod
    let daysInPeriod: Int
    let carryOverAmount: Decimal

    init(
        id: UUID,
        startDate: Date,
        endDate: Date?,
        mappingNode: PeriodMappingNode,
        totalBudget: Decimal,
        currency: String,
        remainingStrategy: RemainingBudgetStrategy,
        periodType: BudgetPeriod,
        daysInPeriod: Int,
        carryOverAmount: Decimal = 0
    ) {
        self.id = id
        self.startDate = startDate
        self.endDate = endDate
        self.mappingNode = mappingNode
        self.totalBudget = totalBudget
        self.currency = currency
        self.remainingStrategy = remainingStrategy
        self.periodType = periodType
        self.daysInPeriod = daysInPeriod
        self.carryOverAmount = carryOverAmount
    }
}

extension PeriodKey {
    var effectiveEndDate: Date {
        endDate ?? BudgetSettings(
            totalBudget: totalBudget,
            period: periodType,
            startDate: startDate,
            daysInPeriod: daysInPeriod
        ).getPeriodEndDate()
    }

    func splitAmount(for mode: BudgetPeriod, referenceDate: Date = Date()) -> Decimal {
        let totalDays = max(1, daysInPeriod)
        let baseTotal = totalBudget - carryOverAmount
        let dailyRate = baseTotal / Decimal(totalDays)

        let multiplier: Int
        switch mode {
        case .daily: multiplier = 1
        case .weekly: multiplier = 7
        case .biweekly: multiplier = 14
        case .monthly: multiplier = totalDays
        }
        let windowDays = min(multiplier, totalDays)

        let calendar = Calendar.current
        let daysSinceStart = calendar.dateComponents(
            [.day],
            from: calendar.startOfDay(for: startDate),
            to: calendar.startOfDay(for: referenceDate)
        ).day ?? 0
        let isFirstWindow = daysSinceStart >= 0 && daysSinceStart < windowDays
        let bonus = isFirstWindow ? carryOverAmount : 0

        return dailyRate * Decimal(windowDays) + bonus
    }
}
