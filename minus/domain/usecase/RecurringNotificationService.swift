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

    static func sendTestNotification() {
        let content = UNMutableNotificationContent()
        content.sound = .default
        content.body = String(localized: "Your recurring payment Test Subscription of: \(formattedAmount(99)) is due in 3 days")

        let request = UNNotificationRequest(
            identifier: "test-recurring-\(UUID().uuidString)",
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 3, repeats: false)
        )
        Task {
            try? await UNUserNotificationCenter.current().add(request)
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
        RecurrenceSchedule.nextOccurrence(
            frequency: frequency,
            anchor: startDate,
            recurrentEndDate: endDate,
            subscriptionDay: subscriptionDay,
            onOrAfter: referenceDate
        )
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
