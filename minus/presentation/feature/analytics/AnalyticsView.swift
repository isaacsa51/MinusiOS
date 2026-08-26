//
//  AnalyticsView.swift
//  minus
//

import SwiftUI

struct AnalyticsView: View {
    @Environment(NavigationRouter.self) private var router
    @Environment(\.dependencies) private var dependencies
    @State private var viewModel: AnalyticsViewModel?

    var periodId: UUID? = nil

    var body: some View {
        Group {
            if let viewModel {
                content(for: viewModel)
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(Color.minus.background.ignoresSafeArea())
        .navigationTitle(navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    router.navigate(to: .pastPeriods)
                } label: {
                    Image(systemName: "clock.arrow.circlepath")
                }
                .accessibilityLabel("Past budget periods")
            }
        }
        .task {
            guard viewModel == nil else { return }
            let vm = AnalyticsViewModel(periodRepo: dependencies.periodRepository, transactionRepo: dependencies.transactionRepository)
            viewModel = vm
            await vm.load(periodId: periodId)
        }
    }

    private var navigationTitle: String {
        guard periodId != nil, let period = viewModel?.displayedPeriod else {
            return String(localized: "Analytics")
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        formatter.locale = Locale(identifier: "en_US")
        return "\(formatter.string(from: period.startDate)) – \(formatter.string(from: period.effectiveEndDate))"
    }

    @ViewBuilder
    private func content(for viewModel: AnalyticsViewModel) -> some View {
        if viewModel.isLoading {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let period = viewModel.displayedPeriod, viewModel.analytics.transactionCount > 0 {
            ScrollView {
                VStack(spacing: 20) {
                    totalTrendCard(viewModel)

                    dailyAverageCard(viewModel)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        MinMaxSpentCard(
                            title: "Smallest Expense",
                            value: viewModel.analytics.minTransaction.map { viewModel.formattedAmount($0.amount) } ?? "--",
                            subtitle: viewModel.analytics.minTransaction.map { viewModel.formattedDate($0.createdAt) },
                            categoryLabel: viewModel.analytics.minTransaction?.categoryName,
                            trendValues: viewModel.transactionTrendValues,
                            highlightIndex: viewModel.analytics.minTransactionIndex,
                            markerAnchor: .start,
                            tint: .spendingHeat(0),
                            textGradientEdge: .top
                        )
                        MinMaxSpentCard(
                            title: "Largest Expense",
                            value: viewModel.analytics.maxTransaction.map { viewModel.formattedAmount($0.amount) } ?? "--",
                            subtitle: viewModel.analytics.maxTransaction.map { viewModel.formattedDate($0.createdAt) },
                            categoryLabel: viewModel.analytics.maxTransaction?.categoryName,
                            trendValues: viewModel.transactionTrendValues,
                            highlightIndex: viewModel.analytics.maxTransactionIndex,
                            markerAnchor: .end,
                            tint: .spendingHeat(1),
                            textGradientEdge: .bottom
                        )
                    }

                    SpendingHeatmapCalendar(period: period, dailyTotals: viewModel.analytics.dailyTotals)

                    categoryBreakdownCard(viewModel)

                    savingsRecommendationCard(viewModel)
                }
                .padding(20)
            }
        } else if viewModel.displayedPeriod == nil {
            emptyState(message: periodId == nil ? "No active budget period yet." : "Budget period not found.")
        } else {
            emptyState(message: "No spending recorded for this period yet.")
        }
    }

    private func totalTrendCard(_ viewModel: AnalyticsViewModel) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Total Spent")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.minus.textSecondary)

                Text(viewModel.formattedAmount(viewModel.analytics.totalSpent))
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .minimumScaleFactor(0.8)
                    .lineLimit(1)
                    .foregroundStyle(Color.minus.textPrimary)

                Text("\(viewModel.analytics.transactionCount) transactions this period")
                    .font(.caption)
                    .foregroundStyle(Color.minus.textSecondary)
            }

