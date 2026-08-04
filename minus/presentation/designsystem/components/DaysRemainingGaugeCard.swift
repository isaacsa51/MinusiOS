//
//  DaysRemainingGaugeCard.swift
//  minus
//

import SwiftUI

struct DaysRemainingGaugeCard: View {
    let period: PeriodKey?

    private var daysRemaining: Int {
        guard let p = period else { return 0 }
        return max(0, Calendar.current.dateComponents([.day], from: Date(), to: p.effectiveEndDate).day ?? 0)
    }

    private var totalDays: Int {
        guard let p = period else { return 1 }
        return max(1, Calendar.current.dateComponents([.day], from: p.startDate, to: p.effectiveEndDate).day ?? 1)
    }

    private var progressFraction: CGFloat {
        let remaining = CGFloat(daysRemaining)
        let total = CGFloat(totalDays)
        return total > 0 ? remaining / total : 0
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.minus.divider, lineWidth: 6)
            Circle()
                .trim(from: 0, to: progressFraction)
                .stroke(Color.minus.success, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                .rotationEffect(.degrees(-90))

            VStack(spacing: 0) {
                Text("\(daysRemaining)")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Color.minus.textPrimary)
                Text("days")
                    .font(.system(size: 8, weight: .medium))
                    .textCase(.uppercase)
                    .foregroundStyle(Color.minus.textSecondary)
            }
        }
        .frame(width: 60, height: 60)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(20)
    }
}

#Preview {
    Grid(horizontalSpacing: 12, verticalSpacing: 0) {
        GridRow(alignment: .top) {
            SummaryCardView(period: nil)
                .gridCellColumns(2)
            DaysRemainingGaugeCard(period: nil)
        }
    }
    .padding()
    .background(Color.minus.background)
}
