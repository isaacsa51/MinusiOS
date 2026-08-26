//
//  SpendingHeatmapSnapshotStore.swift
//  MinusWidget
//

import Foundation

struct SpendingHeatmapDayStat {
    let amount: Double
    let count: Int
}

struct RecentExpense {
    let categoryName: String
    let amount: Double
    let date: Date
}

struct SpendingHeatmapData {
    let periodStartDate: Date
    let periodEndDate: Date
    let currencySymbol: String
    let dailyStats: [Date: SpendingHeatmapDayStat]
    let recentExpenses: [RecentExpense]
}

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

enum SpendingHeatmapSnapshotStore {
    private static let suiteName = "group.com.serranoie.ios.minus"
    private static let key = "spendingHeatmapSnapshot"

    static func read() -> SpendingHeatmapData? {
        guard let defaults = UserDefaults(suiteName: suiteName),
              let data = defaults.data(forKey: key),
              let snapshot = try? JSONDecoder().decode(SpendingHeatmapSnapshot.self, from: data) else {
            return nil
        }

        let calendar = Calendar.current
        let dailyStats = Dictionary(uniqueKeysWithValues: snapshot.dailyTotals.map {
            (calendar.startOfDay(for: $0.date), SpendingHeatmapDayStat(amount: $0.amount, count: $0.count))
        })
        return SpendingHeatmapData(
            periodStartDate: snapshot.periodStartDate,
            periodEndDate: snapshot.periodEndDate,
            currencySymbol: snapshot.currencySymbol,
            dailyStats: dailyStats,
            recentExpenses: snapshot.recentExpenses.map {
                RecentExpense(categoryName: $0.categoryName, amount: $0.amount, date: $0.date)
            }
        )
    }
}
