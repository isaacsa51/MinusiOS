//
//  SpendingHeatmapWidget.swift
//  MinusWidget
//

import WidgetKit
import SwiftUI

struct SpendingHeatmapEntry: TimelineEntry {
    let date: Date
    let periodStartDate: Date
    let periodEndDate: Date
    let dailyAmounts: [Date: Double]
}

struct SpendingHeatmapProvider: TimelineProvider {
    func placeholder(in context: Context) -> SpendingHeatmapEntry {
        .sample
    }

    func getSnapshot(in context: Context, completion: @escaping (SpendingHeatmapEntry) -> Void) {
        completion(context.isPreview ? .sample : currentEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SpendingHeatmapEntry>) -> Void) {
        let nextReload = Calendar.current.date(byAdding: .hour, value: 1, to: .now) ?? .now
        completion(Timeline(entries: [currentEntry()], policy: .after(nextReload)))
    }

    private func currentEntry() -> SpendingHeatmapEntry {
        guard let data = SpendingHeatmapSnapshotStore.read() else { return .empty }
        return SpendingHeatmapEntry(
            date: .now,
            periodStartDate: data.periodStartDate,
            periodEndDate: data.periodEndDate,
            dailyAmounts: data.dailyStats.mapValues(\.amount)
        )
    }
}

extension SpendingHeatmapEntry {
    static var sample: SpendingHeatmapEntry {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let start = calendar.date(byAdding: .day, value: -9, to: today) ?? today
        let end = calendar.date(byAdding: .day, value: 20, to: start) ?? today

        var amounts: [Date: Double] = [:]
        for offset in 0..<10 where offset % 3 != 0 {
            let day = calendar.date(byAdding: .day, value: offset, to: start) ?? start
            amounts[day] = Double.random(in: 5...200)
        }

        return SpendingHeatmapEntry(date: .now, periodStartDate: start, periodEndDate: end, dailyAmounts: amounts)
    }

    fileprivate static var empty: SpendingHeatmapEntry {
        let today = Calendar.current.startOfDay(for: .now)
        return SpendingHeatmapEntry(date: .now, periodStartDate: today, periodEndDate: today, dailyAmounts: [:])
    }
}

struct SpendingHeatmapEntryView: View {
    var entry: SpendingHeatmapProvider.Entry
    @Environment(\.colorScheme) private var colorScheme

    private var palette: WidgetPalette { colorScheme == .dark ? .dark : .light }

