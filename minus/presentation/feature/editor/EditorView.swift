//
//  EditorView.swift
//  minus
//
//  Created by Isaac Emmanuel Serrano Altamirano on 08/05/26.
//

import Foundation
import SwiftUI

struct EditorView: View {
    @Environment(NavigationRouter.self) var router // here we get the instace of Router
    @State private var viewModel = EditorViewModel()
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
                    BudgetPillView(title: "Para hoy", amount: "$1,225.22")
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
        .sheet(isPresented: $isShowingBudgetDetailsSheet) {
            BudgetDetailsSheet()
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
