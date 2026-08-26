//
//  StackedCategoriesGraph.swift
//  minus
//

import Charts
import SwiftUI

struct StackedCategoriesGraph: View {
    let buckets: [AnalyticsViewModel.CategoryStackedBucket]
    let categoryOrder: [String]
    let categoryColors: [String: Color]
    let today: Date?
    let axisUnit: Calendar.Component
    let xDomain: ClosedRange<Date>
    let amountFormatter: (Double) -> String

    @State private var selectedDate: Date?

    private var selectedBucket: AnalyticsViewModel.CategoryStackedBucket? {
        guard let selectedDate else { return nil }
        return buckets.first { Calendar.current.isDate($0.date, equalTo: selectedDate, toGranularity: axisUnit) }
    }

    private struct DataPoint: Identifiable {
        let id = UUID()
        let date: Date
        let category: String
        let amount: Double
    }

    private var dataPoints: [DataPoint] {
        buckets.flatMap { bucket in
            categoryOrder.map { category in
                DataPoint(date: bucket.date, category: category, amount: bucket.amountsByCategory[category] ?? 0)
            }
        }
    }

    private var colorRange: [Color] {
        categoryOrder.map { categoryColors[$0] ?? Color.minus.textSecondary }
    }

    var body: some View {
        Chart {
            barMarks
            todayMark
            selectionMark
        }
        .chartForegroundStyleScale(domain: categoryOrder, range: colorRange)
        .chartXScale(domain: xDomain)
        .chartLegend(.hidden)
        .chartXAxis { xAxisContent }
        .chartOverlay { proxy in dragOverlay(proxy: proxy) }
    }

    @ChartContentBuilder
    private var barMarks: some ChartContent {
        ForEach(dataPoints) { point in
            BarMark(
                x: .value("Date", point.date, unit: axisUnit),
                y: .value("Amount", point.amount)
            )
            .foregroundStyle(by: .value("Category", point.category))
        }
    }

    @ChartContentBuilder
    private var todayMark: some ChartContent {
        if let today {
            RuleMark(x: .value("Today", today, unit: axisUnit))
                .lineStyle(StrokeStyle(lineWidth: 1))
                .foregroundStyle(Color.minus.textSecondary.opacity(0.5))
        }
    }

    @ChartContentBuilder
    private var selectionMark: some ChartContent {
        if let selectedBucket {
            RuleMark(x: .value("Selected", selectedBucket.date, unit: axisUnit))
                .lineStyle(StrokeStyle(lineWidth: 1))
                .foregroundStyle(Color.minus.textPrimary.opacity(0.4))
                .annotation(position: .top, spacing: 4) {
                    tooltip(for: selectedBucket)
                }
        }
    }

    /// Enough days to fit ~6 labels without crowding, regardless of whether
    /// the window is a 7-day week or a 30+ day month — a fixed daily stride
    /// reads fine for Week/Biweek but overlaps badly once Total spans a
    /// full period.
    private var dayAxisStrideCount: Int {
        let days = Calendar.current.dateComponents([.day], from: xDomain.lowerBound, to: xDomain.upperBound).day ?? 1
        return max(1, days / 6)
    }

    @AxisContentBuilder
    private var xAxisContent: some AxisContent {
        if axisUnit == .hour {
            AxisMarks(values: .stride(by: .hour, count: 6)) { value in
                AxisValueLabel { axisLabel(for: value) }
            }
        } else {
            AxisMarks(values: .stride(by: .day, count: dayAxisStrideCount)) { value in
                AxisValueLabel { axisLabel(for: value) }
            }
        }
    }

    @ViewBuilder
    private func axisLabel(for value: AxisValue) -> some View {
        if let date = value.as(Date.self) {
            let isToday = today.map { Calendar.current.isDate($0, equalTo: date, toGranularity: axisUnit) } ?? false
            Group {
                if axisUnit == .hour {
                    Text(date, format: .dateTime.hour())
                } else {
                    Text(date, format: .dateTime.day().month(.abbreviated))
                }
            }
            .fontWeight(isToday ? .bold : .regular)
            .foregroundStyle(isToday ? Color.minus.textPrimary : Color.minus.textSecondary)
        }
    }

    private func dragOverlay(proxy: ChartProxy) -> some View {
        GeometryReader { geo in
            Rectangle()
                .fill(.clear)
                .contentShape(Rectangle())
                .gesture(dragGesture(proxy: proxy, geo: geo))
        }
    }

    private func dragGesture(proxy: ChartProxy, geo: GeometryProxy) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                let originX = geo[proxy.plotAreaFrame].origin.x
                if let date: Date = proxy.value(atX: value.location.x - originX) {
                    selectedDate = date
                }
            }
            .onEnded { _ in selectedDate = nil }
    }

    private func tooltip(for bucket: AnalyticsViewModel.CategoryStackedBucket) -> some View {
        Text(amountFormatter(bucket.amountsByCategory.values.reduce(0, +)))
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundStyle(Color.minus.textPrimary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.minus.surfaceSecondary, in: Capsule())
    }
}

#Preview {
    let calendar = Calendar.current
    let today = calendar.startOfDay(for: Date())
    let categories = ["Groceries", "Transport", "Entertainment", "Coffee"]
    let colors = Dictionary(uniqueKeysWithValues: categories.enumerated().map { ($1, Color.categorical(at: $0)) })

    let buckets = (0..<10).map { offset -> AnalyticsViewModel.CategoryStackedBucket in
        let date = calendar.date(byAdding: .day, value: -offset, to: today)!
        let amounts = Dictionary(uniqueKeysWithValues: categories.map { ($0, Double.random(in: 5...120)) })
        return AnalyticsViewModel.CategoryStackedBucket(date: date, amountsByCategory: amounts)
    }
    let earliest = buckets.map(\.date).min() ?? today

    StackedCategoriesGraph(
        buckets: buckets,
        categoryOrder: categories,
        categoryColors: colors,
        today: today,
        axisUnit: .day,
        xDomain: earliest...today,
        amountFormatter: { "$\(String(format: "%.2f", $0))" }
    )
    .frame(height: 220)
    .padding()
    .background(Color.minus.surface)
    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    .padding()
    .background(Color.minus.background)
}
