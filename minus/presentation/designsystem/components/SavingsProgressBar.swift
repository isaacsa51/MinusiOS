//
//  SavingsProgressBar.swift
//  minus
//

import SwiftUI

struct SavingsProgressBar: View {
    let achievementRatio: Double
    let goalMet: Bool
    var spendingZoneFraction: CGFloat = 0.8

    var body: some View {
        GeometryReader { geo in
            let markerX = geo.size.width * CGFloat(min(max(achievementRatio, 0), 1))

            ZStack(alignment: .leading) {
                HStack(spacing: 3) {
                    Capsule()
                        .fill(Color.minus.primaryAction)
                        .frame(width: geo.size.width * spendingZoneFraction)

                    Capsule()
                        .fill(goalMet ? Color.spendingHeat(0) : Color.spendingHeat(1))
                        .frame(width: geo.size.width * (1 - spendingZoneFraction))
                }

                Circle()
                    .fill(Color.minus.background)
                    .overlay(Circle().stroke(Color.minus.textSecondary, lineWidth: 2))
                    .frame(width: 14, height: 14)
                    .position(x: markerX, y: geo.size.height / 2)
            }
        }
        .frame(height: 10)
    }
}

#Preview {
    VStack(spacing: 24) {
        SavingsProgressBar(achievementRatio: 0, goalMet: false)
        SavingsProgressBar(achievementRatio: 0.5, goalMet: false)
        SavingsProgressBar(achievementRatio: 1.2, goalMet: true)
    }
    .padding()
    .background(Color.minus.background)
}
