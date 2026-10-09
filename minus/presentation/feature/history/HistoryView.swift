//
//  HistoryView.swift
//  minus
//
//  Rendered inside TopSheetContainer from EditorView.
//

import SwiftUI

struct HistoryView: View {
    var activePeriodId: UUID?
    var onEditTransaction: ((Transaction) -> Void)?

    @Environment(\.dependencies) private var dependencies
    @State private var viewModel: HistoryViewModel?

    @AppStorage("showPastPeriodExpenses") private var showPastPeriodExpensesEnabled = true
    @State private var expandedRowId: String?
    @State private var showPastPeriods = false
    @State private var collapsedDates: Set<String> = []

    private var transactions: [Transaction] {
        viewModel?.transactions ?? []
    }

    private var currentPeriodTransactions: [Transaction] {
        guard let periodId = activePeriodId else { return transactions }
        return transactions.filter { $0.periodId == periodId }
    }

    private var recurringInPeriod: [Transaction] {
        currentPeriodTransactions.filter { $0.recurrentFrequency != nil }
    }

    private var recurringOutsidePeriod: [Transaction] {
        guard let periodId = activePeriodId else { return [] }
        return transactions.filter { $0.periodId != periodId && $0.recurrentFrequency != nil }
    }

    private var pastPeriodTransactions: [Transaction] {
        guard let periodId = activePeriodId else { return [] }
        return transactions.filter { $0.periodId != periodId }
    }

