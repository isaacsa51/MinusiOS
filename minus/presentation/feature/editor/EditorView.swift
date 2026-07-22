//
//  EditorView.swift
//  minus
//
//  Created by Isaac Emmanuel Serrano Altamirano on 08/05/26.
//

import Foundation
import SwiftUI

struct EditorView: View {
    @Environment(NavigationRouter.self) var router
    @Environment(\EnvironmentValues.transactionRepository) private var txRepo
    @Environment(\EnvironmentValues.periodRepository) private var periodRepo
    @State private var viewModel: EditorViewModel?
    @State private var budgetVM: BudgetPeriodViewModel?
    @State private var isShowingBudgetDetailsSheet = false
    @State private var isShowingHistorySheet = false
    @State private var amountDragOffset: CGFloat = 0

    private let openSheetThreshold: CGFloat = 60
    private let dragResistance: CGFloat = 0.4

    var body: some View {
        GeometryReader { geo in
            if let viewModel {
                VStack(spacing: 0) {
                    HStack(spacing: 12) {
                        Button(action: {
                            isShowingBudgetDetailsSheet = true
                        }) {
                            BudgetPillView(
                                title: budgetVM?.pillTitle ?? "Cargando...",
                                amount: budgetVM?.pillAmount ?? "...",
                                pillColor: budgetVM?.pillColor ?? Color.minus.textSecondary,
                                progress: budgetVM?.spendingProgress ?? 0,
                                isExceeded: budgetVM?.isExceeded ?? false
                            )
                        }
                        .buttonStyle(.plain)

                        Spacer()

                        Button(action: {
                            router.navigate(to: .analytics)
                        }) {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundStyle(Color.minus.textPrimary)
                                .frame(width: 44, height: 44)
                        }
                        .accessibilityLabel("Analytics")

                        Button(action: {
                            router.navigate(to: .settings)
                        }) {
                            Image(systemName: "gearshape")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundStyle(Color.minus.textPrimary)
                                .frame(width: 44, height: 44)
                        }
                        .accessibilityLabel("Settings")
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)

                    AmountDisplay(viewModel: viewModel)
                        .padding(.top, 16)
                        .offset(y: amountDragOffset)
                        .contentShape(Rectangle())
                        .gesture(amountDragGesture)

                    Spacer()

                    CategoryInputRow(viewModel: viewModel)

                    EditorNumpad(viewModel: viewModel)
                }
                .frame(width: geo.size.width, height: geo.size.height)
            }
        }
        .ignoresSafeArea(.keyboard)
        .background(Color.minus.background.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .task {
            if viewModel == nil, let txRepo, let periodRepo {
                viewModel = EditorViewModel(transactionRepo: txRepo, periodRepo: periodRepo)
            }
            if budgetVM == nil, let periodRepo, let txRepo {
                budgetVM = BudgetPeriodViewModel(periodRepo: periodRepo, transactionRepo: txRepo)
            }
            let localBudgetVM = budgetVM
            viewModel?.onTransactionSaved = {
                await localBudgetVM?.loadSpending()
            }
            await budgetVM?.checkActivePeriod()
            await viewModel?.loadSavedCategories()
        }
        .sheet(isPresented: $isShowingBudgetDetailsSheet) {
            if let vm = budgetVM {
                BudgetDetailsSheet(viewModel: vm)
            }
        }
        .sheet(isPresented: Binding(
            get: { budgetVM?.showNewBudgetSheet ?? false },
            set: { budgetVM?.showNewBudgetSheet = $0 }
        )) {
            if let vm = budgetVM {
                NewBudgetPeriodSheet(viewModel: vm)
            }
        }
        .topSheet(isPresented: $isShowingHistorySheet) {
            HistoryView(activePeriodId: budgetVM?.activePeriod?.id)
        }
        .onChange(of: isShowingHistorySheet) { _, isShowing in
            if !isShowing {
                Task { await budgetVM?.loadSpending() }
            }
        }
        .alert("Error", isPresented: Binding(
            get: { viewModel?.errorMessage != nil },
            set: { if !$0 { viewModel?.errorMessage = nil } }
        )) {
            Button("OK") { viewModel?.errorMessage = nil }
        } message: {
            Text(viewModel?.errorMessage ?? "")
        }
    }

    private var amountDragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                guard value.translation.height > 0 else { return }
                amountDragOffset = value.translation.height * dragResistance
            }
            .onEnded { value in
                if value.translation.height > openSheetThreshold {
                    openHistorySheet()
                } else {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                        amountDragOffset = 0
                    }
                }
            }
    }

    private func openHistorySheet() {
        withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
            amountDragOffset = 0
            isShowingHistorySheet = true
        }
    }
}

private struct AmountDisplay: View {
    let viewModel: EditorViewModel

    var body: some View {
        VStack(spacing: 4) {
            Text(viewModel.amount)
                .font(.system(size: 64, weight: .bold))
                .foregroundStyle(Color.minus.textPrimary)
                .padding(.trailing, 20)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .frame(maxWidth: .infinity, alignment: .trailing)

            if let result = viewModel.expressionResult {
                Text(result)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(Color.minus.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.trailing, 20)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.15), value: viewModel.expressionResult != nil)
    }
}

private struct EditorNumpad: View {
    let viewModel: EditorViewModel

    var body: some View {
        NumpadView(
            onButtonTapped: { button in
                if button.icon == "checkmark" {
                    viewModel.saveTransaction()
                } else {
                    viewModel.processNumber(button: button)
                }
            },
            onDeleteLongPressed: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    viewModel.clearAll()
                }
            }
        )
        .padding(.bottom, 20)
    }
}

#Preview {
    NavigationStack {
        EditorView()
            .environment(NavigationRouter())
    }
}
