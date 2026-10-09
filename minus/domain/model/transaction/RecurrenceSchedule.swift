//
//  RecurrenceSchedule.swift
//  minus
//

import Foundation

/// Projects a recurring transaction's template onto the concrete dates it falls
/// due on.
///
/// Recurring payments are stored as a single row — future occurrences are never
/// materialized as transactions — so everything that needs to look ahead
/// (reserved charges, due-date reminders) derives its dates from here rather
/// than from stored data.
enum RecurrenceSchedule {
    /// Ceiling on every projection loop, so a malformed anchor or window can't spin.
    private static let maxOccurrences = 1000

    /// Every due date in `from...through`, inclusive, normalized to the start of
    /// its day. Never returns a date before `anchor` or after `recurrentEndDate`,
    /// and is empty when the window is inverted or falls outside the
    /// recurrence's lifetime.
    static func occurrences(
        frequency: RecurrentFrequency,
        anchor: Date,
        recurrentEndDate: Date? = nil,
        subscriptionDay: Int? = nil,
        from: Date,
        through: Date,
        calendar: Calendar = .current
    ) -> [Date] {
        let windowStart = calendar.startOfDay(for: from)
        var windowEnd = calendar.startOfDay(for: through)
        let anchorDay = calendar.startOfDay(for: anchor)

        if let recurrentEndDate {
            windowEnd = min(windowEnd, calendar.startOfDay(for: recurrentEndDate))
        }
        guard windowStart <= windowEnd, anchorDay <= windowEnd else { return [] }

        switch frequency {
        case .DAILY:
            return stepped(byDays: 1, anchorDay: anchorDay, windowStart: windowStart, windowEnd: windowEnd, calendar: calendar)
        case .WEEKLY:
            return stepped(byDays: 7, anchorDay: anchorDay, windowStart: windowStart, windowEnd: windowEnd, calendar: calendar)
        case .BIWEEKLY:
            return stepped(byDays: 14, anchorDay: anchorDay, windowStart: windowStart, windowEnd: windowEnd, calendar: calendar)
        case .MONTHLY:
            let day = subscriptionDay ?? calendar.component(.day, from: anchorDay)
            return monthly(onDay: day, anchorDay: anchorDay, windowStart: windowStart, windowEnd: windowEnd, calendar: calendar)
        }
    }

    /// The first due date on or after `referenceDate`, or nil once the
    /// recurrence has run out. Searches only one cycle past the first candidate
    /// day, which is always enough to contain the next occurrence.
    static func nextOccurrence(
        frequency: RecurrentFrequency,
        anchor: Date,
        recurrentEndDate: Date? = nil,
        subscriptionDay: Int? = nil,
        onOrAfter referenceDate: Date,
        calendar: Calendar = .current
    ) -> Date? {
        let lookaheadDays: Int
        switch frequency {
        case .DAILY: lookaheadDays = 1
        case .WEEKLY: lookaheadDays = 7
        case .BIWEEKLY: lookaheadDays = 14
        // Two months, so a day-31 subscription still finds February.
        case .MONTHLY: lookaheadDays = 62
        }

        // Starting at the anchor when it's still in the future keeps the search
        // window small for an imported transaction dated ahead of today.
        let searchStart = max(calendar.startOfDay(for: referenceDate), calendar.startOfDay(for: anchor))
        guard let searchEnd = calendar.date(byAdding: .day, value: lookaheadDays, to: searchStart) else { return nil }

        return occurrences(
            frequency: frequency,
            anchor: anchor,
            recurrentEndDate: recurrentEndDate,
            subscriptionDay: subscriptionDay,
            from: searchStart,
            through: searchEnd,
            calendar: calendar
        ).first
    }

    // MARK: - Fixed-interval frequencies

    private static func stepped(
        byDays stepDays: Int,
        anchorDay: Date,
        windowStart: Date,
        windowEnd: Date,
        calendar: Calendar
    ) -> [Date] {
        // Jump straight to the first tick inside the window instead of walking
        // through what may be years of history one step at a time.
        let daysUntilWindow = calendar.dateComponents([.day], from: anchorDay, to: windowStart).day ?? 0
        let skippedSteps = daysUntilWindow > 0 ? (daysUntilWindow + stepDays - 1) / stepDays : 0
        guard var current = calendar.date(byAdding: .day, value: skippedSteps * stepDays, to: anchorDay) else { return [] }

        var dates: [Date] = []
        while current <= windowEnd, dates.count < maxOccurrences {
            if current >= windowStart {
                dates.append(current)
            }
            guard let next = calendar.date(byAdding: .day, value: stepDays, to: current) else { break }
            current = next
        }
        return dates
    }

    // MARK: - Monthly

    private static func monthly(
        onDay day: Int,
        anchorDay: Date,
        windowStart: Date,
        windowEnd: Date,
        calendar: Calendar
    ) -> [Date] {
        // Walk month by month from whichever of the anchor and the window start
        // comes later, clamping the requested day to each month's own length so
        // a day-31 subscription still lands in February.
        let firstMonth = max(anchorDay, windowStart)
        guard var monthCursor = calendar.date(from: calendar.dateComponents([.year, .month], from: firstMonth)) else { return [] }

        var dates: [Date] = []
        while monthCursor <= windowEnd, dates.count < maxOccurrences {
            if let due = dueDate(onDay: day, inMonthOf: monthCursor, calendar: calendar),
               due >= windowStart, due >= anchorDay, due <= windowEnd {
                dates.append(due)
            }
            guard let nextMonth = calendar.date(byAdding: .month, value: 1, to: monthCursor) else { break }
            monthCursor = nextMonth
        }
        return dates
    }

    private static func dueDate(onDay day: Int, inMonthOf date: Date, calendar: Calendar) -> Date? {
        var components = calendar.dateComponents([.year, .month], from: date)
        let daysInMonth = calendar.range(of: .day, in: .month, for: date)?.count ?? day
        components.day = min(max(day, 1), daysInMonth)
        return calendar.date(from: components)
    }
}
