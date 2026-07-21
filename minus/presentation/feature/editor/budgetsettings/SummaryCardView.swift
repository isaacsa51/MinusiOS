//
//  SummaryCardView.swift
//  minus
//
//  Created by Isaac Emmanuel Serrano Altamirano on 10/05/26.
//

import SwiftUI

struct SummaryCardView: View {
    let period: PeriodKey?

    private var formattedBudget: String {
        guard let p = period else { return "$0" }
        let symbol = Currency.find(byCode: p.currency)?.symbol ?? "$"
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return "\(symbol)\(formatter.string(from: p.totalBudget as NSDecimalNumber) ?? "0.00")"
    }

    private var startDateText: String {
        guard let p = period else { return "--" }
        return Self.shortDateFormatter.string(from: p.startDate)
    }

    private var endDateText: String {
        guard let p = period else { return "--" }
        let endDate = p.endDate ?? BudgetSettings(
            totalBudget: p.totalBudget,
            period: p.periodType,
            startDate: p.startDate,
            daysInPeriod: p.daysInPeriod
        ).getPeriodEndDate()
        return Self.shortDateFormatter.string(from: endDate)
    }

    private var daysRemaining: Int {
        guard let p = period else { return 0 }
        let endDate = p.endDate ?? BudgetSettings(
            totalBudget: p.totalBudget,
            period: p.periodType,
            startDate: p.startDate,
            daysInPeriod: p.daysInPeriod
        ).getPeriodEndDate()
        return max(0, Calendar.current.dateComponents([.day], from: Date(), to: endDate).day ?? 0)
    }

    private var totalDays: Int {
        guard let p = period else { return 1 }
        let endDate = p.endDate ?? BudgetSettings(
            totalBudget: p.totalBudget,
            period: p.periodType,
            startDate: p.startDate,
            daysInPeriod: p.daysInPeriod
        ).getPeriodEndDate()
        return max(1, Calendar.current.dateComponents([.day], from: p.startDate, to: endDate).day ?? 1)
    }

    private var progressFraction: CGFloat {
        let remaining = CGFloat(daysRemaining)
        let total = CGFloat(totalDays)
        return total > 0 ? remaining / total : 0
    }

    private static let shortDateFormatter: DateFormatter = {
        let fmt = DateFormatter()
        fmt.dateFormat = "d MMM"
        fmt.locale = Locale(identifier: "es_MX")
        return fmt
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("Presupuesto total")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.minus.textSecondary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundStyle(Color.minus.textSecondary.opacity(0.6))
            }

            HStack(alignment: .center, spacing: 0) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(formattedBudget)
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .minimumScaleFactor(0.8)
                        .lineLimit(1)
                        .foregroundStyle(Color.minus.textPrimary)

                    HStack(spacing: 4) {
                        Text(startDateText)
                        Image(systemName: "arrow.right")
                            .font(.system(size: 10))
                        Text(endDateText)
                    }
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.minus.textSecondary)
                }

                Spacer()

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
                        Text("días")
                            .font(.system(size: 8, weight: .medium))
                            .textCase(.uppercase)
                            .foregroundStyle(Color.minus.textSecondary)
                    }
                }
                .frame(width: 60, height: 60)
            }
        }
        .padding(20)
        .background(Color.minus.surface)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: Color.primary.opacity(0.12), radius: 10, x: 0, y: 5)
    }
}

#Preview {
    SummaryCardView(period: nil)
        .padding()
        .background(Color.minus.background)
}

struct PeriodCard: View {
    let title: String
    let amount: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.bold)
                    .textCase(.uppercase)
                    .foregroundStyle(isSelected ? Color.minus.textPrimary.opacity(0.8) : Color.minus.textSecondary)

                Text(amount)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(isSelected ? Color.minus.textPrimary : Color.minus.textPrimary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 16)
            .padding(.horizontal, 16)
            .background(isSelected ? Color.minus.primaryAction.opacity(0.8) : Color.minus.surface)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(isSelected ? Color.clear : Color.minus.divider, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
