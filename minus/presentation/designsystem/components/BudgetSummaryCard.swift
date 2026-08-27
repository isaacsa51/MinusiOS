//
//  BudgetSummaryCard.swift
//  minus
//

import SwiftUI
import SwiftThemeKit

struct BudgetSummaryCard: View {
    let period: PeriodKey?

    private var formattedBudget: String {
        guard let p = period else { return "$0" }
        let symbol = Currency.find(byCode: p.currency)?.symbol ?? "$"
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 0
        return "\(symbol)\(formatter.string(from: p.totalBudget as NSDecimalNumber) ?? "0")"
    }

    private var startDateText: String {
        guard let p = period else { return "--" }
        return Self.shortDateFormatter.string(from: p.startDate)
    }

    private var endDateText: String {
        guard let p = period else { return "--" }
        return Self.shortDateFormatter.string(from: p.effectiveEndDate)
    }

    private var daysRemaining: Int {
        guard let p = period else { return 0 }
        return max(0, Calendar.current.dateComponents([.day], from: Date(), to: p.effectiveEndDate).day ?? 0)
    }

    private var totalDays: Int {
        guard let p = period else { return 1 }
        return max(1, Calendar.current.dateComponents([.day], from: p.startDate, to: p.effectiveEndDate).day ?? 1)
    }

    private var progressFraction: CGFloat {
        1 - (CGFloat(daysRemaining) / CGFloat(totalDays))
    }

    private static let shortDateFormatter: DateFormatter = {
        let fmt = DateFormatter()
        fmt.dateFormat = "d MMM"
        fmt.locale = Locale.autoupdatingCurrent
        return fmt
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .center, spacing: 8) {
                    Text(String(localized: "Total Budget"))
                        .font(.caption)
                        .fontWeight(.bold)
                        .tracking(0.4)
                        .textCase(.uppercase)
                        .foregroundStyle(Color.minus.textSecondary)

                    Spacer(minLength: 8)

                    HStack(spacing: 6) {
                        Text(startDateText)
                        Image(systemName: "arrow.right")
                            .font(.system(size: 9, weight: .bold))
                        Text(endDateText)
                    }
                    .font(.caption2)
                    .fontWeight(.bold)
                    .textCase(.uppercase)
                    .foregroundStyle(Color.minus.textSecondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.minus.divider)
                    .clipShape(Capsule())
                }

                Text(formattedBudget)
                    .font(.displaySmall)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                    .foregroundStyle(Color.minus.textPrimary)
            }

            daysGauge
        }
        .padding(.lg)
        .background(Color.minus.surface)
        .clipRadius(.xl, style: .continuous)
    }

    private var daysGauge: some View {
        let diameter: CGFloat = 180
        let lineWidth = max(10, diameter * 0.09)
        let strokeHeadroom = lineWidth / 2 + 4
        let domeHeight = diameter / 2 + strokeHeadroom

        return ZStack {
            DomeArcShape()
                .stroke(Color.minus.divider, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))

            DomeArcShape()
                .trim(from: 0, to: min(max(progressFraction, 0), 1))
                .stroke(Color.minus.success, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .animation(.easeInOut(duration: 0.3), value: progressFraction)
        }
        .frame(width: diameter, height: domeHeight)
        .overlay(alignment: .top) {
            VStack(spacing: 2) {
                Text("\(daysRemaining)")
                    .font(.system(size: diameter * 0.16, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.minus.textPrimary)
                Text(String(localized: "Days Left"))
                    .font(.system(size: max(10, diameter * 0.045), weight: .bold))
                    .tracking(0.4)
                    .textCase(.uppercase)
                    .foregroundStyle(Color.minus.textSecondary)
            }
            .padding(.top, diameter * 0.32)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct DomeArcShape: Shape {
    func path(in rect: CGRect) -> Path {
        let radius = rect.width / 2
        var path = Path()
        path.addRelativeArc(
            center: CGPoint(x: rect.midX, y: radius),
            radius: radius,
            startAngle: .degrees(180),
            delta: .degrees(180)
        )
        return path
    }
}

struct PeriodCard: View {
    @Environment(\.appTheme) private var theme

    let title: String
    let amount: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.labelSmall, weight: .bold)
                    .textCase(.uppercase)
                    .foregroundStyle(isSelected ? Color.minus.textPrimary.opacity(0.8) : Color.minus.textSecondary)

                Text(amount)
                    .font(.headlineSmall)
                    .foregroundStyle(Color.minus.textPrimary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, .lg)
            .padding(.horizontal, .lg)
            .background(isSelected ? Color.minus.primaryAction.opacity(0.8) : Color.minus.surface)
            .clipRadius(.lg, style: .continuous)
            .overlay(
                RoundedRectangle(cornerRadius: theme.radii.lg, style: .continuous)
                    .stroke(isSelected ? Color.clear : Color.minus.divider, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    BudgetSummaryCard(
        period: PeriodKey(
            id: UUID(),
            startDate: Date(),
            endDate: Calendar.current.date(byAdding: .month, value: 1, to: Date()),
            mappingNode: .activeBucket,
            totalBudget: 15000,
            currency: "USD",
            remainingStrategy: .SPLIT_EQUALLY,
            periodType: .monthly,
            daysInPeriod: 30
        )
    )
    .padding()
    .background(Color.minus.background)
}

#Preview {
    PeriodCard
        .init(title: "This week", amount: "$1,200", isSelected: true, action: { })
}
