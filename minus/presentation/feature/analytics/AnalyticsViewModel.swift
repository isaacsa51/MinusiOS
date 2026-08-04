//
//  AnalyticsViewModel.swift
//  minus
//

import SwiftUI

@MainActor
@Observable
class AnalyticsViewModel {
    var activePeriod: PeriodKey?
    var analytics: PeriodAnalytics = .empty
    var isLoading = true
    var errorMessage: String?

    private let getCurrentPeriodUseCase: GetCurrentPeriodIdIUseCase
    private let getPeriodAnalyticsUseCase: GetPeriodAnalyticsUseCase

    init(periodRepo: PeriodRepository, transactionRepo: TransactionRepository) {
        self.getCurrentPeriodUseCase = GetCurrentPeriodIdIUseCase(repository: periodRepo)
        self.getPeriodAnalyticsUseCase = GetPeriodAnalyticsUseCase(transactionRepository: transactionRepo)
    }

    func load() async {
        isLoading = true
        do {
            let period = try await getCurrentPeriodUseCase.execute()
            activePeriod = period
            if let period {
                analytics = try await getPeriodAnalyticsUseCase.execute(periodId: period.id)
            } else {
                analytics = .empty
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private var currencySymbol: String {
        Currency.find(byCode: activePeriod?.currency ?? "")?.symbol ?? "$"
    }

    func formattedAmount(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return "\(currencySymbol)\(formatter.string(from: amount as NSDecimalNumber) ?? "0.00")"
    }

    func formattedDay(_ date: Date) -> String {
        Self.dayFormatter.string(from: date)
    }

    func formattedDateTime(_ date: Date) -> String {
        Self.dateTimeFormatter.string(from: date)
    }

    func percentageLabel(_ fraction: Double) -> String {
        "\(Int((fraction * 100).rounded()))%"
    }

    /// Daily totals, chronological, for the highest/lowest-day tiles' background sparkline.
    var dailyTrendValues: [Double] {
        analytics.dailyTotals.map { NSDecimalNumber(decimal: $0.amount).doubleValue }
    }

    /// Expense amounts, chronological, for the largest/smallest-expense tiles' background sparkline.
    var transactionTrendValues: [Double] {
        analytics.transactionAmounts.map { NSDecimalNumber(decimal: $0).doubleValue }
    }

    /// Total spent divided by days elapsed so far in the period — not the
    /// full period length, so it isn't deflated by days that haven't happened yet.
    var dailyAverageSpent: String {
        guard let period = activePeriod else { return formattedAmount(0) }

        let calendar = Calendar.current
        let start = calendar.startOfDay(for: period.startDate)
        let today = calendar.startOfDay(for: Date())
        let latestElapsedDay = min(today, calendar.startOfDay(for: period.effectiveEndDate))

        let daysElapsed = (calendar.dateComponents([.day], from: start, to: latestElapsedDay).day ?? 0) + 1
        let divisor = max(1, min(daysElapsed, period.daysInPeriod))

        return formattedAmount(analytics.totalSpent / Decimal(divisor))
    }

    /// Running total of spend, one point per day elapsed so far in the
    /// period — stops at today rather than running out to the period's
    /// (possibly still-future) end date.
    private var cumulativeBuckets: [(date: Date, total: Decimal)] {
        guard let period = activePeriod, !analytics.dailyTotals.isEmpty else { return [] }

        let calendar = Calendar.current
        let amountByDay = Dictionary(uniqueKeysWithValues: analytics.dailyTotals.map {
            (calendar.startOfDay(for: $0.date), $0.amount)
        })

        let start = calendar.startOfDay(for: period.startDate)
        let end = min(calendar.startOfDay(for: Date()), calendar.startOfDay(for: period.effectiveEndDate))

        var buckets: [(Date, Decimal)] = []
        var runningTotal: Decimal = 0
        var cursor = start
        while cursor <= end {
            runningTotal += amountByDay[cursor] ?? 0
            buckets.append((cursor, runningTotal))
            cursor = calendar.date(byAdding: .day, value: 1, to: cursor) ?? end.addingTimeInterval(1)
        }
        return buckets
    }

    var totalTrendValues: [Double] {
        cumulativeBuckets.map { NSDecimalNumber(decimal: $0.total).doubleValue }
    }

    var totalTrendStartLabel: String {
        cumulativeBuckets.first.map { formattedDay($0.date) } ?? ""
    }

    var totalTrendEndLabel: String {
        cumulativeBuckets.last.map { formattedDay($0.date) } ?? ""
    }

    var totalTrendPeakLabel: String {
        formattedAmount(cumulativeBuckets.map(\.total).max() ?? 0)
    }

    /// The 50/30/20 method's savings slice: 20% of the period's budget.
    var idealSavings: Decimal {
        (activePeriod?.totalBudget ?? 0) * 0.20
    }

    /// What's actually left once spending is subtracted — floored at 0
    /// (overspending doesn't produce "negative savings" here, just 0).
    var actualSavings: Decimal {
        max(0, (activePeriod?.totalBudget ?? 0) - analytics.totalSpent)
    }

    /// `actualSavings` as a fraction of `idealSavings`, uncapped (can exceed
    /// 1 if the savings goal was beaten) — for the percentage label.
    var savingsAchievementRatio: Double {
        guard idealSavings > 0 else { return 0 }
        return NSDecimalNumber(decimal: actualSavings / idealSavings).doubleValue
    }

    var savingsGoalMet: Bool {
        savingsAchievementRatio >= 1
    }

    var savingsPercentageLabel: String {
        "\(Int((savingsAchievementRatio * 100).rounded()))%"
    }

    /// Projected balance if the 20% ideal is hit every period for ~6 periods.
    var sixPeriodProjectionText: String {
        let projected = idealSavings * 6
        return "\(formattedAmount(idealSavings)) \u{00D7} 6 = \(formattedAmount(projected))"
    }

    var hasRecurringPayments: Bool {
        analytics.recurringSpent > 0
    }

    private func budgetShareLabel(_ amount: Decimal) -> String {
        guard let budget = activePeriod?.totalBudget, budget > 0 else { return "0%" }
        let percent = NSDecimalNumber(decimal: amount / budget * 100).doubleValue
        return "\(formattedAmount(amount)) (\(Int(percent.rounded()))%)"
    }

    var recurringSpendLabel: String { budgetShareLabel(analytics.recurringSpent) }
    var oneTimeSpendLabel: String { budgetShareLabel(analytics.oneTimeSpent) }

    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMM d"
        formatter.locale = Locale(identifier: "en_US")
        return formatter
    }()

    private static let dateTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM h:mm a"
        formatter.locale = Locale(identifier: "en_US")
        return formatter
    }()
}
