//
//  PeriodSpendingCard.swift
//  minus
//

import SwiftUI

struct PeriodSpendingCard: View {
    var spentAmount: String = "$450.00"
    var totalAmount: String = "$15,000"
    var availablePercentage: Int = 70
    var availableColor: Color = Color.minus.success

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(String(localized: "Spent"))
                    .font(.subheadline)
                    .foregroundStyle(Color.minus.textSecondary)

                (
                    Text(spentAmount)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.minus.textPrimary)
                    + Text(" / \(totalAmount)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.minus.textSecondary)
                )
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            }

            Spacer(minLength: 12)

            VStack(alignment: .trailing, spacing: 6) {
                Text(String(localized: "Available"))
                    .font(.subheadline)
                    .foregroundStyle(Color.minus.textSecondary)

                Text("\(availablePercentage)%")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(availableColor)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.minus.surface)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

#Preview {
    VStack(spacing: 12) {
        PeriodSpendingCard(spentAmount: "$0.00", totalAmount: "$15,000", availablePercentage: 100, availableColor: Color.minus.success)
        PeriodSpendingCard(spentAmount: "$1,200.00", totalAmount: "$3,000", availablePercentage: 35, availableColor: .yellow)
        PeriodSpendingCard(spentAmount: "$2,000.00", totalAmount: "$2,000", availablePercentage: 0, availableColor: .red)
    }
    .padding()
    .background(Color.minus.background)
}
