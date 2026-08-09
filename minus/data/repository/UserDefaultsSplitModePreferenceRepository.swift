//
//  UserDefaultsSplitModePreferenceRepository.swift
//  minus
//

import Foundation

class UserDefaultsSplitModePreferenceRepository: SplitModePreferenceRepository {
    private static let key = "selectedSplitMode"
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func getSelectedSplitMode() -> BudgetPeriod? {
        guard let raw = defaults.string(forKey: Self.key) else { return nil }
        return BudgetPeriod(rawValue: raw)
    }

    func setSelectedSplitMode(_ mode: BudgetPeriod) {
        defaults.set(mode.rawValue, forKey: Self.key)
        NotificationCenter.default.post(name: .splitModeDidChange, object: nil)
    }
}
