//
//  CategoryBreakdownRow.swift
//  minus
//

import SwiftUI

struct CategoryBreakdownRow: View {
    let name: String
    let amount: String
    let percentageLabel: String
    let fraction: Double
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)

                Text(name)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.minus.textPrimary)
                    .lineLimit(1)

                Spacer(minLength: 8)

                Text(percentageLabel)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.minus.textSecondary)

                Text(amount)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.minus.textPrimary)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.minus.divider)
                    Capsule()
                        .fill(color)
                        .frame(width: geo.size.width * max(0.02, min(1, fraction)))
                }
            }
            .frame(height: 8)
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        CategoryBreakdownRow(name: "Groceries", amount: "$340.00", percentageLabel: "38%", fraction: 0.38, color: .categorical(at: 0))
        CategoryBreakdownRow(name: "Transport", amount: "$210.00", percentageLabel: "23%", fraction: 0.23, color: .categorical(at: 1))
        CategoryBreakdownRow(name: "Entertainment", amount: "$120.00", percentageLabel: "13%", fraction: 0.13, color: .categorical(at: 2))
        CategoryBreakdownRow(name: "Other", amount: "$90.00", percentageLabel: "10%", fraction: 0.10, color: .categorical(at: 7))
    }
    .padding()
    .background(Color.minus.background)
}
