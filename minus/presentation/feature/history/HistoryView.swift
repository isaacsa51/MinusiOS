//
//  HistoryView.swift
//  minus
//
//  Rendered inside TopSheetContainer from EditorView.
//

import SwiftUI
import SwiftData

struct HistoryView: View {
    var activePeriodId: UUID?
    
    @Environment(\.transactionRepository) private var transactionRepository
    
    @Query(filter: #Predicate<TransactionEntity> { !$0.isDeleted },
           sort: \TransactionEntity.createdAt, order: .reverse)
    private var entities: [TransactionEntity]
    
    @AppStorage("showPastPeriodExpenses") private var showPastPeriodExpensesEnabled = true
    @State private var expandedTransactionId: UUID?
    @State private var showPastPeriods = false
    
    private var currentPeriodEntities: [TransactionEntity] {
        guard let periodId = activePeriodId else { return entities }
        return entities.filter { $0.periodId == periodId }
    }
    
    private var pastPeriodEntities: [TransactionEntity] {
        guard let periodId = activePeriodId else { return [] }
        return entities.filter { $0.periodId != periodId }
    }
    
    private func groupTransactions(_ source: [TransactionEntity]) -> [(date: String, transactions: [TransactionEntity], total: Decimal)] {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMMM"
        
        let grouped = Dictionary(grouping: source) { tx in
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
    
    private static let fullDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .full
        f.timeStyle = .short
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
                    transactionSections(for: groupTransactions(currentPeriodEntities))
                    
                    if showPastPeriodExpensesEnabled && !pastPeriodEntities.isEmpty {
                        PastPeriodDivider(isExpanded: showPastPeriods) {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showPastPeriods.toggle()
                            }
                        }
                        
                        if showPastPeriods {
                            transactionSections(for: groupTransactions(pastPeriodEntities))
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    @ViewBuilder
    private func transactionSections(for groups: [(date: String, transactions: [TransactionEntity], total: Decimal)]) -> some View {
        ForEach(groups, id: \.date) { group in
            Section {
                VStack(spacing: 0) {
                    ForEach(group.transactions) { tx in
                        TransactionRow(
                            categoryName: tx.categoryName ?? "Expense",
                            time: Self.timeFormatter.string(from: tx.createdAt),
                            amount: formatAmount(Decimal(tx.amount)),
                            isExpanded: expandedTransactionId == tx.id,
                            fullDate: Self.fullDateFormatter.string(from: tx.createdAt),
                            onTap: {
                                withAnimation(.easeInOut(duration: 0.25)) {
                                    if expandedTransactionId == tx.id {
                                        expandedTransactionId = nil
                                    } else {
                                        expandedTransactionId = tx.id
                                    }
                                }
                            },
                            onEdit: {
                                // TODO: wire up edit flow
                            },
                            onDelete: {
                                deleteTransaction(id: tx.id)
                            }
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
    
    private func formatAmount(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        let formatted = formatter.string(from: value as NSDecimalNumber) ?? "0"
        return "$\(formatted)"
    }
    
    private func deleteTransaction(id: UUID) {
        guard let repo = transactionRepository else { return }
        withAnimation(.easeInOut(duration: 0.25)) {
            expandedTransactionId = nil
        }
        Task {
            try? await repo.delete(transactionId: id)
        }
    }
}

private struct TransactionRow: View {
    let categoryName: String
    let time: String
    let amount: String
    let isExpanded: Bool
    let fullDate: String
    let onTap: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            Button(action: onTap) {
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
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.minus.textSecondary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            
            if isExpanded {
                VStack(spacing: 0) {
                    Divider()
                        .padding(.leading, 16)
                    
                    VStack(spacing: 8) {
                        DetailInfoRow(label: "Date", value: fullDate)
                        DetailInfoRow(label: "Category", value: categoryName)
                        DetailInfoRow(label: "Amount", value: amount)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
                    
                    HStack(spacing: 12) {
                        Button(action: onEdit) {
                            Label("Edit", systemImage: "pencil")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(Color.minus.textPrimary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(Color.minus.surfaceSecondary)
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        }
                        .buttonStyle(.plain)
                        
                        Button(action: onDelete) {
                            Label("Delete", systemImage: "trash")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(Color.minus.destructive)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(Color.minus.destructive.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 10)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}

private struct DetailInfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 13))
                .foregroundStyle(Color.minus.textSecondary)
            Spacer()
            Text(value)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color.minus.textPrimary)
        }
    }
}

private struct PastPeriodDivider: View {
    let isExpanded: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                line
                HStack(spacing: 6) {
                    Text(isExpanded ? "Ocultar periodos anteriores" : "Ver periodos anteriores")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.minus.textSecondary)
                }
                .layoutPriority(1)
                line
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        }
        .buttonStyle(.plain)
    }
    
    private var line: some View {
        Rectangle()
            .fill(Color.minus.divider)
            .frame(height: 1)
    }
}

private struct HistoryPreview: View {
    @Environment(\.modelContext) private var context
    
    private let currentPeriodId = UUID()
    private let pastPeriodId = UUID()
    
    var body: some View {
        TopSheetContainer(isPresented: .constant(true)) {
            HistoryView(activePeriodId: currentPeriodId)
        }
        .onAppear { seedData() }
    }
    
    private func seedData() {
        let calendar = Calendar.current
        let now = Date()
        
        let currentTransactions: [(Double, String, Date)] = [
            (45.50, "Lunch", now),
            (12.00, "Coffee", now),
            (230.00, "Groceries", calendar.date(byAdding: .day, value: -1, to: now)!),
            (89.99, "Gas", calendar.date(byAdding: .day, value: -1, to: now)!),
            (15.00, "Snacks", calendar.date(byAdding: .day, value: -2, to: now)!),
        ]
        
        let pastTransactions: [(Double, String, Date)] = [
            (500.00, "Rent", calendar.date(byAdding: .day, value: -35, to: now)!),
            (120.00, "Electric Bill", calendar.date(byAdding: .day, value: -36, to: now)!),
            (65.00, "Internet", calendar.date(byAdding: .day, value: -36, to: now)!),
        ]
        
        for (amount, category, date) in currentTransactions {
            context.insert(TransactionEntity(
                id: UUID(), amount: amount, createdAt: date,
                clientGeneratedId: UUID().uuidString, periodId: currentPeriodId,
                isDeleted: false, isCredit: false, categoryId: UUID(), categoryName: category
            ))
        }
        
        for (amount, category, date) in pastTransactions {
            context.insert(TransactionEntity(
                id: UUID(), amount: amount, createdAt: date,
                clientGeneratedId: UUID().uuidString, periodId: pastPeriodId,
                isDeleted: false, isCredit: false, categoryId: UUID(), categoryName: category
            ))
        }
        
        try? context.save()
    }
}

#Preview {
    HistoryPreview()
        .modelContainer(for: TransactionEntity.self, inMemory: true)
}
