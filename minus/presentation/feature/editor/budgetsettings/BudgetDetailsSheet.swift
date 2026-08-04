//
//  BudgetDetailsSheet.swift
//  minus
//
//  Created by Isaac Emmanuel Serrano Altamirano on 10/05/26.
//

import SwiftUI

struct BudgetDetailsSheet: View {
    @Environment(\.dismiss) var dismiss
    let viewModel: BudgetPeriodViewModel

    @State private var showEndPeriodAlert = false
    @State private var showEditBudgetSheet = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 8) {
                    
                    PeriodSpendingCard(
                        spentAmount: viewModel.periodSpentAmount,
                        progress: viewModel.periodSpendingProgress,
                        availablePercentage: viewModel.periodAvailablePercentage,
                        pillColor: viewModel.periodPillColor
                    )
                    
                    Grid(horizontalSpacing: 12, verticalSpacing: 0) {
                        GridRow(alignment: .top) {
                            SummaryCardView(period: viewModel.activePeriod)
                                .gridCellColumns(2)
                            DaysRemainingGaugeCard(period: viewModel.activePeriod)
                        }
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("How do you want to split your budget?")
                            .font(.subheadline)
                            .foregroundStyle(Color.minus.textSecondary)
                            .padding(.horizontal, 4)

                        Picker("Split budget", selection: Binding(
                            get: { viewModel.selectedSplitMode },
                            set: { viewModel.updateSplitMode($0) }
                        )) {
                            ForEach(BudgetPeriod.allCases, id: \.self) { period in
                                Text(period.displayTitle).tag(period)
                            }
                        }
                        .pickerStyle(.segmented)

                        PeriodCard(
                            title: viewModel.selectedSplitMode.displayTitle,
                            amount: splitAmount(for: viewModel.selectedSplitMode),
                            isSelected: true
                        ) {}
                        .allowsHitTesting(false)
                    }
                    
                    Divider()

                    VStack(spacing: 12) {
                        if let bannerText = carryOverBannerText {
                            CarryOverInfoBanner(text: bannerText)
                        }

                        Button(role: .destructive) {
                            showEndPeriodAlert = true
                        } label: {
                            Text("End savings period early")
                                .font(.system(size: 16, weight: .semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.minus.destructive.opacity(0.15))
                                .foregroundStyle(Color.minus.destructive)
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                    }
                }
                .padding(20)
            }
            .background(Color.minus.background.ignoresSafeArea())
            .navigationTitle("Period Details")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await viewModel.loadSpending()
                await viewModel.refreshCarryOverPreview()
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(Color.minus.textSecondary)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.populateFormFromActivePeriod()
                        showEditBudgetSheet = true
                    } label: {
                        Image(systemName: "pencil.circle.fill")
                            .foregroundStyle(Color.minus.textSecondary)
                    }
                }
            }
            .sheet(isPresented: $showEditBudgetSheet) {
                NewBudgetPeriodSheet(viewModel: viewModel)
            }
            .alert("Error", isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )) {
                Button("OK") { viewModel.errorMessage = nil }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
            // generate "alert dialog" for ending early the period
            .presentationSizing(.fitted)
            .confirmationDialog("End current period?", isPresented: $showEndPeriodAlert, titleVisibility: .visible) {
                Button("End and start a new one", role: .destructive) {
                    Task {
                        await viewModel.finishPeriodEarly()
                    }
                    dismiss()
                }

                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This will close out this period's history and ask you for the new period's details.")
            }
        }
    }

    private var carryOverBannerText: String? {
        guard let active = viewModel.activePeriod,
              let preview = viewModel.carryOverPreview else { return nil }

        let symbol = Currency.find(byCode: active.currency)?.symbol ?? "$"
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        let amountText = "\(symbol)\(formatter.string(from: preview.amount as NSDecimalNumber) ?? "0")"

        switch preview.strategy {
        case .SPLIT_EQUALLY:
            return "You have \(amountText) left unspent. When this period ends, it will be spread across every day of your next budget."
        case .ADD_TO_FIRST_DAY:
            return "You have \(amountText) left unspent. When this period ends, it will be added to the first day of your next budget."
        case .ASK_ALWAYS:
            return "You have \(amountText) left unspent. You'll be asked whether to add or discard it when you create your next budget."
        }
    }

    private func splitAmount(for period: BudgetPeriod) -> String {
        guard let active = viewModel.activePeriod else { return "$0" }
        let symbol = Currency.find(byCode: active.currency)?.symbol ?? "$"
        let amount = active.splitAmount(for: period)
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 0
        return "\(symbol)\(formatter.string(from: amount as NSDecimalNumber) ?? "0")"
    }
}

extension BudgetPeriod {
    var displayTitle: String {
        switch self {
        case .daily: return String(localized: "Daily")
        case .weekly: return String(localized: "Weekly")
        case .biweekly: return String(localized: "Biweekly")
        case .monthly: return String(localized: "Monthly")
        }
    }
}
private class PreviewPeriodRepository: PeriodRepository {
    func save(period: PeriodKey) async throws {}
    func getPeriod(id: UUID) async throws -> PeriodKey? { nil }
    func getActivePeriod() async throws -> PeriodKey? {
        PeriodKey(
            id: UUID(),
            startDate: Date(),
            endDate: Calendar.current.date(byAdding: .month, value: 1, to: Date()),
            mappingNode: .activeBucket,
            totalBudget: 15000,
            currency: "MXN",
            remainingStrategy: .SPLIT_EQUALLY,
            periodType: .monthly,
            daysInPeriod: 30
        )
    }
    func getAllPeriods() async throws -> [PeriodKey] { [] }
    func closePeriod(id: UUID, finalEndDate: Date) async throws {}
}

private class PreviewTransactionRepository: TransactionRepository {
    func save(transaction: Transaction) async throws {}
    func delete(transactionId: UUID) async throws {}
    func getTransaction(id: UUID) async throws -> Transaction? { nil }
    func getAllTransactions() async throws -> [Transaction] { [] }
    func getTransactions(forPeriod periodId: UUID) async throws -> [Transaction] { [] }
    func getTransactions(forCategory categoryId: UUID) async throws -> [Transaction] { [] }
    func getTransactions(between startDate: Date, and endDate: Date) async throws -> [Transaction] { [] }
}

#Preview {
    BudgetDetailsSheet(
        viewModel: {
            let vm = BudgetPeriodViewModel(
                periodRepo: PreviewPeriodRepository(),
                transactionRepo: PreviewTransactionRepository()
            )
            vm.activePeriod = PeriodKey(
                id: UUID(),
                startDate: Date(),
                endDate: Calendar.current.date(byAdding: .month, value: 1, to: Date()),
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

