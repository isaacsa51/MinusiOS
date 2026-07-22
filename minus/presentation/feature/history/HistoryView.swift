//
//  HistoryView.swift
//  minus
//
//  Rendered inside TopSheetContainer from EditorView.
//

import SwiftUI
import SwiftData

struct HistoryView: View {
    @Query(filter: #Predicate<TransactionEntity> { !$0.isDeleted },
           sort: \TransactionEntity.createdAt, order: .reverse)
    private var entities: [TransactionEntity]
    
    private var groupedTransactions: [(date: String, transactions: [TransactionEntity], total: Decimal)] {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMMM"
        
        let grouped = Dictionary(grouping: entities) { tx in
            calendar.startOfDay(for: tx.createdAt)
        }
        
        return grouped
            .sorted { $0.key > $1.key }
            .map { (date, txs) in
                let sorted = txs.sorted { $0.createdAt > $1.createdAt }
                let total = sorted.reduce(Decimal.zero) { $0 + Decimal($1.amount) }
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
            if entities.isEmpty {
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
                                        amount: formatAmount(Decimal(tx.amount))
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
    
    private func formatAmount(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        let formatted = formatter.string(from: value as NSDecimalNumber) ?? "0"
        return "$\(formatted)"
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
    TopSheetContainer(isPresented: .constant(true)) {
        HistoryView()
    }
    .modelContainer(for: TransactionEntity.self, inMemory: true)
}