            CumulativeSpendChart(
                points: viewModel.totalTrendPoints,
                startLabel: viewModel.totalTrendStartLabel,
                endLabel: viewModel.totalTrendEndLabel,
                peakLabel: viewModel.totalTrendPeakLabel
            )
        }
        .padding(20)
        .background(Color.minus.surface)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: Color.primary.opacity(0.12), radius: 10, x: 0, y: 5)
    }

    private func dailyAverageCard(_ viewModel: AnalyticsViewModel) -> some View {
        HStack {
            Text("Daily Average")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(Color.minus.textSecondary)

            Spacer()

            Text(viewModel.dailyAverageSpent)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(Color.minus.textPrimary)
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(Color.minus.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func categoryBreakdownCard(_ viewModel: AnalyticsViewModel) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Spending by Category")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(Color.minus.textSecondary)

            VStack(spacing: 16) {
                ForEach(Array(viewModel.analytics.categoryBreakdown.enumerated()), id: \.element.id) { index, category in
                    CategoryBreakdownRow(
                        name: category.name,
                        amount: viewModel.formattedAmount(category.amount),
                        percentageLabel: viewModel.percentageLabel(category.percentage),
                        fraction: category.percentage,
                        color: .categorical(at: index)
                    )
                }
            }
        }
        .padding(20)
        .background(Color.minus.surface)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func savingsRecommendationCard(_ viewModel: AnalyticsViewModel) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Savings Recommendation", systemImage: "info.circle")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(Color.minus.textSecondary)

            VStack(alignment: .leading, spacing: 8) {
                Text("The 50/30/20 method splits your budget into 50% needs, 30% wants, and 20% savings — helping you control spending and save consistently.")

                Text("If you save 20% every period for about 6 periods, you could build:")

                Text(viewModel.sixPeriodProjectionText)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.minus.textPrimary)
            }
            .font(.system(size: 14))
            .foregroundStyle(Color.minus.textSecondary)

            VStack(alignment: .leading, spacing: 8) {
                Text("Current Savings")
                    .font(.subheadline)
                    .foregroundStyle(Color.minus.textSecondary)

                Text(viewModel.savingsPercentageLabel)
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(viewModel.savingsGoalMet ? Color.spendingHeat(0) : Color.spendingHeat(1))

                SavingsProgressBar(
                    achievementRatio: viewModel.savingsAchievementRatio,
                    goalMet: viewModel.savingsGoalMet
                )

                HStack(alignment: .top) {
                    Text("Available: \(viewModel.formattedAmount(viewModel.actualSavings))")
                        .foregroundStyle(Color.minus.textSecondary)

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Ideal savings: \(viewModel.formattedAmount(viewModel.idealSavings))")
                            .strikethrough()
                            .foregroundStyle(Color.minus.textSecondary)
                        Text("Current savings: \(viewModel.formattedAmount(viewModel.actualSavings))")
                            .fontWeight(.semibold)
                            .foregroundStyle(viewModel.savingsGoalMet ? Color.spendingHeat(0) : Color.spendingHeat(1))
                    }
                }
                .font(.caption)
            }

            Divider()

            VStack(spacing: 10) {
                if viewModel.hasRecurringPayments {
                    savingsLegendRow(
                        title: "Recurring Expenses",
                        value: viewModel.recurringSpendLabel,
                        color: Color.minus.textSecondary
                    )
                }
                savingsLegendRow(
                    title: "One-Time Expenses",
                    value: viewModel.oneTimeSpendLabel,
                    color: viewModel.savingsGoalMet ? Color.spendingHeat(0) : Color.spendingHeat(1)
                )
            }

            if periodId == nil {
                Button {
                    router.shouldPresentNewBudgetSheet = true
                    router.popToRoot()
                } label: {
                    Text("New Savings Period")
                        .font(.system(size: 16, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.minus.primaryAction)
                        .foregroundStyle(Color.minus.background)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(20)
        .background(Color.minus.surface)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func savingsLegendRow(title: LocalizedStringKey, value: String, color: Color) -> some View {
        HStack {
            HStack(spacing: 8) {
                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)
                Text(title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Color.minus.textPrimary)
            }

            Spacer()

            Text(value)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(color)
        }
    }

    private func emptyState(message: LocalizedStringKey) -> some View {
        VStack(spacing: 8) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 32))
                .foregroundStyle(Color.minus.textSecondary)
            Text(message)
                .font(.system(size: 15))
                .foregroundStyle(Color.minus.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(40)
    }
}

private class PreviewPeriodRepository: PeriodRepository {
    func save(period: PeriodKey) async throws {}
    func getPeriod(id: UUID) async throws -> PeriodKey? { nil }
    func getPeriod(byExternalId externalId: String) async throws -> PeriodKey? { nil }
    func getActivePeriod() async throws -> PeriodKey? {
        PeriodKey(
            id: UUID(),
            startDate: Calendar.current.date(byAdding: .day, value: -10, to: Date())!,
            endDate: Calendar.current.date(byAdding: .day, value: 20, to: Date()),
            mappingNode: .activeBucket,
            totalBudget: 15000,
            currency: "MXN",
            remainingStrategy: .SPLIT_EQUALLY,
            periodType: .monthly,
            daysInPeriod: 30
        )
    }
    func getAllPeriods() async throws -> [PeriodKey] { [] }
    func closePeriod(id: UUID, finalEndDate: Date) async throws {}
}

private class PreviewTransactionRepository: TransactionRepository {
    func save(transaction: Transaction) async throws {}
    func delete(transactionId: UUID) async throws {}
    func getTransaction(id: UUID) async throws -> Transaction? { nil }
    func getTransaction(byClientGeneratedId clientGeneratedId: String) async throws -> Transaction? { nil }
    func getAllTransactions() async throws -> [Transaction] { [] }
    func getTransactions(forCategory categoryId: UUID) async throws -> [Transaction] { [] }
    func getTransactions(between startDate: Date, and endDate: Date) async throws -> [Transaction] { [] }

    func getTransactions(forPeriod periodId: UUID) async throws -> [Transaction] {
        let categories: [(String, Double)] = [
            ("Groceries", 340), ("Transport", 210), ("Entertainment", 120),
            ("Coffee", 30), ("Rent", 500), ("Utilities", 90), ("Health", 45), ("Gifts", 25), ("Misc", 15)
        ]
        return categories.enumerated().map { index, entry in
            Transaction(
                id: UUID(),
                amount: Decimal(entry.1),
                createdAt: Calendar.current.date(byAdding: .day, value: -index, to: Date()) ?? Date(),
                clientGeneratedId: UUID().uuidString,
                periodId: periodId,
                categoryId: UUID(),
                categoryName: entry.0,
                isIncome: false
            )
        }
    }
}

#Preview {
    NavigationStack {
        AnalyticsView()
            .environment(NavigationRouter())
            .environment(\.dependencies, .preview(
                transactionRepository: PreviewTransactionRepository(),
                periodRepository: PreviewPeriodRepository()
            ))
    }
}
