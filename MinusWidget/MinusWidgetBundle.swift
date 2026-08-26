//
//  MinusWidgetBundle.swift
//  MinusWidget
//
//  Created by Isaac Emmanuel Serrano Altamirano on 26/08/26.
//

import WidgetKit
import SwiftUI

@main
struct MinusWidgetBundle: WidgetBundle {
    var body: some Widget {
        BudgetOverviewWidget()
        SpendingHeatmapWidget()
        MonthlySpendingCompactWidget()
        DaysCountdownWidget()
        MinusWidgetControl()
        MinusWidgetLiveActivity()
    }
}

#Preview("Budget Overview", as: .systemMedium) {
    BudgetOverviewWidget()
} timeline: {
    BudgetOverviewEntry.sample
}

#Preview("Days Remaining", as: .systemSmall) {
    DaysCountdownWidget()
} timeline: {
    DaysCountdownEntry.sample
}

#Preview("Spending Calendar", as: .systemLarge) {
    SpendingHeatmapWidget()
} timeline: {
    SpendingHeatmapEntry.sample
}

#Preview("This Month (Small)", as: .systemSmall) {
    MonthlySpendingCompactWidget()
} timeline: {
    MonthlySpendingCompactEntry.sample
}

#Preview("This Month (Medium)", as: .systemMedium) {
    MonthlySpendingCompactWidget()
} timeline: {
    MonthlySpendingCompactEntry.sample
}
