//
//  RecurrenceScheduleTests.swift
//  minusTests
//

import Testing
import Foundation
@testable import minus

struct RecurrenceScheduleTests {
    private let calendar = Calendar.current

    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day))!
    }

    // MARK: - Fixed intervals

    @Test func dailyYieldsEveryDayInTheWindow() {
        let occurrences = RecurrenceSchedule.occurrences(
            frequency: .DAILY,
            anchor: date(2026, 1, 1),
            from: date(2026, 1, 10),
            through: date(2026, 1, 14)
        )
        #expect(occurrences == [
            date(2026, 1, 10), date(2026, 1, 11), date(2026, 1, 12),
            date(2026, 1, 13), date(2026, 1, 14)
        ])
    }

    @Test func weeklyStaysOnTheAnchorsWeekday() {
        let anchor = date(2026, 1, 5) // a Monday
        let occurrences = RecurrenceSchedule.occurrences(
            frequency: .WEEKLY,
            anchor: anchor,
            from: date(2026, 1, 6),
            through: date(2026, 2, 2)
        )
        #expect(occurrences == [date(2026, 1, 12), date(2026, 1, 19), date(2026, 1, 26), date(2026, 2, 2)])
        #expect(occurrences.allSatisfy {
            calendar.component(.weekday, from: $0) == calendar.component(.weekday, from: anchor)
        })
    }

    @Test func biweeklyAdvancesInFourteenDaySteps() {
        let occurrences = RecurrenceSchedule.occurrences(
            frequency: .BIWEEKLY,
            anchor: date(2026, 1, 1),
            from: date(2026, 1, 1),
            through: date(2026, 2, 1)
        )
        #expect(occurrences == [date(2026, 1, 1), date(2026, 1, 15), date(2026, 1, 29)])
    }

    // MARK: - Monthly

    @Test func monthlyClampsTheSubscriptionDayToEachMonthsLength() {
        let occurrences = RecurrenceSchedule.occurrences(
            frequency: .MONTHLY,
            anchor: date(2026, 1, 31),
            subscriptionDay: 31,
            from: date(2026, 2, 1),
            through: date(2026, 4, 30)
        )
        // 2026 is not a leap year, so February clamps to the 28th.
        #expect(occurrences == [date(2026, 2, 28), date(2026, 3, 31), date(2026, 4, 30)])
    }

    @Test func monthlyFallsBackToTheAnchorsDayWithoutASubscriptionDay() {
        let occurrences = RecurrenceSchedule.occurrences(
            frequency: .MONTHLY,
            anchor: date(2026, 1, 7),
            from: date(2026, 3, 1),
            through: date(2026, 4, 30)
        )
        #expect(occurrences == [date(2026, 3, 7), date(2026, 4, 7)])
    }

    // MARK: - Bounds

    @Test func neverYieldsAnythingBeforeTheAnchor() {
        let occurrences = RecurrenceSchedule.occurrences(
            frequency: .DAILY,
            anchor: date(2026, 1, 15),
            from: date(2026, 1, 10),
            through: date(2026, 1, 17)
        )
        #expect(occurrences == [date(2026, 1, 15), date(2026, 1, 16), date(2026, 1, 17)])
    }

    @Test func stopsAtTheRecurrenceEndDate() {
        let occurrences = RecurrenceSchedule.occurrences(
            frequency: .DAILY,
            anchor: date(2026, 1, 1),
            recurrentEndDate: date(2026, 1, 12),
            from: date(2026, 1, 10),
            through: date(2026, 1, 20)
        )
        #expect(occurrences == [date(2026, 1, 10), date(2026, 1, 11), date(2026, 1, 12)])
    }

    @Test func isEmptyWhenTheAnchorLiesBeyondTheWindow() {
        let occurrences = RecurrenceSchedule.occurrences(
            frequency: .DAILY,
            anchor: date(2026, 2, 1),
            from: date(2026, 1, 10),
            through: date(2026, 1, 20)
        )
        #expect(occurrences.isEmpty)
    }

    @Test func isEmptyWhenTheWindowIsInverted() {
        let occurrences = RecurrenceSchedule.occurrences(
            frequency: .DAILY,
            anchor: date(2026, 1, 1),
            from: date(2026, 1, 20),
            through: date(2026, 1, 10)
        )
        #expect(occurrences.isEmpty)
    }

    // MARK: - nextOccurrence

    @Test func nextOccurrenceSkipsForwardToAFutureAnchor() {
        let next = RecurrenceSchedule.nextOccurrence(
            frequency: .MONTHLY,
            anchor: date(2026, 3, 1),
            subscriptionDay: 1,
            onOrAfter: date(2026, 1, 15)
        )
        #expect(next == date(2026, 3, 1))
    }

    @Test func nextOccurrenceIsNilOnceTheRecurrenceHasEnded() {
        let next = RecurrenceSchedule.nextOccurrence(
            frequency: .WEEKLY,
            anchor: date(2026, 1, 5),
            recurrentEndDate: date(2026, 1, 20),
            onOrAfter: date(2026, 2, 1)
        )
        #expect(next == nil)
    }
}
