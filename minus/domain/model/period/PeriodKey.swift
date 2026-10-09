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
    let externalId: String?

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
        carryOverAmount: Decimal = 0,
        externalId: String? = nil
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
        self.externalId = externalId
    }
}

extension PeriodKey {
    var effectiveEndDate: Date {
        if let endDate { return endDate }
        // `daysInPeriod` is this period's already-resolved length. Routing
        // through BudgetSettings would re-apply its create-time rule of
        // rounding a requested length up to the period type's minimum, so a
        // 14-day monthly period would report a 30-day span — contradicting the
        // same `daysInPeriod` that windowDays(for:) and the daily-rate math use.
        let days = Swift.max(1, daysInPeriod)
        return Calendar.current.date(byAdding: .day, value: days - 1, to: startDate) ?? startDate
    }

    /// How many days the pill's window covers, never more than the period itself.
    func windowDays(for mode: BudgetPeriod) -> Int {
        let totalDays = max(1, daysInPeriod)

        let multiplier: Int
        switch mode {
        case .daily: multiplier = 1
        case .weekly: multiplier = 7
        case .biweekly: multiplier = 14
        case .monthly: multiplier = totalDays
        }
        return min(multiplier, totalDays)
    }

    /// Whether `referenceDate` still falls inside the period's opening window —
    /// the only one an `ADD_TO_FIRST_DAY` carry-over is paid out in.
    func isFirstWindow(for mode: BudgetPeriod, referenceDate: Date = Date()) -> Bool {
        let calendar = Calendar.current
        let daysSinceStart = calendar.dateComponents(
            [.day],
            from: calendar.startOfDay(for: startDate),
            to: calendar.startOfDay(for: referenceDate)
        ).day ?? 0
        return daysSinceStart >= 0 && daysSinceStart < windowDays(for: mode)
    }

    func splitAmount(for mode: BudgetPeriod, dailyRate: Decimal, referenceDate: Date = Date()) -> Decimal {
        let bonus = isFirstWindow(for: mode, referenceDate: referenceDate) ? carryOverAmount : 0
        return dailyRate * Decimal(windowDays(for: mode)) + bonus
    }
}