    private static var calendar: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.locale = Locale.autoupdatingCurrent
        return cal
    }()

    // Reordered from Calendar's fixed Sun...Sat order to match firstWeekday,
    // and translated per the device locale — a hardcoded English S/M/T/W/T/F/S
    // would be both wrong-order and wrong-language for most non-US locales.
    private static var weekdaySymbols: [String] {
        let symbols = calendar.veryShortWeekdaySymbols
        let offset = calendar.firstWeekday - 1
        return Array(symbols[offset...] + symbols[..<offset])
    }

    private static let monthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        formatter.locale = Locale.autoupdatingCurrent
        return formatter
    }()

    private var periodStart: Date { Self.calendar.startOfDay(for: entry.periodStartDate) }
    private var periodEnd: Date { Self.calendar.startOfDay(for: entry.periodEndDate) }

    private var maxDailyAmount: Double {
        entry.dailyAmounts.values.max() ?? 0
    }

    private enum GridSlot {
        case blank
        case dimmed(Date)
        case real(Date)
    }

    private struct MonthSection {
        let label: String
        let slots: [GridSlot]
        var rowCount: Int { max(1, Int((Double(slots.count) / 7.0).rounded(.up))) }
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

            sections.append(MonthSection(label: Self.monthFormatter.string(from: firstOfMonth), slots: slots))

            guard let nextMonth = cal.date(byAdding: .month, value: 1, to: monthCursor) else { break }
            monthCursor = nextMonth
        }

        return sections
    }

    var body: some View {
        let sections = monthSections
        let rowSpacing: CGFloat = 4
        let interSectionSpacing: CGFloat = 8
        let labelHeight: CGFloat = 16
        let labelSpacing: CGFloat = 4
        let headerHeight: CGFloat = 12
        let headerSpacing: CGFloat = 4
        let totalRows = sections.reduce(0) { $0 + $1.rowCount }
        let overheadPerSection = labelHeight + labelSpacing + headerHeight + headerSpacing

        GeometryReader { geo in
            let totalFixedOverhead = CGFloat(sections.count) * overheadPerSection
                + CGFloat(max(0, sections.count - 1)) * interSectionSpacing
            let totalRowSpacing = CGFloat(max(0, totalRows - sections.count)) * rowSpacing
            let cellWidth = (geo.size.width - rowSpacing * 6) / 7
            let cellHeight = totalRows > 0
                ? (geo.size.height - totalFixedOverhead - totalRowSpacing) / CGFloat(totalRows)
                : cellWidth
            let cellSize = max(0, min(cellWidth, cellHeight))
            let columns = Array(repeating: GridItem(.fixed(cellSize), spacing: rowSpacing), count: 7)

            VStack(alignment: .leading, spacing: interSectionSpacing) {
                ForEach(Array(sections.enumerated()), id: \.offset) { _, section in
                    VStack(alignment: .leading, spacing: 0) {
                        Text(section.label)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(palette.textPrimary)
                            .frame(height: labelHeight, alignment: .leading)
                            .padding(.bottom, labelSpacing)

                        LazyVGrid(columns: columns, spacing: rowSpacing) {
                            ForEach(Array(Self.weekdaySymbols.enumerated()), id: \.offset) { _, symbol in
                                Text(symbol)
                                    .font(.system(size: 9, weight: .medium))
                                    .foregroundStyle(palette.textSecondary)
                                    .frame(height: headerHeight)
                            }
                        }
                        .padding(.bottom, headerSpacing)

                        LazyVGrid(columns: columns, spacing: rowSpacing) {
                            ForEach(Array(section.slots.enumerated()), id: \.offset) { _, slot in
                                dayCell(slot, size: cellSize)
                            }
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(16)
        .containerBackground(for: .widget) {
            palette.background
        }
    }

    @ViewBuilder
    private func dayCell(_ slot: GridSlot, size: CGFloat) -> some View {
        let fontSize = min(8, size * 0.35)

        switch slot {
        case .blank:
            Color.clear
                .frame(width: size, height: size)

        case .dimmed(let day):
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(Color.clear)
                .frame(width: size, height: size)
                .overlay(
                    Text("\(Self.calendar.component(.day, from: day))")
                        .font(.system(size: fontSize, weight: .medium))
                        .italic()
                        .foregroundStyle(palette.textSecondary.opacity(0.6))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .stroke(palette.textSecondary.opacity(0.25), lineWidth: 1)
                )

        case .real(let day):
            let amount = entry.dailyAmounts[day]
            let isToday = Self.calendar.isDateInToday(day)
            let isHottestDay = maxDailyAmount > 0 && amount == maxDailyAmount

            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(fillColor(for: amount))
                .frame(width: size, height: size)
                .overlay(
                    Text("\(Self.calendar.component(.day, from: day))")
                        .font(.system(size: fontSize, weight: .medium))
                        .foregroundStyle(labelColor(for: amount))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .stroke(isToday ? palette.textPrimary : palette.textSecondary.opacity(0.25), lineWidth: isToday ? 1.5 : 1)
                )
                .scaleEffect(isHottestDay ? 1.15 : 1)
                .zIndex(isHottestDay ? 1 : 0)
        }
    }

    private func fillColor(for amount: Double?) -> Color {
        guard let amount, maxDailyAmount > 0 else { return palette.background }
        return .spendingHeat(amount / maxDailyAmount)
    }

    private func labelColor(for amount: Double?) -> Color {
        amount == nil ? palette.textSecondary : .white
    }
}

struct SpendingHeatmapWidget: Widget {
    let kind: String = "SpendingHeatmap"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SpendingHeatmapProvider()) { entry in
            SpendingHeatmapEntryView(entry: entry)
        }
        .configurationDisplayName(String(localized: "Spending Calendar"))
        .description(String(localized: "A heatmap of daily spending for your active budget period."))
        .supportedFamilies([.systemLarge])
    }
}

#Preview(as: .systemLarge) {
    SpendingHeatmapWidget()
} timeline: {
    SpendingHeatmapEntry.sample
}
