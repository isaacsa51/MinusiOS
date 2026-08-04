//
//  GetPeriodAnalyticsUseCase.swift
//  minus
//

import Foundation

class GetPeriodAnalyticsUseCase {
    private static let maxCategorySlots = 8

    private let transactionRepository: TransactionRepository

    init(transactionRepository: TransactionRepository) {
        self.transactionRepository = transactionRepository
    }

    func execute(periodId: UUID) async throws -> PeriodAnalytics {
        let expenses = try await transactionRepository
            .getTransactions(forPeriod: periodId)
            .filter { !$0.isCredit }
            .sorted { $0.createdAt < $1.createdAt }

        guard !expenses.isEmpty else { return .empty }

        let totalSpent = expenses.reduce(Decimal.zero) { $0 + $1.amount }

        let transactionAmounts = expenses.map(\.amount)
        let minTxIndex = transactionAmounts.indices.min { transactionAmounts[$0] < transactionAmounts[$1] }
        let maxTxIndex = transactionAmounts.indices.max { transactionAmounts[$0] < transactionAmounts[$1] }

        let dailyTotals = Self.dailyTotals(from: expenses)
        let minDayIndex = dailyTotals.indices.min { dailyTotals[$0].amount < dailyTotals[$1].amount }
        let maxDayIndex = dailyTotals.indices.max { dailyTotals[$0].amount < dailyTotals[$1].amount }

        let recurringSpent = expenses.filter(\.isRecurrent).reduce(Decimal.zero) { $0 + $1.amount }

        return PeriodAnalytics(
            totalSpent: totalSpent,
            transactionCount: expenses.count,
            minTransaction: minTxIndex.map { expenses[$0] },
            maxTransaction: maxTxIndex.map { expenses[$0] },
            transactionAmounts: transactionAmounts,
            minTransactionIndex: minTxIndex,
            maxTransactionIndex: maxTxIndex,
            minSpendingDay: minDayIndex.map { dailyTotals[$0] },
            maxSpendingDay: maxDayIndex.map { dailyTotals[$0] },
            dailyTotals: dailyTotals,
            minDayIndex: minDayIndex,
            maxDayIndex: maxDayIndex,
            categoryBreakdown: Self.categoryBreakdown(from: expenses, totalSpent: totalSpent),
            recurringSpent: recurringSpent,
            oneTimeSpent: totalSpent - recurringSpent
        )
    }

    private static func dailyTotals(from expenses: [Transaction]) -> [DailyTotal] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: expenses) { calendar.startOfDay(for: $0.createdAt) }
        return grouped
            .map { date, txs in DailyTotal(date: date, amount: txs.reduce(Decimal.zero) { $0 + $1.amount }) }
            .sorted { $0.date < $1.date }
    }

    private static func categoryBreakdown(from expenses: [Transaction], totalSpent: Decimal) -> [CategorySpending] {
        guard totalSpent > 0 else { return [] }

        let grouped = Dictionary(grouping: expenses) { $0.categoryId }
        let entries = grouped.map { categoryId, txs -> CategorySpending in
            let amount = txs.reduce(Decimal.zero) { $0 + $1.amount }
            let name = txs.first?.categoryName ?? String(localized: "Uncategorized")
            return CategorySpending(
                id: categoryId,
                name: name,
                amount: amount,
                percentage: NSDecimalNumber(decimal: amount / totalSpent).doubleValue
            )
        }
        .sorted { $0.amount > $1.amount }

        guard entries.count > maxCategorySlots else { return entries }

        let head = entries.prefix(maxCategorySlots - 1)
        let otherAmount = entries.suffix(from: maxCategorySlots - 1).reduce(Decimal.zero) { $0 + $1.amount }
        let other = CategorySpending(
            id: UUID(),
            name: String(localized: "Other"),
            amount: otherAmount,
            percentage: NSDecimalNumber(decimal: otherAmount / totalSpent).doubleValue
        )
        return Array(head) + [other]
    }
}
