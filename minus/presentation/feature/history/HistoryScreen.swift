//
//  HistoryScreen.swift
//  minus
//

import SwiftUI

struct HistoryScreen: View {
    @Environment(NavigationRouter.self) private var router
    @Environment(\.dependencies) private var dependencies
    @State private var activePeriodId: UUID?
    @State private var isLoading = true

    var body: some View {
        Group {
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                HistoryView(activePeriodId: activePeriodId) { tx in
                    router.pendingEditTransaction = PendingEditTransaction(
                        id: tx.id,
                        amount: NSDecimalNumber(decimal: tx.amount).doubleValue,
                        categoryName: tx.categoryName,
                        date: tx.createdAt,
                        isIncome: tx.isIncome,
                        extraNote: tx.extraNote
                    )
                    router.popToRoot()
                }
            }
        }
        .background(Color.minus.background.ignoresSafeArea())
        .navigationTitle("History")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            activePeriodId = try? await dependencies.periodRepository.getActivePeriod()?.id
            isLoading = false
        }
    }
}

#Preview {
    NavigationStack {
        HistoryScreen()
            .environment(NavigationRouter())
    }
}
