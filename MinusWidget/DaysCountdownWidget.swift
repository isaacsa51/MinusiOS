//
//  DaysCountdownWidget.swift
//  MinusWidget
//

import WidgetKit
import SwiftUI

struct DaysCountdownEntry: TimelineEntry {
    let date: Date
    let startDate: Date
    let endDate: Date
}

struct DaysCountdownProvider: TimelineProvider {
    func placeholder(in context: Context) -> DaysCountdownEntry {
        .sample
    }

    func getSnapshot(in context: Context, completion: @escaping (DaysCountdownEntry) -> Void) {
        completion(context.isPreview ? .sample : currentEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<DaysCountdownEntry>) -> Void) {
        let calendar = Calendar.current
        let nextMidnight = calendar.nextDate(after: .now, matching: DateComponents(hour: 0, minute: 0), matchingPolicy: .nextTime) ?? calendar.date(byAdding: .hour, value: 1, to: .now) ?? .now
        completion(Timeline(entries: [currentEntry()], policy: .after(nextMidnight)))
    }

    private func currentEntry() -> DaysCountdownEntry {
        guard let data = BudgetOverviewSnapshotStore.read() else { return .empty }
        return DaysCountdownEntry(date: .now, startDate: data.startDate, endDate: data.endDate)
    }
}

extension DaysCountdownEntry {
    static var sample: DaysCountdownEntry {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let start = calendar.date(byAdding: .day, value: -27, to: today) ?? today
        let end = calendar.date(byAdding: .day, value: 3, to: today) ?? today
        return DaysCountdownEntry(date: .now, startDate: start, endDate: end)
    }

    fileprivate static var empty: DaysCountdownEntry {
        let today = Calendar.current.startOfDay(for: .now)
        return DaysCountdownEntry(date: .now, startDate: today, endDate: today)
    }
}

struct DaysCountdownEntryView: View {
    var entry: DaysCountdownProvider.Entry
    @Environment(\.colorScheme) private var colorScheme

    private var palette: WidgetPalette { colorScheme == .dark ? .dark : .light }

    private var daysRemaining: Int {
        max(0, Calendar.current.dateComponents([.day], from: .now, to: entry.endDate).day ?? 0)
    }

    private var totalDays: Int {
        max(1, Calendar.current.dateComponents([.day], from: entry.startDate, to: entry.endDate).day ?? 1)
    }

    private var progressFraction: CGFloat {
        1 - (CGFloat(daysRemaining) / CGFloat(totalDays))
    }

    private var daysUnitLabel: String {
        daysRemaining == 1 ? String(localized: "day") : String(localized: "days")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("\(daysRemaining) \(daysUnitLabel)")
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(palette.textPrimary)

            Text(String(localized: "remaining"))
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(palette.textSecondary)

            Spacer(minLength: 0)

            GeometryReader { geo in
                let diameter = min(geo.size.width, geo.size.height) * 0.72
                HStack {
                    Spacer()
                    ring(diameter: diameter)
                }
                .frame(maxHeight: .infinity, alignment: .bottom)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(4)
        .containerBackground(for: .widget) {
            palette.background
        }
    }

    private func ring(diameter: CGFloat) -> some View {
        let lineWidth = max(4, diameter * 0.11)
        return ZStack {
            Circle()
                .stroke(palette.textSecondary.opacity(0.25), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: progressFraction)
                .stroke(palette.textPrimary, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
        .frame(width: diameter, height: diameter)
    }
}

struct DaysCountdownWidget: Widget {
    let kind: String = "DaysCountdown"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: DaysCountdownProvider()) { entry in
            DaysCountdownEntryView(entry: entry)
        }
        .configurationDisplayName(String(localized: "Days Remaining"))
        .description(String(localized: "A countdown ring for the days left in your active budget period."))
        .supportedFamilies([.systemSmall])
    }
}

#Preview(as: .systemSmall) {
    DaysCountdownWidget()
} timeline: {
    DaysCountdownEntry.sample
}
