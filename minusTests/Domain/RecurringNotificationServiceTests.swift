//
//  RecurringNotificationServiceTests.swift
//  minusTests
//

import Testing
import Foundation
@testable import minus

struct RecurringNotificationServiceTests {
    @Test func dailyDueDateIsAlwaysToday() {
        let anchor = Date(timeIntervalSince1970: 0)
        let reference = Calendar.current.date(byAdding: .day, value: 30, to: anchor)!
        let due = RecurringNotificationService.nextDueDate(
            frequency: .DAILY, startDate: anchor, endDate: nil, subscriptionDay: nil, referenceDate: reference
        )
        #expect(due.map { Calendar.current.isDate($0, inSameDayAs: reference) } == true)
    }

    @Test func weeklyDueDateLandsOnSameWeekdayAsAnchor() {
        let calendar = Calendar.current
        let anchor = calendar.date(from: DateComponents(year: 2026, month: 1, day: 5))! // a Monday
        let reference = calendar.date(from: DateComponents(year: 2026, month: 1, day: 8))! // Thursday
        let due = RecurringNotificationService.nextDueDate(
            frequency: .WEEKLY, startDate: anchor, endDate: nil, subscriptionDay: nil, referenceDate: reference
        )
        let dueWeekday = due.map { calendar.component(.weekday, from: $0) }
        #expect(dueWeekday == calendar.component(.weekday, from: anchor))
    }

    @Test func biweeklyDueDateAdvancesInFourteenDaySteps() {
        let calendar = Calendar.current
        let anchor = Date(timeIntervalSince1970: 0)
        let reference = calendar.date(byAdding: .day, value: 20, to: anchor)!
        let due = RecurringNotificationService.nextDueDate(
            frequency: .BIWEEKLY, startDate: anchor, endDate: nil, subscriptionDay: nil, referenceDate: reference
        )
        let expected = calendar.date(byAdding: .day, value: 28, to: calendar.startOfDay(for: anchor))!
        #expect(due.map { calendar.isDate($0, inSameDayAs: expected) } == true)
    }

    @Test func monthlyDueDateClampsToShorterMonths() {
        let calendar = Calendar.current
        let anchor = calendar.date(from: DateComponents(year: 2026, month: 1, day: 31))!
        let reference = calendar.date(from: DateComponents(year: 2026, month: 2, day: 1))!
        let due = RecurringNotificationService.nextDueDate(
            frequency: .MONTHLY, startDate: anchor, endDate: nil, subscriptionDay: 31, referenceDate: reference
        )
        let expectedDay = calendar.range(of: .day, in: .month, for: reference)!.count
        #expect(due.map { calendar.component(.day, from: $0) } == expectedDay)
        #expect(due.map { calendar.component(.month, from: $0) } == 2)
    }

    @Test func monthlyDueDateRollsToNextMonthWhenThisMonthsDateHasPassed() {
        let calendar = Calendar.current
        let anchor = calendar.date(from: DateComponents(year: 2026, month: 1, day: 5))!
        let reference = calendar.date(from: DateComponents(year: 2026, month: 3, day: 10))!
        let due = RecurringNotificationService.nextDueDate(
            frequency: .MONTHLY, startDate: anchor, endDate: nil, subscriptionDay: 5, referenceDate: reference
        )
        #expect(due.map { calendar.component(.month, from: $0) } == 4)
        #expect(due.map { calendar.component(.day, from: $0) } == 5)
    }

    @Test func dueDateReturnsNilOnceItWouldFallAfterEndDate() {
        let calendar = Calendar.current
        let anchor = Date(timeIntervalSince1970: 0)
        let end = calendar.date(byAdding: .day, value: 3, to: anchor)!
        let reference = calendar.date(byAdding: .day, value: 10, to: anchor)!
        let due = RecurringNotificationService.nextDueDate(
            frequency: .DAILY, startDate: anchor, endDate: end, subscriptionDay: nil, referenceDate: reference
        )
        #expect(due == nil)
    }
}
