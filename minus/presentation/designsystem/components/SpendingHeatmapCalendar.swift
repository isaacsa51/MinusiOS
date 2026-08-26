//
//  SpendingHeatmapCalendar.swift
//  minus
//
//  A month-grid calendar (weekday columns, week rows) spanning the active
//  budget period. Each day cell is colored by that day's spend relative to
//  the period's hottest day — green (low) through red (high) — via
//  Color.spendingHeat. Every cell gets a subtle outline so empty (no-spend)
//  days stay visible against the card; today's outline is stronger, and the
//  single hottest day renders oversized, overlapping its neighbors. Owns its
//  own card chrome (padding/background/corner radius) — callers just place it.
//
//  When the period spans more than one calendar month, it renders as one
//  section per month (own label, own weekday header), each padded out to
//  full weeks: days that belong to that month but fall outside the period
//  render dimmed rather than dropped, so the boundary week never looks cut
//  off; days that belong to an adjacent month are blank, since that month
//  gets its own section instead of sharing the row.
//
//  Deliberately plain LazyVGrid rather than Swift Charts: this is a calendar
//  grid, not really "a chart," and LazyVGrid's GridItem(.flexible()) sizes
//  and aligns every cell natively — no manual width measurement, no plot-area
//  margins to account for, nothing to get subtly wrong.

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

    /// A day-grid slot: `blank` belongs to a neighboring month (rendered in
    /// its own section instead), `dimmed` belongs to this section's month but
    /// falls outside the period, `real` is an actual in-period day.
    private enum GridSlot {
        case blank
        case dimmed(Date)
        case real(Date)
    }

    private struct MonthSection: Identifiable {
        let id: Date
        let label: String
        let slots: [GridSlot]
    }

    private func weekStart(of date: Date) -> Date {
        let cal = Self.calendar
        let offset = (cal.component(.weekday, from: date) - cal.firstWeekday + 7) % 7
        return cal.date(byAdding: .day, value: -offset, to: date) ?? date
    }

    private func weekEnd(of date: Date) -> Date {
        let cal = Self.calendar
        let offset = 6 - ((cal.component(.weekday, from: date) - cal.firstWeekday + 7) % 7)
        return cal.date(byAdding: .day, value: offset, to: date) ?? date
    }

    private var monthSections: [MonthSection] {
        let cal = Self.calendar
        guard let periodStartMonth = cal.dateInterval(of: .month, for: periodStart)?.start,
              let periodEndMonth = cal.dateInterval(of: .month, for: periodEnd)?.start else {
            return []
        }

        var sections: [MonthSection] = []
        var monthCursor = periodStartMonth

        while monthCursor <= periodEndMonth {
            guard let monthInterval = cal.dateInterval(of: .month, for: monthCursor) else { break }
            let firstOfMonth = monthInterval.start
            let lastOfMonth = cal.date(byAdding: .day, value: -1, to: monthInterval.end) ?? monthInterval.end

            let sectionStart = max(periodStart, firstOfMonth)
            let sectionEnd = min(periodEnd, lastOfMonth)

            var slots: [GridSlot] = []
            var cursor = weekStart(of: sectionStart)
            let gridEnd = weekEnd(of: sectionEnd)
            while cursor <= gridEnd {
                let belongsToThisMonth = cal.dateInterval(of: .month, for: cursor)?.start == firstOfMonth
                if belongsToThisMonth {
                    slots.append(cursor >= periodStart && cursor <= periodEnd ? .real(cursor) : .dimmed(cursor))
                } else {
                    slots.append(.blank)
                }
                cursor = cal.date(byAdding: .day, value: 1, to: cursor) ?? gridEnd.addingTimeInterval(1)
            }

            sections.append(MonthSection(
                id: firstOfMonth,
                label: Self.monthFormatter.string(from: firstOfMonth),
                slots: slots
            ))

            guard let nextMonth = cal.date(byAdding: .month, value: 1, to: monthCursor) else { break }
            monthCursor = nextMonth
        }

        return sections
    }

    private var columns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            ForEach(monthSections) { section in
                VStack(alignment: .leading, spacing: 12) {
                    Text(section.label)
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
                        ForEach(Array(section.slots.enumerated()), id: \.offset) { _, slot in
                            dayCell(slot)
                        }
                    }
                    // Extra breathing room above row 0 so the hottest day's oversized
                    // cell (below) can bleed upward without touching the header row.
                    .padding(.top, 8)
                }
            }
        }
        .padding(20)
        .background(Color.minus.surface)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    @ViewBuilder
    private func dayCell(_ slot: GridSlot) -> some View {
        switch slot {
        case .blank:
            Color.clear
                .aspectRatio(1, contentMode: .fit)

        case .dimmed(let day):
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(Color.clear)
                .aspectRatio(1, contentMode: .fit)
                .overlay(
                    Text("\(Self.calendar.component(.day, from: day))")
                        .font(.system(size: 10, weight: .medium))
                        .italic()
                        .foregroundStyle(Color.minus.textSecondary.opacity(0.6))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .stroke(Color.minus.divider, lineWidth: 1)
                )
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(accessibilityLabel(for: day, amount: nil))

        case .real(let day):
            let amount = amountByDay[day]
            let isToday = Self.calendar.isDateInToday(day)
            let isHottestDay = maxDailyAmount > 0 && amount == maxDailyAmount

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
                        .stroke(
                            isToday ? Color.minus.textPrimary : Color.minus.divider,
                            lineWidth: isToday ? 2 : 1
                        )
                )
                .scaleEffect(isHottestDay ? 1.3 : 1)
                .zIndex(isHottestDay ? 1 : 0)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(accessibilityLabel(for: day, amount: amount))
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
