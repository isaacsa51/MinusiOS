//
//  PeriodSpendingCard.swift
//  minus
//

import SwiftUI

struct PeriodSpendingCard: View {
    var spentAmount: String = "$450.00"
    var progress: Double = 0.3
    var availablePercentage: Int = 70
    var pillColor: Color = Color.minus.primaryAction

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(pillColor.opacity(0.15))

                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(pillColor.opacity(0.35))
                    .frame(width: geo.size.width * min(max(progress, 0), 1))

                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(pillColor.opacity(0.5), lineWidth: 1)

                VStack(alignment: .leading, spacing: 4) {
                    Text(spentAmount)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.minus.textPrimary)

                    Text("Spent")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(Color.minus.textSecondary)

                    Text("Available: \(availablePercentage)%")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.minus.textSecondary)
                }
                .padding(20)
            }
        }
        .frame(height: 130)
        .animation(.easeInOut(duration: 0.3), value: progress)
    }
}

#Preview {
    VStack(spacing: 12) {
        PeriodSpendingCard(spentAmount: "$450.00", progress: 0.3, availablePercentage: 70, pillColor: Color.minus.success)
        PeriodSpendingCard(spentAmount: "$1,200.00", progress: 0.65, availablePercentage: 35, pillColor: .yellow)
        PeriodSpendingCard(spentAmount: "$2,000.00", progress: 1.0, availablePercentage: 0, pillColor: .red)
    }
    .padding()
    .background(Color.minus.background)
}
