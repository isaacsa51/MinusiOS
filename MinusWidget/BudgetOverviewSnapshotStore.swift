//
//  BudgetOverviewSnapshotStore.swift
//  MinusWidget
//

import Foundation

struct BudgetOverviewData {
    let totalBudget: Double
    let currencySymbol: String
    let startDate: Date
    let endDate: Date
}

private struct BudgetOverviewSnapshot: Codable {
    let totalBudget: Double
    let currencySymbol: String
    let startDate: Date
    let endDate: Date
}

enum BudgetOverviewSnapshotStore {
    private static let suiteName = "group.com.serranoie.ios.minus"
    private static let key = "budgetOverviewSnapshot"

    static func read() -> BudgetOverviewData? {
        guard let defaults = UserDefaults(suiteName: suiteName),
              let data = defaults.data(forKey: key),
              let snapshot = try? JSONDecoder().decode(BudgetOverviewSnapshot.self, from: data) else {
            return nil
        }
        return BudgetOverviewData(
            totalBudget: snapshot.totalBudget,
            currencySymbol: snapshot.currencySymbol,
            startDate: snapshot.startDate,
            endDate: snapshot.endDate
        )
    }
}
