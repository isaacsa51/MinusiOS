//
//  UserDefaultsCreditCardPreferenceRepository.swift
//  minus
//

import Foundation

class UserDefaultsCreditCardPreferenceRepository: CreditCardPreferenceRepository {
    private static let enabledKey = "useCreditCardPayments"
    private static let cutoffDayKey = "creditCardCutoffDay"
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func isCreditCardPaymentsEnabled() -> Bool {
        defaults.bool(forKey: Self.enabledKey)
    }

    func setCreditCardPaymentsEnabled(_ enabled: Bool) {
        defaults.set(enabled, forKey: Self.enabledKey)
    }

    func getCutoffDay() -> Int? {
        let day = defaults.integer(forKey: Self.cutoffDayKey)
        return day > 0 ? day : nil
    }

    func setCutoffDay(_ day: Int) {
        defaults.set(day, forKey: Self.cutoffDayKey)
    }
}
