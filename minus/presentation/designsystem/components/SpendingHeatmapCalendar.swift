//
//  SpendingHeatmapCalendar.swift
//  minus
//
//  A month-grid calendar (weekday columns, week rows) spanning the active
//  budget period. Each day cell is colored by that day's spend relative to
//  the period's hottest day — green (low) through red (high) — via
//  Color.spendingHeat. Days with no recorded spending stay surface-colored
//  rather than reading as "zero," and today gets an outline.

import SwiftUI

struct SpendingHeatmapCalendar: View {
    let period: PeriodKey
    let dailyTotals: [DailyTotal]

    private static var calendar: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.locale = Locale(identifier: "en_US")
        return cal
    }()

    private static let weekdaySymbols = ["S", "M", "T", "W", "T", "F", "S"]

    private static let monthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        formatter.locale = Locale(identifier: "en_US")
        return formatter
    }()

    private static let accessibilityDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d"
        formatter.locale = Locale(identifier: "en_US")
        return formatter
    }()

    private var periodStart: Date { Self.calendar.startOfDay(for: period.startDate) }
    private var periodEnd: Date { Self.calendar.startOfDay(for: period.effectiveEndDate) }

    private var amountByDay: [Date: Decimal] {
        Dictionary(uniqueKeysWithValues: dailyTotals.map { (Self.calendar.startOfDay(for: $0.date), $0.amount) })
    }

    private var maxDailyAmount: Decimal {
        dailyTotals.map(\.amount).max() ?? 0
    }

    private var monthLabel: String {
        let startMonth = Self.monthFormatter.string(from: periodStart)
        let endMonth = Self.monthFormatter.string(from: periodEnd)
        return startMonth == endMonth ? startMonth : "\(startMonth) \u{2013} \(endMonth)"
    }

    /// Flat list of grid cells, weekday-aligned; padding cells outside the
    /// period's own range are `nil` so `LazyVGrid` still wraps every 7 into
    /// a full week row.
    private var gridDays: [Date?] {
        let cal = Self.calendar

        let startOffset = (cal.component(.weekday, from: periodStart) - cal.firstWeekday + 7) % 7
        let gridStart = cal.date(byAdding: .day, value: -startOffset, to: periodStart) ?? periodStart

        let endOffset = 6 - ((cal.component(.weekday, from: periodEnd) - cal.firstWeekday + 7) % 7)
        let gridEnd = cal.date(byAdding: .day, value: endOffset, to: periodEnd) ?? periodEnd

        var days: [Date?] = []
        var cursor = gridStart
        while cursor <= gridEnd {
            days.append(cursor >= periodStart && cursor <= periodEnd ? cursor : nil)
            cursor = cal.date(byAdding: .day, value: 1, to: cursor) ?? gridEnd.addingTimeInterval(1)
        }
        return days
    }

    private var columns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(monthLabel)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(Color.minus.textPrimary)

            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(Array(Self.weekdaySymbols.enumerated()), id: \.offset) { _, symbol in
                    Text(symbol)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color.minus.textSecondary)
                }
            }

            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(Array(gridDays.enumerated()), id: \.offset) { _, day in
                    dayCell(for: day)
                }
            }
        }
    }

    @ViewBuilder
    private func dayCell(for day: Date?) -> some View {
        if let day {
            let amount = amountByDay[day]
            let isToday = Self.calendar.isDateInToday(day)

            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(fillColor(for: amount))
                .aspectRatio(1, contentMode: .fit)
                .overlay(
                    Text("\(Self.calendar.component(.day, from: day))")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(labelColor(for: amount))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .stroke(Color.minus.textPrimary, lineWidth: isToday ? 2 : 0)
                )
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(accessibilityLabel(for: day, amount: amount))
        } else {
            Color.clear
                .aspectRatio(1, contentMode: .fit)
        }
    }

    private func fillColor(for amount: Decimal?) -> Color {
        guard let amount, maxDailyAmount > 0 else { return Color.minus.surface }
        return .spendingHeat(NSDecimalNumber(decimal: amount / maxDailyAmount).doubleValue)
    }

    private func labelColor(for amount: Decimal?) -> Color {
        amount == nil ? Color.minus.textSecondary : .white
    }

    private func accessibilityLabel(for day: Date, amount: Decimal?) -> String {
        let dateText = Self.accessibilityDateFormatter.string(from: day)
        guard let amount else { return "\(dateText), no spending" }
        return "\(dateText), spent \(amount)"
    }
}

#Preview {
    let calendar = Calendar.current
    let start = calendar.date(byAdding: .day, value: -9, to: Date())!
    let period = PeriodKey(
        id: UUID(),
        startDate: start,
        endDate: calendar.date(byAdding: .day, value: 20, to: start),
        mappingNode: .activeBucket,
        totalBudget: 3000,
        currency: "USD",
        remainingStrategy: .SPLIT_EQUALLY,
        periodType: .monthly,
        daysInPeriod: 30
    )
    let totals = (0..<10).compactMap { offset -> DailyTotal? in
        guard offset % 3 != 0 else { return nil }
        let date = calendar.date(byAdding: .day, value: offset, to: start)!
        return DailyTotal(date: date, amount: Decimal(Double.random(in: 5...200)))
    }

    return SpendingHeatmapCalendar(period: period, dailyTotals: totals)
        .padding()
        .background(Color.minus.background)
}
