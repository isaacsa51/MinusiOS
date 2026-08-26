//
//  AnalyticsViewModel+CategoriesGraph.swift
//  minus
//

import Foundation

extension AnalyticsViewModel {
    enum TimeRangeMode: String, CaseIterable {
        case day = "Días"
        case week = "Semana"
        case biweek = "Quincena"
        case total = "Total"

        var windowDays: Int {
            switch self {
            case .day: return 1
            case .week: return 7
            case .biweek: return 14
            case .total: return 0
            }
        }
    }

    struct CategoryStackedBucket: Identifiable {
        var id: Date { date }
        let date: Date
        let amountsByCategory: [String: Double]
    }

    struct CategoriesGraphData {
        let buckets: [CategoryStackedBucket]
        let axisUnit: Calendar.Component
        let xDomain: ClosedRange<Date>
        let today: Date?
    }

    struct TimeRangeNavigatorData {
        let label: String
        let pageCount: Int
    }

    var categoryOrder: [String] {
        analytics.categoryBreakdown.map(\.name)
    }

    func categoriesGraphData(mode: TimeRangeMode, pageIndex: Int, period: PeriodKey) -> CategoriesGraphData {
        let window = windowBounds(for: mode, pageIndex: pageIndex, period: period)
        let axisUnit: Calendar.Component = mode == .day ? .hour : .day

        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: Date())
        let today: Date? = mode == .day
            ? nil
            : (todayStart >= window.start && todayStart < window.end ? todayStart : nil)

        return CategoriesGraphData(
            buckets: categoryStackedBuckets(from: window.start, until: window.end, unit: axisUnit),
            axisUnit: axisUnit,
            xDomain: window.start...window.end,
            today: today
        )
    }

    func timeRangeNavigatorData(mode: TimeRangeMode, pageIndex: Int, period: PeriodKey) -> TimeRangeNavigatorData {
        let count = pageCount(for: mode, period: period)
        let window = windowBounds(for: mode, pageIndex: pageIndex, period: period)
        let lastIncludedDay = Calendar.current.date(byAdding: .day, value: -1, to: window.end) ?? window.start
        let label = mode == .day
            ? dayNavigatorLabel(for: window.start)
            : rangeNavigatorLabel(from: window.start, to: lastIncludedDay)
        return TimeRangeNavigatorData(label: label, pageCount: count)
    }

    func defaultPageIndex(for mode: TimeRangeMode, period: PeriodKey) -> Int {
        guard mode != .total else { return 0 }
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: period.startDate)
        let today = calendar.startOfDay(for: Date())
        let daysSinceStart = calendar.dateComponents([.day], from: start, to: today).day ?? 0
        guard daysSinceStart >= 0 else { return 0 }

        let count = pageCount(for: mode, period: period)
        return min(daysSinceStart / mode.windowDays, count - 1)
    }

    func categoryStackedBuckets(from start: Date, until end: Date, unit: Calendar.Component) -> [CategoryStackedBucket] {
        let calendar = Calendar.current
        let knownNames = Set(categoryOrder)
        let inRange = analytics.expenses.filter { $0.createdAt >= start && $0.createdAt < end }
        let grouped = Dictionary(grouping: inRange) { tx -> Date in
            unit == .hour
                ? calendar.date(from: calendar.dateComponents([.year, .month, .day, .hour], from: tx.createdAt)) ?? tx.createdAt
                : calendar.startOfDay(for: tx.createdAt)
        }

        return grouped.map { bucketDate, txs in
            var amounts: [String: Double] = [:]
            for tx in txs {
                let trimmed = tx.categoryName?.trimmingCharacters(in: .whitespacesAndNewlines)
                let name = (trimmed?.isEmpty == false ? trimmed! : nil) ?? String(localized: "Uncategorized")
                let resolved = knownNames.contains(name) ? name : String(localized: "Other")
                amounts[resolved, default: 0] += NSDecimalNumber(decimal: tx.amount).doubleValue
            }
            return CategoryStackedBucket(date: bucketDate, amountsByCategory: amounts)
        }
        .sorted { $0.date < $1.date }
    }

    func dayNavigatorLabel(for date: Date) -> String {
        let day = Calendar.current.component(.day, from: date)
        let ordinalDay = Self.ordinalFormatter.string(from: NSNumber(value: day)) ?? "\(day)"
        return "\(Self.weekdayMonthFormatter.string(from: date)) \(ordinalDay)"
    }

    func rangeNavigatorLabel(from start: Date, to end: Date) -> String {
        "\(Self.shortDayFormatter.string(from: start)) – \(Self.shortDayFormatter.string(from: end))"
    }

    private func totalPeriodDays(_ period: PeriodKey) -> Int {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: period.startDate)
        let end = calendar.startOfDay(for: period.effectiveEndDate)
        return max(1, (calendar.dateComponents([.day], from: start, to: end).day ?? 0) + 1)
    }

    private func pageCount(for mode: TimeRangeMode, period: PeriodKey) -> Int {
        guard mode != .total else { return 1 }
        let totalDays = totalPeriodDays(period)
        return max(1, Int(ceil(Double(totalDays) / Double(mode.windowDays))))
    }

    private func windowBounds(for mode: TimeRangeMode, pageIndex: Int, period: PeriodKey) -> (start: Date, end: Date) {
        let calendar = Calendar.current
        let periodStart = calendar.startOfDay(for: period.startDate)
        let periodEndExclusive = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: period.effectiveEndDate)) ?? periodStart

        guard mode != .total else { return (periodStart, periodEndExclusive) }

        let windowStart = calendar.date(byAdding: .day, value: pageIndex * mode.windowDays, to: periodStart) ?? periodStart
        let windowEnd = min(
            calendar.date(byAdding: .day, value: mode.windowDays, to: windowStart) ?? windowStart,
            periodEndExclusive
        )
        return (windowStart, windowEnd)
    }

    private static let weekdayMonthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM"
        formatter.locale = Locale(identifier: "en_US")
        return formatter
    }()

    private static let shortDayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        formatter.locale = Locale(identifier: "en_US")
        return formatter
    }()

    private static let ordinalFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .ordinal
        formatter.locale = Locale(identifier: "en_US")
        return formatter
    }()
}