    private func groupTransactions(_ source: [Transaction]) -> [(date: String, transactions: [Transaction], total: Decimal)] {
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
                let total = sorted.reduce(Decimal.zero) { total, tx in
                    tx.isIncome ? total - tx.amount : total + tx.amount
                }
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
            if transactions.isEmpty {
                Text("No transactions yet")
                    .font(.system(size: 15))
                    .foregroundStyle(Color.minus.textSecondary)
                    .padding(.top, 40)
            } else {
                LazyVStack(spacing: 0, pinnedViews: .sectionHeaders) {
                    if !recurringInPeriod.isEmpty {
                        RecurringSectionHeader(title: "Recurring payments")
                        recurringList(for: recurringInPeriod, sectionId: "recurringInPeriod")
                    }

                    transactionSections(for: groupTransactions(currentPeriodTransactions), sectionId: "current")

                    if !recurringOutsidePeriod.isEmpty {
                        RecurringSectionHeader(title: "Recurring outside period")
                        recurringList(for: recurringOutsidePeriod, sectionId: "recurringOutsidePeriod")
                    }

                    if showPastPeriodExpensesEnabled && !pastPeriodTransactions.isEmpty {
                        PastPeriodDivider(isExpanded: showPastPeriods) {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showPastPeriods.toggle()
                            }
                        }

                        if showPastPeriods {
                            transactionSections(for: groupTransactions(pastPeriodTransactions), sectionId: "past")
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task {
            guard viewModel == nil else { return }
            let vm = HistoryViewModel(transactionRepository: dependencies.transactionRepository)
            viewModel = vm
            await vm.load()
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

    @ViewBuilder
    private func transactionSections(for groups: [(date: String, transactions: [Transaction], total: Decimal)], sectionId: String) -> some View {
        ForEach(groups, id: \.date) { group in
            let isCollapsed = collapsedDates.contains(group.date)

            Section {
                if !isCollapsed {
                    VStack(spacing: 0) {
                        ForEach(group.transactions) { tx in
                            let rowId = "\(sectionId)-\(tx.id)"
                            TransactionRow(
                                categoryName: tx.categoryName ?? (tx.isIncome ? "Income" : "Expense"),
                                time: Self.timeFormatter.string(from: tx.createdAt),
                                amount: formatAmount(tx.amount, isIncome: tx.isIncome),
                                isIncome: tx.isIncome,
                                isExpanded: expandedRowId == rowId,
                                fullDate: Self.fullDateFormatter.string(from: tx.createdAt),
                                extraNote: tx.extraNote,
                                onTap: {
                                    withAnimation(.easeInOut(duration: 0.25)) {
                                        if expandedRowId == rowId {
                                            expandedRowId = nil
                                        } else {
                                            expandedRowId = rowId
                                        }
                                    }
                                },
                                onEdit: {
                                    onEditTransaction?(tx)
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
                }
            } header: {
                Button {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        if isCollapsed {
                            collapsedDates.remove(group.date)
                        } else {
                            collapsedDates.insert(group.date)
                        }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.down")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Color.minus.textSecondary)
                            .rotationEffect(.degrees(isCollapsed ? -90 : 0))
                        Text(group.date)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color.minus.textSecondary)
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .background(Color.minus.background)
            }
        }
    }

    @ViewBuilder
    private func recurringList(for items: [Transaction], sectionId: String) -> some View {
        VStack(spacing: 0) {
            ForEach(items) { tx in
                let rowId = "\(sectionId)-\(tx.id)"
                TransactionRow(
                    categoryName: tx.categoryName ?? (tx.isIncome ? "Income" : "Expense"),
                    time: Self.timeFormatter.string(from: tx.createdAt),
                    amount: formatAmount(tx.amount, isIncome: tx.isIncome),
                    isIncome: tx.isIncome,
                    isExpanded: expandedRowId == rowId,
                    fullDate: Self.fullDateFormatter.string(from: tx.createdAt),
                    extraNote: tx.extraNote,
                    onTap: {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            if expandedRowId == rowId {
                                expandedRowId = nil
                            } else {
                                expandedRowId = rowId
                            }
                        }
                    },
                    onEdit: {
                        onEditTransaction?(tx)
                    },
                    onDelete: {
                        deleteTransaction(id: tx.id)
                    }
                )

                if tx.id != items.last?.id {
                    Divider()
                        .padding(.leading, 16)
                }
            }
        }
        .background(Color.minus.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
    }

    private func formatAmount(_ value: Decimal, isIncome: Bool = false) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        let formatted = formatter.string(from: value as NSDecimalNumber) ?? "0"
        return isIncome ? "+$\(formatted)" : "$\(formatted)"
    }

    private func deleteTransaction(id: UUID) {
        withAnimation(.easeInOut(duration: 0.25)) {
            expandedRowId = nil
        }
        Task {
            await viewModel?.deleteTransaction(id: id)
        }
    }
}

private struct TransactionRow: View {
    let categoryName: String
    let time: String
    let amount: String
    let isIncome: Bool
    let isExpanded: Bool
    let fullDate: String
    let extraNote: String?
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
                        .foregroundStyle(isIncome ? Color.minus.success : Color.minus.textPrimary)
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

                        if let extraNote, !extraNote.isEmpty {
                            DetailInfoRow(label: "Note", value: extraNote)
                        }
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
                .multilineTextAlignment(.trailing)
        }
    }
}

private struct RecurringSectionHeader: View {
    let title: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "repeat")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color.minus.primaryAction)
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.minus.primaryAction)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
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
                    Text(isExpanded ? "Hide past periods" : "View past periods")
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

private class PreviewTransactionRepository: TransactionRepository {
    let currentPeriodId: UUID
    let pastPeriodId: UUID

    init(currentPeriodId: UUID, pastPeriodId: UUID) {
        self.currentPeriodId = currentPeriodId
        self.pastPeriodId = pastPeriodId
    }

    func save(transaction: Transaction) async throws {}
    func delete(transactionId: UUID) async throws {}
    func getTransaction(id: UUID) async throws -> Transaction? { nil }
    func getTransaction(byClientGeneratedId clientGeneratedId: String) async throws -> Transaction? { nil }
    func getTransactions(forPeriod periodId: UUID) async throws -> [Transaction] { [] }
    func getTransactions(forCategory categoryId: UUID) async throws -> [Transaction] { [] }
    func getTransactions(between startDate: Date, and endDate: Date) async throws -> [Transaction] { [] }

    func getAllTransactions() async throws -> [Transaction] {
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

        let current = currentTransactions.map { amount, category, date in
            Transaction(
                id: UUID(), amount: Decimal(amount), createdAt: date,
                clientGeneratedId: UUID().uuidString, periodId: currentPeriodId,
                categoryId: UUID(), categoryName: category
            )
        }
        let past = pastTransactions.map { amount, category, date in
            Transaction(
                id: UUID(), amount: Decimal(amount), createdAt: date,
                clientGeneratedId: UUID().uuidString, periodId: pastPeriodId,
                categoryId: UUID(), categoryName: category
            )
        }
        return current + past
    }
}

#Preview {
    let currentPeriodId = UUID()
    let pastPeriodId = UUID()

    return TopSheetContainer(isPresented: .constant(true)) {
        HistoryView(activePeriodId: currentPeriodId)
    }
    .environment(\.dependencies, .preview(transactionRepository: PreviewTransactionRepository(currentPeriodId: currentPeriodId, pastPeriodId: pastPeriodId)))
}
