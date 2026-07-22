import SwiftUI

struct NewBudgetPeriodSheet: View {
    @Environment(\.dismiss) var dismiss
    @Bindable var viewModel: BudgetPeriodViewModel

    var body: some View {
        VStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 2.5)
                .fill(Color.minus.textSecondary.opacity(0.4))
                .frame(width: 36, height: 5)
                .padding(.top, 10)

            ScrollView {
                VStack(spacing: 28) {
                    Text("New Budget Period")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(Color.minus.textPrimary)
                        .padding(.top, 16)

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
                        dateRangeRow

                        Divider()
                            .padding(.leading, 52)

                        strategyRow

                        Divider()
                            .padding(.leading, 52)

                        currencyRow
                    }
                    .background(Color.minus.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

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
        .alert("Error", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

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

extension RemainingBudgetStrategy {
    var displayName: String {
        switch self {
        case .SPLIT_EQUALLY: return "Spread across all days"
        case .ADD_TO_FIRST_DAY: return "Add to first day"
        case .ASK_ALWAYS: return "Ask always"
        }
    }
}
