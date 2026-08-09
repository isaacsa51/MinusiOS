//
//  SplitModePreferenceRepository.swift
//  minus
//

import Foundation

protocol SplitModePreferenceRepository {
    func getSelectedSplitMode() -> BudgetPeriod?
    func setSelectedSplitMode(_ mode: BudgetPeriod)
}

extension Notification.Name {
    static let splitModeDidChange = Notification.Name("splitModeDidChange")
}
