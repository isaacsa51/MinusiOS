//
//  SpendingHeatmapSnapshotWriter.swift
//  minus
//

import Foundation
import WidgetKit

private struct SpendingHeatmapDaySnapshot: Codable {
    let date: Date
    let amount: Double
    let count: Int
}

private struct RecentExpenseSnapshot: Codable {
    let categoryName: String
    let amount: Double
    let date: Date
}

private struct SpendingHeatmapSnapshot: Codable {
    let periodStartDate: Date
    let periodEndDate: Date
    let currencySymbol: String
    let dailyTotals: [SpendingHeatmapDaySnapshot]
    let recentExpenses: [RecentExpenseSnapshot]
}

enum SpendingHeatmapSnapshotWriter {
    private static let suiteName = "group.com.serranoie.ios.minus"
    private static let key = "spendingHeatmapSnapshot"
    private static let recentExpenseLimit = 5

    static func refresh(period: PeriodKey?, expenses: [Transaction]) {
        guard let defaults = UserDefaults(suiteName: suiteName) else { return }

        guard let period else {
            defaults.removeObject(forKey: key)
            WidgetCenter.shared.reloadTimelines(ofKind: "SpendingHeatmap")
            WidgetCenter.shared.reloadTimelines(ofKind: "MonthlySpendingCompact")
            return
        }

        let nonIncome = expenses.filter { !$0.isIncome }

        let calendar = Calendar.current
        let grouped = Dictionary(grouping: nonIncome) { calendar.startOfDay(for: $0.createdAt) }
        let dailyTotals = grouped
            .map { date, txs in
                SpendingHeatmapDaySnapshot(
                    date: date,
                    amount: NSDecimalNumber(decimal: txs.reduce(Decimal.zero) { $0 + $1.amount }).doubleValue,
                    count: txs.count
                )
            }
            .sorted { $0.date < $1.date }

        let recentExpenses = nonIncome
            .sorted { $0.createdAt > $1.createdAt }
            .prefix(recentExpenseLimit)
            .map {
                RecentExpenseSnapshot(
                    categoryName: $0.categoryName?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
                        ? $0.categoryName!
                        : String(localized: "Uncategorized"),
                    amount: NSDecimalNumber(decimal: $0.amount).doubleValue,
                    date: $0.createdAt
                )
            }

        let snapshot = SpendingHeatmapSnapshot(
            periodStartDate: period.startDate,
            periodEndDate: period.effectiveEndDate,
            currencySymbol: Currency.find(byCode: period.currency)?.symbol ?? "$",
            dailyTotals: dailyTotals,
            recentExpenses: recentExpenses
        )

        if let data = try? JSONEncoder().encode(snapshot) {
            defaults.set(data, forKey: key)
        }
        WidgetCenter.shared.reloadTimelines(ofKind: "SpendingHeatmap")
        WidgetCenter.shared.reloadTimelines(ofKind: "MonthlySpendingCompact")
    }
}
