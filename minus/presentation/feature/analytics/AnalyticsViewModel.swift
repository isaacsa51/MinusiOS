//
//  AnalyticsViewModel.swift
//  minus
//

import SwiftUI

@MainActor
@Observable
class AnalyticsViewModel {
    var displayedPeriod: PeriodKey?
    var analytics: PeriodAnalytics = .empty
    var isLoading = true
    var errorMessage: String?

    private let getCurrentPeriodUseCase: GetCurrentPeriodIdIUseCase
    private let getPeriodUseCase: GetPeriodUseCase
    private let getPeriodAnalyticsUseCase: GetPeriodAnalyticsUseCase

    init(periodRepo: PeriodRepository, transactionRepo: TransactionRepository) {
        self.getCurrentPeriodUseCase = GetCurrentPeriodIdIUseCase(repository: periodRepo)
        self.getPeriodUseCase = GetPeriodUseCase(repository: periodRepo)
        self.getPeriodAnalyticsUseCase = GetPeriodAnalyticsUseCase(transactionRepository: transactionRepo)
    }

    func load(periodId: UUID? = nil) async {
        isLoading = true
        do {
            let period: PeriodKey?
            if let periodId {
                period = try await getPeriodUseCase.execute(id: periodId)
            } else {
                period = try await getCurrentPeriodUseCase.execute()
            }
            displayedPeriod = period
            if let period {
                analytics = try await getPeriodAnalyticsUseCase.execute(periodId: period.id)
            } else {
                analytics = .empty
            }

            // Only the active period (periodId == nil means "load whatever's
            // active") should drive the widget — browsing a past period here
            // shouldn't overwrite it with stale history.
            if periodId == nil {
                SpendingHeatmapSnapshotWriter.refresh(period: period, expenses: analytics.expenses)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private var currencySymbol: String {
        Currency.find(byCode: displayedPeriod?.currency ?? "")?.symbol ?? "$"
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

    func formattedDate(_ date: Date) -> String {
        Self.transactionDateFormatter.string(from: date)
    }

    func percentageLabel(_ fraction: Double) -> String {
        "\(Int((fraction * 100).rounded()))%"
    }

    var dailyTrendValues: [Double] {
        analytics.dailyTotals.map { NSDecimalNumber(decimal: $0.amount).doubleValue }
    }

    var transactionTrendValues: [Double] {
        analytics.transactionAmounts.map { NSDecimalNumber(decimal: $0).doubleValue }
    }

    var dailyAverageSpent: String {
        guard let period = displayedPeriod else { return formattedAmount(0) }

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
        guard let period = displayedPeriod, !analytics.dailyTotals.isEmpty else { return [] }

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

    var totalTrendPoints: [CumulativeSpendPoint] {
        cumulativeBuckets.map { CumulativeSpendPoint(date: $0.date, total: NSDecimalNumber(decimal: $0.total).doubleValue) }
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

    var idealSavings: Decimal {
        (displayedPeriod?.totalBudget ?? 0) * 0.20
    }

    var actualSavings: Decimal {
        max(0, (displayedPeriod?.totalBudget ?? 0) - analytics.totalSpent)
    }

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

    var sixPeriodProjectionText: String {
        let projected = idealSavings * 6
        return "\(formattedAmount(idealSavings)) \u{00D7} 6 = \(formattedAmount(projected))"
    }

    var hasRecurringPayments: Bool {
        analytics.recurringSpent > 0
    }

    private func budgetShareLabel(_ amount: Decimal) -> String {
        guard let budget = displayedPeriod?.totalBudget, budget > 0 else { return "0%" }
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

    private static let transactionDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMMM"
        formatter.locale = Locale(identifier: "en_US")
        return formatter
    }()
}
