//
//  MonthlySpendingCompactWidget.swift
//  MinusWidget
//

import WidgetKit
import SwiftUI

struct MonthlySpendingCompactEntry: TimelineEntry {
    let date: Date
    let monthStart: Date
    let periodStartDate: Date
    let periodEndDate: Date
    let currencySymbol: String
    let dailyAmounts: [Date: Double]
    let expenseCount: Int
    let recentExpenses: [RecentExpense]
}

struct MonthlySpendingCompactProvider: TimelineProvider {
    func placeholder(in context: Context) -> MonthlySpendingCompactEntry {
        .sample
    }

    func getSnapshot(in context: Context, completion: @escaping (MonthlySpendingCompactEntry) -> Void) {
        completion(context.isPreview ? .sample : currentEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<MonthlySpendingCompactEntry>) -> Void) {
        let nextReload = Calendar.current.date(byAdding: .hour, value: 1, to: .now) ?? .now
        completion(Timeline(entries: [currentEntry()], policy: .after(nextReload)))
    }

    private func currentEntry() -> MonthlySpendingCompactEntry {
        let calendar = Calendar.current
        let monthStart = calendar.dateInterval(of: .month, for: .now)?.start ?? calendar.startOfDay(for: .now)

        guard let data = SpendingHeatmapSnapshotStore.read() else {
            return MonthlySpendingCompactEntry(
                date: .now,
                monthStart: monthStart,
                periodStartDate: monthStart,
                periodEndDate: monthStart,
                currencySymbol: "$",
                dailyAmounts: [:],
                expenseCount: 0,
                recentExpenses: []
            )
        }

        let monthInterval = calendar.dateInterval(of: .month, for: monthStart)
        let statsInMonth = data.dailyStats.filter { day, _ in
            guard let monthInterval else { return false }
            return day >= monthInterval.start && day < monthInterval.end
        }

        return MonthlySpendingCompactEntry(
            date: .now,
            monthStart: monthStart,
            periodStartDate: data.periodStartDate,
            periodEndDate: data.periodEndDate,
            currencySymbol: data.currencySymbol,
            dailyAmounts: statsInMonth.mapValues(\.amount),
            expenseCount: statsInMonth.values.reduce(0) { $0 + $1.count },
            recentExpenses: data.recentExpenses
        )
    }
}

extension MonthlySpendingCompactEntry {
    static var sample: MonthlySpendingCompactEntry {
        let calendar = Calendar.current
        let monthStart = calendar.dateInterval(of: .month, for: .now)?.start ?? calendar.startOfDay(for: .now)

        var amounts: [Date: Double] = [:]
        var count = 0
        for offset in 0..<15 where offset % 3 != 0 {
            let day = calendar.date(byAdding: .day, value: offset, to: monthStart) ?? monthStart
            amounts[day] = Double.random(in: 5...200)
            count += 1
        }

        let categories = ["Food", "Transport", "Shopping"]
        let recentExpenses = categories.enumerated().map { index, name in
            RecentExpense(
                categoryName: name,
                amount: 123.45,
                date: calendar.date(byAdding: .day, value: -index, to: .now) ?? .now
            )
        }

        return MonthlySpendingCompactEntry(
            date: .now,
            monthStart: monthStart,
            periodStartDate: monthStart,
            periodEndDate: calendar.date(byAdding: .month, value: 1, to: monthStart) ?? monthStart,
            currencySymbol: "$",
            dailyAmounts: amounts,
            expenseCount: count,
            recentExpenses: recentExpenses
        )
    }
}

