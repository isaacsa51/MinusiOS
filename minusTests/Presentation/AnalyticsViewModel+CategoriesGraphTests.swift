//
//  AnalyticsViewModel+CategoriesGraphTests.swift
//  minusTests
//

import Testing
import Foundation
@testable import minus

@MainActor
struct AnalyticsViewModelCategoriesGraphTests {
    private static let calendar = Calendar.current

    private func makeViewModel(
        expenses: [Transaction],
        categoryBreakdown: [CategorySpending] = []
    ) -> AnalyticsViewModel {
        let viewModel = AnalyticsViewModel(
            periodRepo: InMemoryPeriodRepository(),
            transactionRepo: InMemoryTransactionRepository()
        )
        viewModel.analytics = PeriodAnalytics(
            totalSpent: expenses.reduce(Decimal.zero) { $0 + $1.amount },
            transactionCount: expenses.count,
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
            categoryBreakdown: categoryBreakdown,
            recurringSpent: 0,
            oneTimeSpent: 0,
            expenses: expenses
        )
        return viewModel
    }

    private func makeTransaction(amount: Decimal, createdAt: Date, categoryName: String?) -> Transaction {
        Transaction(
            id: UUID(),
            amount: amount,
            createdAt: createdAt,
            clientGeneratedId: UUID().uuidString,
            periodId: UUID(),
            categoryId: UUID(),
            categoryName: categoryName
        )
    }

    private func makePeriod(startDate: Date, endDate: Date?, daysInPeriod: Int) -> PeriodKey {
        PeriodKey(
            id: UUID(),
            startDate: startDate,
            endDate: endDate,
            mappingNode: .activeBucket,
            totalBudget: 1000,
            currency: "USD",
            remainingStrategy: .SPLIT_EQUALLY,
            periodType: .monthly,
            daysInPeriod: daysInPeriod
        )
    }

    private func category(_ name: String, amount: Decimal = 0) -> CategorySpending {
        CategorySpending(id: UUID(), name: name, amount: amount, percentage: 0)
    }

    @Test func givenTransactionsOnSameDayThenBucketsGroupByDay() {
        let dayOne = Self.calendar.date(from: DateComponents(year: 2026, month: 8, day: 1, hour: 9))!
        let dayOneLater = Self.calendar.date(from: DateComponents(year: 2026, month: 8, day: 1, hour: 18))!
        let dayTwo = Self.calendar.date(from: DateComponents(year: 2026, month: 8, day: 2, hour: 9))!
        let expenses = [
            makeTransaction(amount: 10, createdAt: dayOne, categoryName: "Groceries"),
            makeTransaction(amount: 5, createdAt: dayOneLater, categoryName: "Groceries"),
            makeTransaction(amount: 20, createdAt: dayTwo, categoryName: "Groceries"),
        ]
        let viewModel = makeViewModel(expenses: expenses, categoryBreakdown: [category("Groceries")])

        let until = Self.calendar.date(byAdding: .day, value: 1, to: dayTwo)!
        let buckets = viewModel.categoryStackedBuckets(from: dayOne, until: until, unit: .day)

        #expect(buckets.count == 2)
        #expect(buckets[0].amountsByCategory["Groceries"] == 15)
        #expect(buckets[1].amountsByCategory["Groceries"] == 20)
    }

    @Test func givenTransactionsInDifferentHoursThenBucketsGroupByHour() {
        let morning = Self.calendar.date(from: DateComponents(year: 2026, month: 8, day: 1, hour: 9))!
        let evening = Self.calendar.date(from: DateComponents(year: 2026, month: 8, day: 1, hour: 20))!
        let expenses = [
            makeTransaction(amount: 8, createdAt: morning, categoryName: "Coffee"),
            makeTransaction(amount: 40, createdAt: evening, categoryName: "Coffee"),
        ]
        let viewModel = makeViewModel(expenses: expenses, categoryBreakdown: [category("Coffee")])

        let start = Self.calendar.startOfDay(for: morning)
        let until = Self.calendar.date(byAdding: .day, value: 1, to: start)!
        let buckets = viewModel.categoryStackedBuckets(from: start, until: until, unit: .hour)

        #expect(buckets.count == 2)
        #expect(buckets[0].amountsByCategory["Coffee"] == 8)
        #expect(buckets[1].amountsByCategory["Coffee"] == 40)
    }

    @Test func givenTransactionAtWindowUpperBoundThenBucketsExcludeIt() {
        let start = Self.calendar.date(from: DateComponents(year: 2026, month: 8, day: 1))!
        let boundary = Self.calendar.date(from: DateComponents(year: 2026, month: 8, day: 2))!
        let expenses = [makeTransaction(amount: 99, createdAt: boundary, categoryName: "Groceries")]
        let viewModel = makeViewModel(expenses: expenses, categoryBreakdown: [category("Groceries")])

        let buckets = viewModel.categoryStackedBuckets(from: start, until: boundary, unit: .day)

        #expect(buckets.isEmpty)
    }

