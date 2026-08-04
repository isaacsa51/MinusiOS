//
//  PeriodAnalytics.swift
//  minus
//

import Foundation

struct CategorySpending: Identifiable {
    let id: UUID
    let name: String
    let amount: Decimal
    /// Share of `PeriodAnalytics.totalSpent`, in 0...1.
    let percentage: Double
}

struct DailyTotal: Identifiable {
    var id: Date { date }
    let date: Date
    let amount: Decimal
}

struct PeriodAnalytics {
    let totalSpent: Decimal
    let transactionCount: Int

    let minTransaction: Transaction?
    let maxTransaction: Transaction?
    /// Expense amounts in chronological order — the series behind the
    /// largest/smallest-expense stat tiles' background sparkline.
    let transactionAmounts: [Decimal]
    /// `minTransaction`/`maxTransaction`'s position within `transactionAmounts`.
    let minTransactionIndex: Int?
    let maxTransactionIndex: Int?

    let minSpendingDay: DailyTotal?
    let maxSpendingDay: DailyTotal?
    /// One entry per day that had spending, chronological; days with none are
    /// simply absent. The series behind the highest/lowest-day sparkline.
    let dailyTotals: [DailyTotal]
    /// `minSpendingDay`/`maxSpendingDay`'s position within `dailyTotals`.
    let minDayIndex: Int?
    let maxDayIndex: Int?

    /// Sorted by amount descending. Categories past the display cap are folded
    /// into a trailing "Other" entry rather than growing the palette.
    let categoryBreakdown: [CategorySpending]

    /// Spent on transactions with a `recurrentFrequency` set, vs. one-off spend.
    /// `recurringSpent + oneTimeSpent == totalSpent`.
    let recurringSpent: Decimal
    let oneTimeSpent: Decimal

    static let empty = PeriodAnalytics(
        totalSpent: 0,
        transactionCount: 0,
        minTransaction: nil,
        maxTransaction: nil,
        transactionAmounts: [],
        minTransactionIndex: nil,
        maxTransactionIndex: nil,
        minSpendingDay: nil,
        maxSpendingDay: nil,
        dailyTotals: [],
        minDayIndex: nil,
        maxDayIndex: nil,
        categoryBreakdown: [],
        recurringSpent: 0,
        oneTimeSpent: 0
    )
}
