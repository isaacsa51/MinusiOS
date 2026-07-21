//
//  NewBudgetPeriodSheet.swift
//  minus
//

import SwiftUI

struct NewBudgetPeriodSheet: View {
    @Environment(\.dismiss) var dismiss
    @Bindable var viewModel: BudgetPeriodViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Drag indicator
            RoundedRectangle(cornerRadius: 2.5)
                .fill(Color.minus.textSecondary.opacity(0.4))
                .frame(width: 36, height: 5)
                .padding(.top, 10)

            ScrollView {
                VStack(spacing: 28) {
                    // Title
                    Text("New Budget Period")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(Color.minus.textPrimary)
                        .padding(.top, 16)

                    // Large amount input
                    TextField("0.00", text: $viewModel.formBudgetAmount)
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Color.minus.textPrimary)
                        .onChange(of: viewModel.formBudgetAmount) { _, newValue in
                            let raw = CurrencyInputFormatter.stripFormatting(newValue)
                            let formatted = CurrencyInputFormatter.format(raw)
                            if formatted != newValue {
                                viewModel.formBudgetAmount = formatted
                            }
                        }

                    VStack(spacing: 0) {
                        // Date range row
                        dateRangeRow

                        Divider()
                            .padding(.leading, 52)

                        // Remaining strategy row
                        strategyRow

                        Divider()
                            .padding(.leading, 52)

                        // Currency row
                        currencyRow
                    }
                    .background(Color.minus.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                    // Apply button
                    Button {
                        Task { await viewModel.applyNewBudget() }
                    } label: {
                        Text("Apply")
                            .font(.system(size: 18, weight: .bold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.minus.primaryAction)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                }
                .padding(20)
            }
        }
        .background(Color.minus.background.ignoresSafeArea())
        .interactiveDismissDisabled(viewModel.activePeriod == nil)
    }

    // MARK: - Row views

    private var dateRangeRow: some View {
        HStack(spacing: 14) {
            Image(systemName: "calendar")
                .font(.system(size: 18))
                .foregroundStyle(Color.minus.textSecondary)
                .frame(width: 24)

            DatePicker("", selection: $viewModel.formStartDate, displayedComponents: .date)
                .labelsHidden()

            Text("—")
                .foregroundStyle(Color.minus.textSecondary)

            DatePicker("", selection: $viewModel.formEndDate, displayedComponents: .date)
                .labelsHidden()

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    private var strategyRow: some View {
        Menu {
            ForEach(RemainingBudgetStrategy.allCases, id: \.self) { strategy in
                Button {
                    viewModel.formRemainingStrategy = strategy
                } label: {
                    HStack {
                        Text(strategy.displayName)
                        if viewModel.formRemainingStrategy == strategy {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "square.stack.3d.up")
                    .font(.system(size: 18))
                    .foregroundStyle(Color.minus.textSecondary)
                    .frame(width: 24)

                Text("Remaining")
                    .font(.body)
                    .foregroundStyle(Color.minus.textPrimary)

                Spacer()

                Text(viewModel.formRemainingStrategy.displayName)
                    .font(.subheadline)
                    .foregroundStyle(Color.minus.textSecondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
    }

    private var currencyRow: some View {
        HStack(spacing: 14) {
            Image(systemName: "circle.fill")
                .font(.system(size: 18))
                .foregroundStyle(Color.minus.textSecondary)
                .frame(width: 24)

            Text("Currency")
                .font(.body)
                .foregroundStyle(Color.minus.textPrimary)

            Spacer()

            Text("\(viewModel.formCurrency.symbol) \(viewModel.formCurrency.code)")
                .font(.subheadline)
                .foregroundStyle(Color.minus.textSecondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}

// MARK: - Display names for strategy

extension RemainingBudgetStrategy {
    var displayName: String {
        switch self {
        case .SPLIT_EQUALLY: return "Spread across all days"
        case .ADD_TO_FIRST_DAY: return "Add to first day"
        case .ASK_ALWAYS: return "Ask always"
        }
    }
}
