//
//  BudgetOverviewWidget.swift
//  MinusWidget
//
//  Created by Isaac Emmanuel Serrano Altamirano on 26/08/26.
//

import WidgetKit
import SwiftUI

struct BudgetOverviewEntry: TimelineEntry {
    let date: Date
    let totalBudget: Decimal
    let currencySymbol: String
    let startDate: Date
    let endDate: Date
}

struct BudgetOverviewProvider: TimelineProvider {
    func placeholder(in context: Context) -> BudgetOverviewEntry {
        .sample
    }

    func getSnapshot(in context: Context, completion: @escaping (BudgetOverviewEntry) -> Void) {
        completion(context.isPreview ? .sample : currentEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<BudgetOverviewEntry>) -> Void) {
        let nextReload = Calendar.current.date(byAdding: .hour, value: 1, to: .now) ?? .now
        completion(Timeline(entries: [currentEntry()], policy: .after(nextReload)))
    }

    private func currentEntry() -> BudgetOverviewEntry {
        guard let data = BudgetOverviewSnapshotStore.read() else { return .empty }
        return BudgetOverviewEntry(
            date: .now,
            totalBudget: Decimal(data.totalBudget),
            currencySymbol: data.currencySymbol,
            startDate: data.startDate,
            endDate: data.endDate
        )
    }
}

extension BudgetOverviewEntry {
    // Internal (not file-private) so preview code elsewhere — e.g. the
    // consolidated widget gallery preview in MinusWidgetBundle.swift — can
    // reuse the same mock data instead of duplicating it.
    static var sample: BudgetOverviewEntry {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let start = calendar.date(byAdding: .day, value: -2, to: today) ?? today
        return BudgetOverviewEntry(
            date: .now,
            totalBudget: 12345.56,
            currencySymbol: "$",
            startDate: start,
            endDate: today
        )
    }

    fileprivate static var empty: BudgetOverviewEntry {
        let today = Calendar.current.startOfDay(for: .now)
        return BudgetOverviewEntry(date: .now, totalBudget: 0, currencySymbol: "$", startDate: today, endDate: today)
    }
}

struct BudgetOverviewEntryView: View {
    var entry: BudgetOverviewProvider.Entry
    @Environment(\.colorScheme) private var colorScheme

    private var palette: WidgetPalette { colorScheme == .dark ? .dark : .light }

    private var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return "\(entry.currencySymbol)\(formatter.string(from: entry.totalBudget as NSDecimalNumber) ?? "0.00")"
    }

    private var startDateText: String { Self.dateFormatter.string(from: entry.startDate) }
    private var endDateText: String { Self.dateFormatter.string(from: entry.endDate) }

    private static let dateFormatter: DateFormatter = {
        let fmt = DateFormatter()
        fmt.dateFormat = "d MMM"
        fmt.locale = Locale.autoupdatingCurrent
        return fmt
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(formattedAmount)
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundStyle(palette.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)

            Text(String(localized: "Total budget"))
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(palette.textSecondary)

            Spacer(minLength: 8)

            HStack(spacing: 6) {
                Text(startDateText)
                ArrowLine()
                    .stroke(palette.textSecondary, style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))
                    .frame(maxWidth: .infinity)
                    .frame(height: 8)
                Text(endDateText)
            }
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(palette.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(16)
        .containerBackground(for: .widget) {
            palette.background
        }
    }
}

private struct ArrowLine: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let midY = rect.midY
        let headLength: CGFloat = 5
        let lineEndX = rect.maxX - headLength

        path.move(to: CGPoint(x: rect.minX, y: midY))
        path.addLine(to: CGPoint(x: lineEndX, y: midY))

        path.move(to: CGPoint(x: lineEndX - headLength * 0.6, y: midY - headLength * 0.6))
        path.addLine(to: CGPoint(x: rect.maxX, y: midY))
        path.addLine(to: CGPoint(x: lineEndX - headLength * 0.6, y: midY + headLength * 0.6))

        return path
    }
}

struct BudgetOverviewWidget: Widget {
    let kind: String = "BudgetOverview"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: BudgetOverviewProvider()) { entry in
            BudgetOverviewEntryView(entry: entry)
        }
        .configurationDisplayName(String(localized: "Budget Overview"))
        .description(String(localized: "Shows your total budget and its date range."))
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

#Preview(as: .systemMedium) {
    BudgetOverviewWidget()
} timeline: {
    BudgetOverviewEntry.sample
}
