import Foundation
import UserNotifications

class RecurringNotificationService {
    private static let reminderHour = 9
    private static let daysBeforeRange = stride(from: 3, through: 0, by: -1)

    static func requestAuthorizationIfNeeded() {
        Task {
            _ = try? await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
        }
    }

    static func schedule(
        transactionId: UUID,
        amount: Decimal,
        categoryName: String?,
        frequency: RecurrentFrequency,
        startDate: Date,
        endDate: Date?,
        subscriptionDay: Int?
    ) {
        cancel(transactionId: transactionId)

        guard let dueDate = nextDueDate(
            frequency: frequency,
            startDate: startDate,
            endDate: endDate,
            subscriptionDay: subscriptionDay
        ) else { return }

        let calendar = Calendar.current
        let category = categoryName?.trimmingCharacters(in: .whitespacesAndNewlines)
            .isEmpty == false ? categoryName! : String(localized: "Uncategorized")
        let amountText = formattedAmount(amount)
        let today = calendar.startOfDay(for: Date())

        Task {
            let center = UNUserNotificationCenter.current()
            for daysBefore in daysBeforeRange {
                guard let fireDay = calendar.date(byAdding: .day, value: -daysBefore, to: dueDate),
                      fireDay >= today else { continue }

                var fireComponents = calendar.dateComponents([.year, .month, .day], from: fireDay)
                fireComponents.hour = reminderHour

                let content = UNMutableNotificationContent()
                content.sound = .default
                content.body = daysBefore == 0
                    ? String(localized: "Your recurring payment \(category) of: \(amountText) is today.")
                    : String(localized: "Your recurring payment \(category) of: \(amountText) is due in \(daysBefore) \(daysBefore == 1 ? "day" : "days")")

                let request = UNNotificationRequest(
                    identifier: identifier(transactionId: transactionId, daysBefore: daysBefore),
                    content: content,
                    trigger: UNCalendarNotificationTrigger(dateMatching: fireComponents, repeats: false)
                )
                try? await center.add(request)
            }
        }
    }

    static func cancel(transactionId: UUID) {
        let ids = daysBeforeRange.map { identifier(transactionId: transactionId, daysBefore: $0) }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
    }

    // MARK: - Due date math

    static func nextDueDate(
        frequency: RecurrentFrequency,
        startDate: Date,
        endDate: Date?,
        subscriptionDay: Int?,
        referenceDate: Date = Date()
    ) -> Date? {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: referenceDate)
        let anchor = calendar.startOfDay(for: startDate)

        let due: Date?
        switch frequency {
        case .DAILY:
            due = max(anchor, today)
        case .WEEKLY:
            due = nextOccurrence(ofWeekday: calendar.component(.weekday, from: anchor), onOrAfter: today, calendar: calendar)
        case .BIWEEKLY:
            due = nextBiweeklyOccurrence(anchor: anchor, onOrAfter: today, calendar: calendar)
        case .MONTHLY:
            let day = subscriptionDay ?? calendar.component(.day, from: anchor)
            due = nextOccurrence(ofDayOfMonth: day, onOrAfter: today, calendar: calendar)
        }

        guard let due else { return nil }
        if let endDate, due > calendar.startOfDay(for: endDate) { return nil }
        return due
    }

    private static func nextOccurrence(ofWeekday weekday: Int, onOrAfter date: Date, calendar: Calendar) -> Date? {
        var current = date
        for _ in 0..<7 {
            if calendar.component(.weekday, from: current) == weekday { return current }
            guard let next = calendar.date(byAdding: .day, value: 1, to: current) else { return nil }
            current = next
        }
        return nil
    }

    private static func nextBiweeklyOccurrence(anchor: Date, onOrAfter date: Date, calendar: Calendar) -> Date? {
        guard anchor < date else { return anchor }
        var current = anchor
        var safety = 0
        while current < date, safety < 2000 {
            guard let next = calendar.date(byAdding: .day, value: 14, to: current) else { return nil }
            current = next
            safety += 1
        }
        return current
    }

    private static func nextOccurrence(ofDayOfMonth day: Int, onOrAfter date: Date, calendar: Calendar) -> Date? {
        func candidate(for anchor: Date) -> Date? {
            var components = calendar.dateComponents([.year, .month], from: anchor)
            let daysInMonth = calendar.range(of: .day, in: .month, for: anchor)?.count ?? day
            components.day = min(day, daysInMonth)
            return calendar.date(from: components)
        }

        if let thisMonth = candidate(for: date), thisMonth >= date {
            return thisMonth
        }
        guard let nextMonthAnchor = calendar.date(byAdding: .month, value: 1, to: date) else { return nil }
        return candidate(for: nextMonthAnchor)
    }

    // MARK: - Formatting

    private static func identifier(transactionId: UUID, daysBefore: Int) -> String {
        "recurring-\(transactionId.uuidString)-\(daysBefore)"
    }

    private static func formattedAmount(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return "$\(formatter.string(from: amount as NSDecimalNumber) ?? "0.00")"
    }
}
