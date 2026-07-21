//
//  EditorView.swift
//  minus
//
//  Created by Isaac Emmanuel Serrano Altamirano on 08/05/26.
//

import Foundation
import SwiftUI
import SwiftData

struct EditorView: View {
    @Environment(NavigationRouter.self) var router
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = EditorViewModel()
    @State private var budgetVM: BudgetPeriodViewModel?
    @State private var isShowingBudgetDetailsSheet = false
    @State private var isShowingHistorySheet = false
    @State private var amountDragOffset: CGFloat = 0

    private let openSheetThreshold: CGFloat = 60
    private let dragResistance: CGFloat = 0.4

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Button(action: {
                    isShowingBudgetDetailsSheet = true
                }) {
                    BudgetPillView(
                        title: budgetVM?.pillTitle ?? "Cargando...",
                        amount: budgetVM?.pillAmount ?? "...",
                        pillColor: budgetVM?.pillColor ?? Color.minus.textSecondary
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

            Text(viewModel.amount)
                .font(.system(size: 64, weight: .bold))
                .foregroundStyle(Color.minus.textPrimary)
                .padding(.trailing, 20)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.top, 16)
                .offset(y: amountDragOffset)
                .contentShape(Rectangle())
                .gesture(amountDragGesture)

            Spacer()

            // Category input row
            HStack(spacing: 8) {
                if !viewModel.savedCategories.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(viewModel.savedCategories) { category in
                                if let name = category.name {
                                    CategoryBadgeView(
                                        name: name,
                                        isSelected: viewModel.categoryText == name,
                                        onTap: { viewModel.selectCategory(category) }
                                    )
                                }
                            }
                        }
                    }
                }

                HStack(spacing: 6) {
                    Image(systemName: "tag")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.minus.textSecondary)
                    TextField("Category", text: $viewModel.categoryText)
                        .font(.system(size: 15))
                        .foregroundStyle(Color.minus.textPrimary)
                        .textInputAutocapitalization(.words)
                        .submitLabel(.done)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.minus.surface)
                .clipShape(Capsule())
                .frame(maxWidth: viewModel.savedCategories.isEmpty ? .infinity : 160)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)

            NumpadView(onButtonTapped: { button in
                if button.icon == "checkmark" {
                    viewModel.saveTransaction()
                } else {
                    viewModel.processNumber(button: button)
                }
            })
            .padding(.bottom, 20)
        }
        .frame(maxWidth: .infinity)
        .background(Color.minus.background.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .task {
            if budgetVM == nil {
                budgetVM = BudgetPeriodViewModel(context: modelContext)
            }
            await budgetVM?.checkActivePeriod()
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
            HistoryView()
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

#Preview {
    NavigationStack {
        EditorView()
            .environment(NavigationRouter())
    }
}