    @Test func givenUnknownCategoryThenBucketFoldsIntoOther() {
        let date = Self.calendar.date(from: DateComponents(year: 2026, month: 8, day: 1, hour: 9))!
        let expenses = [makeTransaction(amount: 12, createdAt: date, categoryName: "Obscure Hobby")]
        let viewModel = makeViewModel(
            expenses: expenses,
            categoryBreakdown: [category("Groceries"), category("Other")]
        )

        let until = Self.calendar.date(byAdding: .day, value: 1, to: date)!
        let buckets = viewModel.categoryStackedBuckets(from: date, until: until, unit: .day)

        #expect(buckets.first?.amountsByCategory["Other"] == 12)
        #expect(buckets.first?.amountsByCategory["Obscure Hobby"] == nil)
    }

    @Test func givenNilCategoryNameThenBucketResolvesToUncategorized() {
        let date = Self.calendar.date(from: DateComponents(year: 2026, month: 8, day: 1, hour: 9))!
        let expenses = [makeTransaction(amount: 7, createdAt: date, categoryName: nil)]
        let viewModel = makeViewModel(
            expenses: expenses,
            categoryBreakdown: [category("Uncategorized")]
        )

        let until = Self.calendar.date(byAdding: .day, value: 1, to: date)!
        let buckets = viewModel.categoryStackedBuckets(from: date, until: until, unit: .day)

        #expect(buckets.first?.amountsByCategory["Uncategorized"] == 7)
    }

    @Test func givenActivePeriodThenDefaultPageIndexLandsOnTodaysPage() {
        let start = Self.calendar.date(byAdding: .day, value: -5, to: Self.calendar.startOfDay(for: Date()))!
        let period = makePeriod(startDate: start, endDate: nil, daysInPeriod: 30)
        let viewModel = makeViewModel(expenses: [])

        let pageIndex = viewModel.defaultPageIndex(for: .day, period: period)

        #expect(pageIndex == 5)
    }

    @Test func givenClosedPastPeriodThenDefaultPageIndexClampsToLastPage() {
        let start = Self.calendar.date(byAdding: .day, value: -30, to: Self.calendar.startOfDay(for: Date()))!
        let end = Self.calendar.date(byAdding: .day, value: -25, to: Self.calendar.startOfDay(for: Date()))!
        let period = makePeriod(startDate: start, endDate: end, daysInPeriod: 6)
        let viewModel = makeViewModel(expenses: [])

        let pageIndex = viewModel.defaultPageIndex(for: .week, period: period)
        let data = viewModel.timeRangeNavigatorData(mode: .week, pageIndex: pageIndex, period: period)

        #expect(pageIndex == data.pageCount - 1)
    }

    @Test func givenTotalModeThenDefaultPageIndexIsZero() {
        let period = makePeriod(startDate: Date(), endDate: nil, daysInPeriod: 30)
        let viewModel = makeViewModel(expenses: [])

        let pageIndex = viewModel.defaultPageIndex(for: .total, period: period)

        #expect(pageIndex == 0)
    }

    @Test func givenTotalModeThenGraphDataSpansWholePeriod() {
        let start = Self.calendar.startOfDay(for: Date())
        let end = Self.calendar.date(byAdding: .day, value: 9, to: start)!
        let period = makePeriod(startDate: start, endDate: end, daysInPeriod: 10)
        let viewModel = makeViewModel(expenses: [])

        let data = viewModel.categoriesGraphData(mode: .total, pageIndex: 0, period: period)

        #expect(data.axisUnit == .day)
        #expect(Self.calendar.isDate(data.xDomain.lowerBound, inSameDayAs: start))
    }

    @Test func givenDayModeThenGraphDataUsesHourlyAxisAndHidesTodayMarker() {
        let start = Self.calendar.date(byAdding: .day, value: -3, to: Self.calendar.startOfDay(for: Date()))!
        let period = makePeriod(startDate: start, endDate: nil, daysInPeriod: 30)
        let viewModel = makeViewModel(expenses: [])
        let pageIndex = viewModel.defaultPageIndex(for: .day, period: period)

        let data = viewModel.categoriesGraphData(mode: .day, pageIndex: pageIndex, period: period)

        #expect(data.axisUnit == .hour)
        #expect(data.today == nil)
    }

    @Test func givenWeekModeThenNavigatorDataReturnsRangeLabelAndPageCount() {
        let start = Self.calendar.startOfDay(for: Date())
        let period = makePeriod(startDate: start, endDate: nil, daysInPeriod: 14)
        let viewModel = makeViewModel(expenses: [])

        let data = viewModel.timeRangeNavigatorData(mode: .week, pageIndex: 0, period: period)

        #expect(data.label.contains("–"))
        #expect(data.pageCount == 2)
    }
}
