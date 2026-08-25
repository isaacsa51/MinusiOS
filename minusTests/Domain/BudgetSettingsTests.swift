//
//  BudgetSettingsTests.swift
//  minusTests
//

import Testing
import Foundation
@testable import minus

struct BudgetSettingsTests {
    @Test func daysForPeriodUsesExplicitOverrideWhenLarger() {
        let settings = BudgetSettings(totalBudget: 100, period: .weekly, startDate: Date(), daysInPeriod: 20)
        #expect(settings.getDaysForPeriod() == 20)
    }

    @Test func daysForPeriodFallsBackToBaseWhenOverrideSmaller() {
        let settings = BudgetSettings(totalBudget: 100, period: .monthly, startDate: Date(), daysInPeriod: 5)
        #expect(settings.getDaysForPeriod() == 30)
    }

    @Test func calculateDailyBudgetRoundsToTwoDecimals() {
        let settings = BudgetSettings(totalBudget: 100, period: .weekly, startDate: Date(), daysInPeriod: 7)
        #expect(settings.calculateDailyBudget() == Decimal(string: "14.29"))
    }

    @Test func calculateDailyBudgetReturnsTotalWhenDaysIsZero() {
        let settings = BudgetSettings(totalBudget: 100, period: .daily, startDate: Date(), daysInPeriod: 1)
        #expect(settings.calculateDailyBudget() == 100)
    }

    @Test func periodEndDateUsesExplicitEndDateWhenSet() {
        let start = Date()
        let end = Calendar.current.date(byAdding: .day, value: 10, to: start)!
        let settings = BudgetSettings(totalBudget: 100, period: .monthly, startDate: start, endDate: end)
        #expect(settings.getPeriodEndDate() == end)
    }

    @Test func periodEndDateComputedFromDaysWhenNoExplicitEndDate() {
        let start = Date(timeIntervalSince1970: 0)
        let settings = BudgetSettings(totalBudget: 100, period: .daily, startDate: start, daysInPeriod: 5)
        let expected = Calendar.current.date(byAdding: .day, value: 4, to: start)!
        #expect(settings.getPeriodEndDate() == expected)
    }
}
