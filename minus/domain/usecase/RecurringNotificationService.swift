import Foundation

class RecurringNotificationService {
    /// Schedules recurring notifications for a transaction.
    /// Currently a stub -- implement with UNUserNotificationCenter.
    static func schedule(
        transactionId: UUID,
        amount: Decimal,
        categoryName: String?,
        frequency: RecurrentFrequency,
        startDate: Date,
        endDate: Date?,
        subscriptionDay: Int?
    ) {
        // TODO: Request notification permission via UNUserNotificationCenter
        // TODO: Create UNMutableNotificationContent with transaction details
        // TODO: Create UNCalendarNotificationTrigger based on frequency:
        //   - WEEKLY: DateComponents with weekday matching startDate's weekday
        //   - BIWEEKLY: Schedule two-week repeating trigger
        //   - MONTHLY: DateComponents with day = subscriptionDay
        // TODO: Create UNNotificationRequest and add to UNUserNotificationCenter
    }

    /// Cancels all notifications for a specific transaction.
    static func cancel(transactionId: UUID) {
        // TODO: Remove pending notifications with identifier matching transactionId
    }
}
