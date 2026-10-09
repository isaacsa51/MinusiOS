//
//  UserDefaultsReservedChargesPreferenceRepository.swift
//  minus
//

import Foundation

class UserDefaultsReservedChargesPreferenceRepository: ReservedChargesPreferenceRepository {
    private static let key = "reserveUpcomingCharges"
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func isReserveUpcomingChargesEnabled() -> Bool {
        defaults.bool(forKey: Self.key)
    }

    func setReserveUpcomingChargesEnabled(_ enabled: Bool) {
        defaults.set(enabled, forKey: Self.key)
        NotificationCenter.default.post(name: .reserveUpcomingChargesDidChange, object: nil)
    }
}
