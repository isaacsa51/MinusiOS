//
//  PeriodKeyTests.swift
//  minusTests
//

import Testing
import Foundation
@testable import minus

struct PeriodKeyTests {
    @Test func splitAmountAppliesDailyRateAcrossWindow() {
        let period = PeriodKey(
            id: UUID(),
            startDate: Date(timeIntervalSince1970: 0),
            endDate: nil,
            mappingNode: .activeBucket,
            totalBudget: 500,
            currency: "USD",
            remainingStrategy: .SPLIT_EQUALLY,
            periodType: .monthly,
            daysInPeriod: 10
        )

        let daily = period.splitAmount(for: .daily, dailyRate: 50, referenceDate: period.startDate)
        #expect(daily == 50)

        let weekly = period.splitAmount(for: .weekly, dailyRate: 50, referenceDate: period.startDate)
        #expect(weekly == 350)
    }

    @Test func splitAmountClampsWindowToRemainingDaysInPeriod() {
        let period = PeriodKey(
            id: UUID(),
            startDate: Date(timeIntervalSince1970: 0),
            endDate: nil,
            mappingNode: .activeBucket,
            totalBudget: 100,
            currency: "USD",
            remainingStrategy: .SPLIT_EQUALLY,
            periodType: .monthly,
            daysInPeriod: 5
        )

        let weekly = period.splitAmount(for: .weekly, dailyRate: 20, referenceDate: period.startDate)
        #expect(weekly == 100)
    }

    @Test func splitAmountAddsCarryOverBonusOnlyInFirstWindow() {
        let start = Date(timeIntervalSince1970: 0)
        let period = PeriodKey(
            id: UUID(),
            startDate: start,
            endDate: nil,
            mappingNode: .activeBucket,
            totalBudget: 500,
            currency: "USD",
            remainingStrategy: .ADD_TO_FIRST_DAY,
            periodType: .monthly,
            daysInPeriod: 10,
            carryOverAmount: 20
        )

        let firstDay = period.splitAmount(for: .daily, dailyRate: 48, referenceDate: start)
        #expect(firstDay == 68)

        let laterDay = Calendar.current.date(byAdding: .day, value: 5, to: start)!
        let laterDayAmount = period.splitAmount(for: .daily, dailyRate: 48, referenceDate: laterDay)
        #expect(laterDayAmount == 48)
    }

    @Test func effectiveEndDateReturnsExplicitEndDateWhenSet() {
        let start = Date(timeIntervalSince1970: 0)
        let end = Calendar.current.date(byAdding: .day, value: 20, to: start)!
        let period = PeriodKey(
            id: UUID(), startDate: start, endDate: end, mappingNode: .activeBucket,
            totalBudget: 100, currency: "USD", remainingStrategy: .SPLIT_EQUALLY,
            periodType: .monthly, daysInPeriod: 30
        )
        #expect(period.effectiveEndDate == end)
    }

    @Test func effectiveEndDateFallsBackToComputedEndWhenNil() {
        let start = Date(timeIntervalSince1970: 0)
        let period = PeriodKey(
            id: UUID(), startDate: start, endDate: nil, mappingNode: .activeBucket,
            totalBudget: 300, currency: "USD", remainingStrategy: .SPLIT_EQUALLY,
            periodType: .weekly, daysInPeriod: 7
        )
        let expected = Calendar.current.date(byAdding: .day, value: 6, to: start)!
        #expect(Calendar.current.isDate(period.effectiveEndDate, inSameDayAs: expected))
    }
}