struct MonthlySpendingCompactEntryView: View {
    var entry: MonthlySpendingCompactProvider.Entry
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.widgetFamily) private var family

    private var palette: WidgetPalette { colorScheme == .dark ? .dark : .light }

    private static var calendar: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.locale = Locale.autoupdatingCurrent
        return cal
    }()

    private static let monthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        formatter.locale = Locale.autoupdatingCurrent
        return formatter
    }()

    private var monthStart: Date { Self.calendar.startOfDay(for: entry.monthStart) }
    private var periodStart: Date { Self.calendar.startOfDay(for: entry.periodStartDate) }
    private var periodEnd: Date { Self.calendar.startOfDay(for: entry.periodEndDate) }

    private var maxDailyAmount: Double {
        entry.dailyAmounts.values.max() ?? 0
    }

    private var monthLabel: String {
        Self.monthFormatter.string(from: monthStart)
    }

    private enum GridSlot {
        case blank
        case dimmed(Date)
        case real(Date)
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

    private var gridSlots: [GridSlot] {
        let cal = Self.calendar
        guard let monthInterval = cal.dateInterval(of: .month, for: monthStart) else { return [] }
        let firstOfMonth = monthInterval.start
        let lastOfMonth = cal.date(byAdding: .day, value: -1, to: monthInterval.end) ?? monthInterval.end

        var slots: [GridSlot] = []
        var cursor = weekStart(of: firstOfMonth)
        let gridEnd = weekEnd(of: lastOfMonth)
        while cursor <= gridEnd {
            let belongsToThisMonth = cal.dateInterval(of: .month, for: cursor)?.start == firstOfMonth
            if belongsToThisMonth {
                slots.append(cursor >= periodStart && cursor <= periodEnd ? .real(cursor) : .dimmed(cursor))
            } else {
                slots.append(.blank)
            }
            cursor = cal.date(byAdding: .day, value: 1, to: cursor) ?? gridEnd.addingTimeInterval(1)
        }
        return slots
    }

    private var numberOfRows: Int {
        max(1, Int((Double(gridSlots.count) / 7.0).rounded(.up)))
    }

    private var isCompact: Bool { family == .systemSmall }
    private var cellSpacing: CGFloat { isCompact ? 1.5 : 2.5 }

    private func cellSize(in size: CGSize) -> (width: CGFloat, height: CGFloat) {
        let spacing = cellSpacing
        let height = max(0, (size.height - spacing * CGFloat(max(0, numberOfRows - 1))) / CGFloat(numberOfRows))
        let width: CGFloat
        if isCompact {
            let squareWidth = (size.width - spacing * 6) / 7
            width = max(0, min(squareWidth, height))
        } else {
            let targetGridWidth = size.width * 0.92
            width = max(0, (targetGridWidth - spacing * 6) / 7)
        }
        return (width, height)
    }

    private var calendarSection: some View {
        VStack(alignment: .leading, spacing: isCompact ? 2 : 3) {
            Text(monthLabel)
                .font(.system(size: isCompact ? 11 : 13, weight: .semibold))
                .foregroundStyle(palette.textPrimary)

            GeometryReader { geo in
                let size = cellSize(in: geo.size)
                let columns = Array(repeating: GridItem(.fixed(size.width), spacing: cellSpacing), count: 7)

                LazyVGrid(columns: columns, spacing: cellSpacing) {
                    ForEach(Array(gridSlots.enumerated()), id: \.offset) { _, slot in
                        dayCell(slot, width: size.width, height: size.height)
                    }
                }
            }
        }
    }

    var body: some View {
        Group {
            if isCompact {
                VStack(alignment: .leading, spacing: 2) {
                    calendarSection
                    statLine
                }
            } else {
                HStack(alignment: .top, spacing: 10) {
                    recentExpensesList
                        .frame(maxWidth: .infinity, alignment: .leading)
                    calendarSection
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .containerBackground(for: .widget) {
            palette.background
        }
    }

    private var recentExpensesList: some View {
        VStack(alignment: .leading, spacing: 4) {
            if entry.recentExpenses.isEmpty {
                Text(String(localized: "No expenses yet"))
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(palette.textSecondary)
            } else {
                ForEach(Array(entry.recentExpenses.prefix(3).enumerated()), id: \.offset) { _, expense in
                    expenseRow(expense)
                }
            }
            Spacer(minLength: 0)
        }
    }

    private func expenseRow(_ expense: RecentExpense) -> some View {
        let color = WidgetPalette.categoricalColor(for: expense.categoryName, dark: colorScheme == .dark)

        return HStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 1.5)
                .fill(color)
                .frame(width: 3)

            VStack(alignment: .leading, spacing: 1) {
                Text("\(expense.categoryName) (\(formattedAmount(expense.amount)))")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(palette.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Text(Self.expenseDateFormatter.string(from: expense.date))
                    .font(.system(size: 8, weight: .semibold))
                    .foregroundStyle(palette.textSecondary)
                    .textCase(.uppercase)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 6)
        .background(color.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
    }

    private func formattedAmount(_ amount: Double) -> String {
        "\(entry.currencySymbol)\(Self.expenseAmountFormatter.string(from: NSNumber(value: amount)) ?? "0.00")"
    }

    private static let expenseDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        formatter.locale = Locale.autoupdatingCurrent
        return formatter
    }()

    private static let expenseAmountFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter
    }()

    private var expenseCountUnitLabel: String {
        entry.expenseCount == 1 ? String(localized: "expense") : String(localized: "expenses")
    }

    private var statLine: some View {
        HStack {
            Spacer()
            Text("\(entry.expenseCount)")
                .font(.system(size: isCompact ? 11 : 13, weight: .bold))
                .foregroundStyle(WidgetPalette.accent)
            + Text(" \(expenseCountUnitLabel)")
                .font(.system(size: isCompact ? 9 : 11, weight: .regular))
                .foregroundStyle(palette.textSecondary)
        }
    }

    @ViewBuilder
    private func dayCell(_ slot: GridSlot, width: CGFloat, height: CGFloat) -> some View {
        switch slot {
        case .blank:
            Color.clear
                .frame(width: width, height: height)

        case .dimmed:
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(Color.clear)
                .frame(width: width, height: height)
                .overlay(
                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                        .stroke(palette.textSecondary.opacity(0.2), lineWidth: 1)
                )

        case .real(let day):
            let amount = entry.dailyAmounts[day]
            let isToday = Self.calendar.isDateInToday(day)

            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(fillColor(for: amount))
                .frame(width: width, height: height)
                .overlay(
                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                        .stroke(isToday ? palette.textPrimary : palette.textSecondary.opacity(0.2), lineWidth: isToday ? 1.5 : 1)
                )
        }
    }

    private func fillColor(for amount: Double?) -> Color {
        guard let amount, amount > 0, maxDailyAmount > 0 else { return palette.background }
        return .spendingHeat(amount / maxDailyAmount)
    }
}

struct MonthlySpendingCompactWidget: Widget {
    let kind: String = "MonthlySpendingCompact"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MonthlySpendingCompactProvider()) { entry in
            MonthlySpendingCompactEntryView(entry: entry)
        }
        .configurationDisplayName(String(localized: "This Month"))
        .description(String(localized: "This month's spending heatmap with your expense count."))
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

#Preview(as: .systemSmall) {
    MonthlySpendingCompactWidget()
} timeline: {
    MonthlySpendingCompactEntry.sample
}
