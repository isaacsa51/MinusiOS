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
        BudgetOverviewSnapshotStore.readEntry() ?? .empty
    }
}

private struct BudgetOverviewSnapshot: Codable {
    let totalBudget: Double
    let currencySymbol: String
    let startDate: Date
    let endDate: Date
}

private enum BudgetOverviewSnapshotStore {
    private static let suiteName = "group.com.serranoie.ios.minus"
    private static let key = "budgetOverviewSnapshot"

    static func readEntry() -> BudgetOverviewEntry? {
        guard let defaults = UserDefaults(suiteName: suiteName),
              let data = defaults.data(forKey: key),
              let snapshot = try? JSONDecoder().decode(BudgetOverviewSnapshot.self, from: data) else {
            return nil
        }
        return BudgetOverviewEntry(
            date: .now,
            totalBudget: Decimal(snapshot.totalBudget),
            currencySymbol: snapshot.currencySymbol,
            startDate: snapshot.startDate,
            endDate: snapshot.endDate
        )
    }
}

private extension BudgetOverviewEntry {
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

    static var empty: BudgetOverviewEntry {
        let today = Calendar.current.startOfDay(for: .now)
        return BudgetOverviewEntry(date: .now, totalBudget: 0, currencySymbol: "$", startDate: today, endDate: today)
    }
}

struct BudgetOverviewEntryView: View {
    var entry: BudgetOverviewProvider.Entry
    @Environment(\.colorScheme) private var colorScheme

    private var palette: OverviewPalette { colorScheme == .dark ? .dark : .light }

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
        fmt.locale = Locale(identifier: "en_US")
        return fmt
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(formattedAmount)
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundStyle(palette.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)

            Text("Total budget")
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

private struct OverviewPalette {
    let background: Color
    let textPrimary: Color
    let textSecondary: Color

    static let light = OverviewPalette(
        background: Color(red: 0.9647, green: 0.9451, blue: 0.8941),   // #F6F1E4
        textPrimary: Color(red: 0.1059, green: 0.1059, blue: 0.0902),  // #1B1B17
        textSecondary: Color(red: 0.4784, green: 0.4667, blue: 0.4275) // #7A776D
    )

    static let dark = OverviewPalette(
        background: Color(red: 0.1059, green: 0.1059, blue: 0.0902),   // #1B1B17
        textPrimary: Color(red: 0.9647, green: 0.9451, blue: 0.8941),  // #F6F1E4
        textSecondary: Color(red: 0.6039, green: 0.5882, blue: 0.5412) // #9A968A
    )
}

struct BudgetOverviewWidget: Widget {
    let kind: String = "BudgetOverview"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: BudgetOverviewProvider()) { entry in
            BudgetOverviewEntryView(entry: entry)
        }
        .configurationDisplayName("Budget Overview")
        .description("Shows your total budget and its date range.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

#Preview(as: .systemMedium) {
    BudgetOverviewWidget()
} timeline: {
    BudgetOverviewEntry.sample
}
