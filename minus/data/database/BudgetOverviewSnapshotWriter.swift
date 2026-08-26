//
//  BudgetOverviewSnapshotWriter.swift
//  minus
//

import Foundation
import WidgetKit

struct BudgetOverviewSnapshot: Codable {
    let totalBudget: Double
    let currencySymbol: String
    let startDate: Date
    let endDate: Date
}

enum BudgetOverviewSnapshotWriter {
    private static let suiteName = "group.com.serranoie.ios.minus"
    private static let key = "budgetOverviewSnapshot"

    static func write(_ period: PeriodKey?) {
        guard let defaults = UserDefaults(suiteName: suiteName) else { return }

        guard let period else {
            defaults.removeObject(forKey: key)
            return
        }

        let symbol = Currency.find(byCode: period.currency)?.symbol ?? "$"
        let snapshot = BudgetOverviewSnapshot(
            totalBudget: NSDecimalNumber(decimal: period.totalBudget).doubleValue,
            currencySymbol: symbol,
            startDate: period.startDate,
            endDate: period.effectiveEndDate
        )

        if let data = try? JSONEncoder().encode(snapshot) {
            defaults.set(data, forKey: key)
        }
    }

    static func refresh(activePeriod: PeriodKey?) {
        write(activePeriod)
        WidgetCenter.shared.reloadTimelines(ofKind: "BudgetOverview")
    }
}
