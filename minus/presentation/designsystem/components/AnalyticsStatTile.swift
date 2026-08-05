//
//  AnalyticsStatTile.swift
//  minus
//

import SwiftUI
import SwiftThemeKit

struct AnalyticsStatTile: View {
    @Environment(\.appTheme) private var theme

    let title: String
    let value: String
    var subtitle: String? = nil
    var categoryLabel: String? = nil
    var trendValues: [Double] = []
    var highlightIndex: Int? = nil
    var markerAnchor: TrendGraphBackground.MarkerAnchor = .end
    var tint: Color = Color.minus.primaryAction

    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: theme.radii.xl, style: .continuous)
                .fill(tint.opacity(0.14))

            if !trendValues.isEmpty, highlightIndex != nil {
                TrendGraphBackground(
                    values: trendValues,
                    highlightIndex: highlightIndex,
                    anchor: markerAnchor,
                    tint: tint
                )
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.displaySmall)
                    .foregroundStyle(Color.minus.textPrimary)
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)

                Text(title)
                    .font(.labelMedium)
                    .foregroundStyle(Color.minus.textSecondary)

                if let subtitle {
                    Text(subtitle)
                        .font(.labelSmall)
                        .foregroundStyle(Color.minus.textSecondary)
                        .lineLimit(1)
                        .padding(.top, .xs)
                }

                if let categoryLabel {
                    Label(categoryLabel, systemImage: "tag.fill")
                        .font(.labelSmall)
                        .foregroundStyle(Color.minus.textSecondary)
                        .lineLimit(1)
                }
            }
            .padding(.lg)
        }
        .frame(minHeight: 140)
        .clipRadius(.xl, style: .continuous)
    }
}

#Preview {
    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
        AnalyticsStatTile(
            title: "Highest Day",
            value: "$340.00",
            subtitle: "Sat, Aug 1",
            trendValues: [40, 90, 60, 120, 340, 80, 55],
            highlightIndex: 4,
            markerAnchor: .end,
            tint: .spendingHeat(1)
        )
        AnalyticsStatTile(
            title: "Lowest Day",
            value: "$12.00",
            subtitle: "Tue, Jul 28",
            trendValues: [40, 90, 60, 12, 340, 80, 55],
            highlightIndex: 3,
            markerAnchor: .start,
            tint: .spendingHeat(0)
        )
        AnalyticsStatTile(
            title: "Largest Expense",
            value: "$200.00",
            subtitle: "25 Jun 3:30 PM",
            categoryLabel: "Rent",
            trendValues: [4, 10, 200, 8, 22, 6],
            highlightIndex: 2,
            markerAnchor: .end,
            tint: .spendingHeat(1)
        )
        AnalyticsStatTile(
            title: "Smallest Expense",
            value: "$4.50",
            subtitle: "25 Jun 3:30 PM",
            categoryLabel: "Morning coffee",
            trendValues: [4.5, 10, 200, 8, 22, 6],
            highlightIndex: 0,
            markerAnchor: .start,
            tint: .spendingHeat(0)
        )
    }
    .padding()
    .background(Color.minus.background)
}
