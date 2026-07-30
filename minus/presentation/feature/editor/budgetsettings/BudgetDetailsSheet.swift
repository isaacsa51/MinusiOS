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
                VStack(spacing: 24) {
                    SummaryCardView(period: viewModel.activePeriod)

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Cómo quieres dividir el presupuesto?")
                            .font(.subheadline)
                            .foregroundStyle(Color.minus.textSecondary)
                            .padding(.horizontal, 4)

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            ForEach(BudgetPeriod.allCases, id: \.self) { period in
                                PeriodCard(
                                    title: period.displayTitle,
                                    amount: splitAmount(for: period),
                                    isSelected: viewModel.selectedSplitMode == period
                                ) {
                                    viewModel.updateSplitMode(period)
                                }
                            }
                        }
                    }

                    Button(role: .destructive) {
                        showEndPeriodAlert = true
                    } label: {
                        Text("Finalizar periodo de ahorro antes de tiempo")
                            .font(.system(size: 16, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.minus.destructive.opacity(0.15))
                            .foregroundStyle(Color.minus.destructive)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                }
                .padding(20)
            }
            .background(Color.minus.background.ignoresSafeArea())
            .navigationTitle("Detalles del periodo")
            .navigationBarTitleDisplayMode(.inline)
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
            .confirmationDialog("Terminar periodo actual?", isPresented: $showEndPeriodAlert, titleVisibility: .visible) {
                Button("Finalizar y crear uno nuevo", role: .destructive) {
                    // TODO: call FinishPeriodEarlyUseCase or delegate it into the viewmodel to not tight UI with business logic
                    dismiss()
                }

                Button("Cancelar", role: .cancel) { }
            } message: {
                Text("Esta acción cerrará el historial de este periodo y se te pedirá información sobre el nuevo periodo.")
            }
        }
    }

    private func splitAmount(for period: BudgetPeriod) -> String {
        guard let active = viewModel.activePeriod else { return "$0" }
        let symbol = Currency.find(byCode: active.currency)?.symbol ?? "$"
        let totalDays = max(1, active.daysInPeriod)
        let daily = active.totalBudget / Decimal(totalDays)

        let multiplier: Int
        switch period {
        case .daily: multiplier = 1
        case .weekly: multiplier = 7
        case .biweekly: multiplier = 14
        case .monthly: multiplier = totalDays
        }

        let amount = daily * Decimal(min(multiplier, totalDays))
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
        case .daily: return "A diario"
        case .weekly: return "Semanal"
        case .biweekly: return "Quincenal"
        case .monthly: return "Mensual"
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

