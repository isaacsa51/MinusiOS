//
//  ReservedChargesPreferenceRepository.swift
//  minus
//

import Foundation

protocol ReservedChargesPreferenceRepository {
    func isReserveUpcomingChargesEnabled() -> Bool
    func setReserveUpcomingChargesEnabled(_ enabled: Bool)
}

extension Notification.Name {
    static let reserveUpcomingChargesDidChange = Notification.Name("reserveUpcomingChargesDidChange")
}
