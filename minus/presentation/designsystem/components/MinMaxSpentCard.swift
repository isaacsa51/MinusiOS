//
//  MinMaxSpentCard.swift
//  minus
//

import SwiftUI
import SwiftThemeKit

struct MinMaxSpentCard: View {
    @Environment(\.appTheme) private var theme

    let title: String
    let value: String
    var subtitle: String? = nil
    var categoryLabel: String? = nil
    var trendValues: [Double] = []
    var highlightIndex: Int? = nil
    var tint: Color = Color.minus.primaryAction
    var textGradientEdge: TrendGraphBackground.GradientEdge? = nil

    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: theme.radii.xl, style: .continuous)
                .fill(tint.opacity(0.14))

            if !trendValues.isEmpty, highlightIndex != nil {
                TrendGraphBackground(
                    values: trendValues,
                    highlightIndex: highlightIndex,
                    tint: tint,
                    textGradientEdge: textGradientEdge
                )
            }

            VStack(alignment: .leading, spacing: 1) {
                Text(value)
                    .font(.displaySmall)
                    .foregroundStyle(Color.minus.textPrimary)
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)

                Text(title)
                    .font(.labelMedium)
                    .foregroundStyle(Color.minus.textSecondary)

                if let subtitle {
                    Label(subtitle, systemImage: "calendar")
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
            .padding(.vertical, .lg)
            .padding(.horizontal, .md)
        }
        .frame(minHeight: 140)
        .clipRadius(.xl, style: .continuous)
    }
}

#Preview {
    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
        MinMaxSpentCard(
            title: "Highest Day",
            value: "$340.00",
            subtitle: "01 August",
            trendValues: [40, 90, 60, 120, 340, 80, 55],
            highlightIndex: 4,
            tint: .spendingHeat(1)
        )
        MinMaxSpentCard(
            title: "Lowest Day",
            value: "$12.00",
            subtitle: "28 July",
            trendValues: [40, 90, 60, 12, 340, 80, 55],
            highlightIndex: 3,
            tint: .spendingHeat(0)
        )
        MinMaxSpentCard(
            title: "Largest Expense",
            value: "$200.00",
            subtitle: "12 August",
            categoryLabel: "Rent",
            trendValues: [4, 10, 200, 8, 22, 6],
            highlightIndex: 2,
            tint: .spendingHeat(1),
            textGradientEdge: .bottom
        )
        MinMaxSpentCard(
            title: "Smallest Expense",
            value: "$4.50",
            subtitle: "06 July",
            categoryLabel: "Morning coffee",
            trendValues: [4.5, 10, 200, 8, 22, 6],
            highlightIndex: 0,
            tint: .spendingHeat(0),
            textGradientEdge: .top
        )
    }
    .padding()
    .background(Color.minus.background)
}
