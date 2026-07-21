//
//  HistoryView.swift
//  minus
//
//  Rendered inside TopSheetContainer from EditorView.
//

import SwiftUI

struct HistoryView: View {
    let transactions: [Transaction]
    
    private var groupedTransactions: [(date: String, transactions: [Transaction], total: Double)] {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMMM"
        
        let grouped = Dictionary(grouping: transactions) { tx in
            calendar.startOfDay(for: tx.createdAt)
        }
        
        return grouped
            .sorted { $0.key > $1.key }
            .map { (date, txs) in
                let sorted = txs.sorted { $0.createdAt > $1.createdAt }
                let total = sorted.reduce(0) { $0 + $1.amount }
                return (date: formatter.string(from: date), transactions: sorted, total: total)
            }
    }
    
    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return f
    }()
    
    var body: some View {
        ScrollView {
            if transactions.isEmpty {
                Text("No transactions yet")
                    .font(.system(size: 15))
                    .foregroundStyle(Color.minus.textSecondary)
                    .padding(.top, 40)
            } else {
                LazyVStack(spacing: 0, pinnedViews: .sectionHeaders) {
                    ForEach(groupedTransactions, id: \.date) { group in
                        Section {
                            VStack(spacing: 0) {
                                ForEach(group.transactions) { tx in
                                    TransactionRow(
                                        categoryName: tx.categoryName ?? "Expense",
                                        time: Self.timeFormatter.string(from: tx.createdAt),
                                        amount: formatAmount(tx.amount)
                                    )
                                    
                                    if tx.id != group.transactions.last?.id {
                                        Divider()
                                            .padding(.leading, 16)
                                    }
                                }
                            }
                            .background(Color.minus.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .padding(.horizontal, 16)
                            
                            // Daily total
                            HStack {
                                Spacer()
                                Text("Total: \(formatAmount(group.total))")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(Color.minus.textSecondary)
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 4)
                            .padding(.bottom, 12)
                        } header: {
                            HStack(spacing: 6) {
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(Color.minus.textSecondary)
                                Text(group.date)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(Color.minus.textSecondary)
                                Spacer()
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.minus.background)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func formatAmount(_ value: Double) -> String {
        let raw = String(format: "%.2f", value)
        // Strip trailing zeros after decimal
        if raw.contains(".") {
            var result = raw
            while result.hasSuffix("0") { result.removeLast() }
            if result.hasSuffix(".") { result.removeLast() }
            return "$\(result)"
        }
        return "$\(raw)"
    }
}

private struct TransactionRow: View {
    let categoryName: String
    let time: String
    let amount: String
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(categoryName)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Color.minus.textPrimary)
                Text(time)
                    .font(.system(size: 12))
                    .foregroundStyle(Color.minus.textSecondary)
            }
            Spacer()
            Text(amount)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Color.minus.textPrimary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}

#Preview {
    let sampleTransactions = [
        Transaction(id: UUID(), amount: 49.99, createdAt: Date(), clientGeneratedId: UUID().uuidString, periodId: UUID(), categoryId: UUID(), categoryName: "Online course"),
        Transaction(id: UUID(), amount: 25.0, createdAt: Date().addingTimeInterval(-3600), clientGeneratedId: UUID().uuidString, periodId: UUID(), categoryId: UUID(), categoryName: "Gym membership"),
        Transaction(id: UUID(), amount: 55.0, createdAt: Date().addingTimeInterval(-86400), clientGeneratedId: UUID().uuidString, periodId: UUID(), categoryId: UUID(), categoryName: "New shirt"),
    ]
    
    TopSheetContainer(isPresented: .constant(true)) {
        HistoryView(transactions: sampleTransactions)
    }
}
