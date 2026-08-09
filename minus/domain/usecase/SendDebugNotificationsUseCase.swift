//
//  SendDebugNotificationsUseCase.swift
//  minus
//

/// Fires sample notifications for manually verifying delivery (foreground presentation, sound,
/// wording) without waiting on real due/period-end dates — a developer-only debug affordance,
/// triggered by the numpad's hidden 5-dot-tap gesture.
class SendDebugNotificationsUseCase {
    func execute() {
        RecurringNotificationService.sendTestNotification()
        PeriodEndNotificationService.sendTestNotification()
    }
}
