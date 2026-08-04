//
//  CarryOverInfoBanner.swift
//  minus
//

import SwiftUI

struct CarryOverInfoBanner: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "info.circle.fill")
                .font(.system(size: 15))
                .foregroundStyle(Color.minus.primaryAction)

            Text(text)
                .font(.system(size: 13))
                .foregroundStyle(Color.minus.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
        .padding(12)
        .background(Color.minus.primaryAction.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

#Preview("Pill + Carry Over") {
    ScrollView {
        VStack(alignment: .leading, spacing: 24) {
            carryOverExample(
                caption: "Spread across all days",
                pillTitle: "For today",
                pillAmount: "$120.00",
                pillColor: Color.minus.success,
                progress: 0.3,
                bannerText: "You have $500 left unspent. When this period ends, it will be spread across every day of your next budget."
            )

            carryOverExample(
                caption: "Add to first day",
                pillTitle: "For today",
                pillAmount: "$620.00",
                pillColor: Color.minus.success,
                progress: 0.15,
                bannerText: "You have $500 left unspent. When this period ends, it will be added to the first day of your next budget."
            )

            carryOverExample(
                caption: "Ask always",
                pillTitle: "For today",
                pillAmount: "$120.00",
                pillColor: .yellow,
                progress: 0.5,
                bannerText: "You have $500 left unspent. You'll be asked whether to add or discard it when you create your next budget."
            )
        }
        .padding()
    }
}

@ViewBuilder
private func carryOverExample(
    caption: String,
    pillTitle: String,
    pillAmount: String,
    pillColor: Color,
    progress: Double,
    isExceeded: Bool = false,
    bannerText: String
) -> some View {
    VStack(alignment: .leading, spacing: 10) {
        Text(caption)
            .font(.caption)
            .foregroundStyle(Color.minus.textSecondary)

        BudgetPillView(
            title: pillTitle,
            amount: pillAmount,
            pillColor: pillColor,
            progress: progress,
            isExceeded: isExceeded
        )

        CarryOverInfoBanner(text: bannerText)
    }
}
