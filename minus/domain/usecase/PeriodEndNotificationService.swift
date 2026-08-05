import Foundation
import UserNotifications

class PeriodEndNotificationService {
    private static let reminderHour = 9

    static func schedule(periodId: UUID, endDate: Date) {
        cancel(periodId: periodId)

        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: endDate)
        components.hour = reminderHour

        let content = UNMutableNotificationContent()
        content.title = String(localized: "Budget period ended")
        content.body = String(localized: "Your current budget period has ended. Review your spending and start a new one.")
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: identifier(periodId: periodId),
            content: content,
            trigger: UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        )

        Task {
            try? await UNUserNotificationCenter.current().add(request)
        }
    }

    static func cancel(periodId: UUID) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier(periodId: periodId)])
    }

    private static func identifier(periodId: UUID) -> String {
        "period-end-\(periodId.uuidString)"
    }
}
