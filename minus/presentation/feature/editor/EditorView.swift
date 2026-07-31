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
                        if viewModel.isEditing {
                            Button {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    viewModel.clearAll()
                                }
                            } label: {
                                BudgetPillView(
                                    title: "",
                                    amount: "",
                                    pillColor: Color.minus.destructive,
                                    progress: 1.0
                                )
                                .overlay {
                                    Text("Tap here to cancel edit")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundStyle(Color.minus.destructive)
                                }
                            }
                            .buttonStyle(.plain)
                            .transition(.blurReplace)
                        } else if viewModel.isIncomeOrDecreaseMode {
                            let pillColor = viewModel.transactionMode == .income
                                ? Color.minus.success
                                : Color.minus.primaryAction
                            let verb = viewModel.transactionMode == .income
                                ? "will be added"
                                : "will be subtracted"
                            Button {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    viewModel.clearAll()
                                }
                            } label: {
                                BudgetPillView(
                                    title: "",
                                    amount: "",
                                    pillColor: pillColor,
                                    progress: 0.0
                                )
                                .overlay {
                                    Text("\(viewModel.amount) \(verb)")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundStyle(pillColor)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.7)
                                        .padding(.horizontal, 12)
                                }
                            }
                            .buttonStyle(.plain)
                            .transition(.blurReplace)
                        } else {
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
                            .transition(.blurReplace)
                        }

                        if !viewModel.isEditing && !viewModel.isIncomeOrDecreaseMode {
                            Spacer()

                            if viewModel.hasValue {
                                Button {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        viewModel.isRecurring.toggle()
                                        if viewModel.isRecurring {
                                            viewModel.showRecurrenceOptions = true
                                        }
                                    }
                                } label: {
                                    Image(systemName: viewModel.isRecurring ? "repeat.circle.fill" : "repeat.circle")
                                        .font(.system(size: 24, weight: .semibold))
                                        .foregroundStyle(
                                            viewModel.isRecurring
                                                ? Color.minus.primaryAction
                                                : Color.minus.textSecondary
                                        )
                                        .frame(width: 44, height: 44)
                                }
                                .accessibilityLabel("Recurring payment")
                                .transition(.blurReplace)
                            } else {
                                HStack(spacing: 12) {
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
                                .transition(.blurReplace)
                            }
                        }
                    }
                    .animation(.easeInOut(duration: 0.25), value: viewModel.hasValue)
                    .padding(.horizontal, 16)
                    .padding(.top, 12)

                    if viewModel.isEditing {
                        EditingDateHeader(date: Binding(
                            get: { viewModel.editingDate ?? Date() },
                            set: { viewModel.editingDate = $0 }
                        ))
                        .transition(.blurReplace)
                    }

                    AmountDisplay(viewModel: viewModel)
                        .padding(.top, viewModel.isEditing ? 8 : 16)
                        .offset(y: amountDragOffset)
                        .contentShape(Rectangle())
                        .gesture(amountDragGesture)

                    if viewModel.isRecurring {
                        HStack(spacing: 4) {
                            Image(systemName: "repeat")
                                .font(.system(size: 12))
                            Text(viewModel.selectedFrequency.displayName)
                                .font(.system(size: 13, weight: .medium))
                        }
                        .foregroundStyle(Color.minus.primaryAction)
                        .transition(.opacity)
                    }

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
        .sheet(isPresented: Binding(
            get: { viewModel?.showRecurrenceOptions ?? false },
            set: { viewModel?.showRecurrenceOptions = $0 }
        )) {
            if let vm = viewModel {
                RecurrenceOptionsSheet(viewModel: vm)
            }
        }
        .topSheet(isPresented: $isShowingHistorySheet) {
            HistoryView(activePeriodId: budgetVM?.activePeriod?.id) { id, amount, categoryName, date, isCredit in
                viewModel?.startEditing(id: id, amount: amount, categoryName: categoryName, date: date, isCredit: isCredit)
                withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                    isShowingHistorySheet = false
                }
            }
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

    private var amountColor: Color {
        switch viewModel.transactionMode {
        case .expense: return Color.minus.textPrimary
        case .income: return Color.minus.success
        case .decrease: return Color.minus.primaryAction
        }
    }

    var body: some View {
        VStack(spacing: 4) {
            Text(viewModel.amount)
                .font(.system(size: 64, weight: .bold))
                .foregroundStyle(amountColor)
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

private struct EditingDateHeader: View {
    @Binding var date: Date

    var body: some View {
        HStack(spacing: 12) {
            DatePicker("Date", selection: $date, displayedComponents: .date)
                .labelsHidden()
                .datePickerStyle(.compact)
                .tint(Color.minus.primaryAction)

            DatePicker("Time", selection: $date, displayedComponents: .hourAndMinute)
                .labelsHidden()
                .datePickerStyle(.compact)
                .tint(Color.minus.primaryAction)

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
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
