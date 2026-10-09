//
//  BudgetFormulaSheet.swift
//  minus
//

import SwiftUI

/// The "How it's calculated" breakdown, reached by long-pressing the budget
/// pill. Walks the same arithmetic the pill ran, in the order it ran it:
/// what's divisible, what's held back, the division itself, and what's left.
struct BudgetFormulaSheet: View {
    let viewModel: BudgetPeriodViewModel

    var body: some View {
        VStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 2.5)
                .fill(Color.minus.textSecondary.opacity(0.4))
                .frame(width: 36, height: 5)
                .padding(.top, 10)

            ScrollView {
                if let breakdown = viewModel.budgetFormula {
                    content(for: breakdown)
                } else {
                    Text(String(localized: "There's no active budget period yet."))
                        .font(.subheadline)
                        .foregroundStyle(Color.minus.textSecondary)
                        .padding(40)
                }
            }
        }
        .background(Color.minus.background.ignoresSafeArea())
        .presentationSizing(.fitted)
        .task {
            await viewModel.loadSpending()
        }
    }

    private func content(for breakdown: BudgetFormulaBreakdown) -> some View {
        VStack(spacing: 24) {
            VStack(spacing: 4) {
                Text(String(localized: "How it's calculated"))
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(Color.minus.textPrimary)

                Text(breakdown.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(Color.minus.textSecondary)
            }
            .multilineTextAlignment(.center)
            .padding(.top, 12)

            // A lone "total budget = free to spend" pair says nothing the
            // fraction below doesn't already show.
            if breakdown.poolLines.count > 2 {
                section(String(localized: "What's free to spend")) {
                    ledger(breakdown.poolLines)
                }
            }

            if !breakdown.reservedCharges.isEmpty {
                section(String(localized: "Set aside for charges due later in the period")) {
                    ForEach(breakdown.reservedCharges) { charge in
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Text(charge.name)
                                .font(.system(size: 14))
                                .foregroundStyle(Color.minus.textSecondary)
                                .lineLimit(1)

                            Spacer(minLength: 12)

                            Text(charge.amount)
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                .foregroundStyle(Color.minus.textPrimary)
                        }
                    }
                }
            }

            section(String(localized: "Spread across the days left")) {
                fraction(for: breakdown)
            }

            VStack(spacing: 10) {
                section(String(localized: "What's left")) {
                    ledger(breakdown.leftLines, totalIsNegative: breakdown.shortfallNote != nil)
                }

                if let note = breakdown.shortfallNote {
                    Text(note)
                        .font(.footnote)
                        .foregroundStyle(Color.minus.destructive)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                }
            }

            Text(String(localized: "Tip: tap the pill instead of holding it to open the period sheet."))
                .font(.footnote)
                .foregroundStyle(Color.minus.textSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
        }
        .padding(20)
    }

    // MARK: - Pieces

    private func fraction(for breakdown: BudgetFormulaBreakdown) -> some View {
        HStack(spacing: 14) {
            VStack(spacing: 4) {
                Text(breakdown.numerator)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.minus.textPrimary)

                Rectangle()
                    .fill(Color.minus.textSecondary.opacity(0.6))
                    .frame(height: 1)

                Text(breakdown.denominator)
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.minus.textPrimary)
            }
            .fixedSize()

            Text(verbatim: "=")
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(Color.minus.textSecondary)

            Text(breakdown.dailyRate)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(Color.minus.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .frame(maxWidth: .infinity)
    }

    private func ledger(_ lines: [BudgetFormulaLine], totalIsNegative: Bool = false) -> some View {
        ForEach(lines) { line in
            let isTotal = line.sign == .equals

            if isTotal {
                Divider()
            }

            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(line.label)
                    .font(.system(size: isTotal ? 15 : 14, weight: isTotal ? .semibold : .regular))
                    .foregroundStyle(isTotal ? Color.minus.textPrimary : Color.minus.textSecondary)

                Spacer(minLength: 12)

                if !line.sign.symbol.isEmpty {
                    Text(verbatim: line.sign.symbol)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.minus.textSecondary)
                }

                Text(line.amount)
                    .font(.system(size: isTotal ? 17 : 15, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        isTotal && totalIsNegative ? Color.minus.destructive : Color.minus.textPrimary
                    )
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
        }
    }

    private func section<Content: View>(
        _ title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(Color.minus.textSecondary)
                .padding(.horizontal, 4)

            VStack(spacing: 10) {
                content()
            }
            .padding(16)
            .frame(maxWidth: .infinity)
            .background(Color.minus.surface)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }
}

#Preview {
    BudgetFormulaSheet(
        viewModel: {
            let dependencies = AppDependencies.preview()
            let vm = BudgetPeriodViewModel(
                periodRepo: dependencies.periodRepository,
                transactionRepo: dependencies.transactionRepository,
                splitModePreferenceRepo: dependencies.splitModePreferenceRepository,
                reservedChargesPreferenceRepo: dependencies.reservedChargesPreferenceRepository
            )
            vm.activePeriod = PeriodKey(
                id: UUID(),
                startDate: Calendar.current.date(byAdding: .day, value: -15, to: Date()) ?? Date(),
                endDate: Calendar.current.date(byAdding: .day, value: 15, to: Date()),
                mappingNode: .activeBucket,
                totalBudget: 15000,
                currency: "MXN",
                remainingStrategy: .SPLIT_EQUALLY,
                periodType: .monthly,
                daysInPeriod: 30
            )
            return vm
        }()
    )
}
