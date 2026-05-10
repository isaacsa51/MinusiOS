//
//  ThemeManager.swift
//  minus
//
//  Created by Isaac Emmanuel Serrano Altamirano on 10/05/26.
//

import SwiftUI

@Observable
final class ThemeManager {
    private let storageKey = "app_theme_mode"

    var selectedMode: AppThemeMode {
        didSet {
            UserDefaults.standard.set(selectedMode.rawValue, forKey: storageKey)
        }
    }

    init() {
        let savedModeRawValue = UserDefaults.standard.string(forKey: storageKey)
        selectedMode = AppThemeMode(rawValue: savedModeRawValue ?? "") ?? .system
    }

    var colorScheme: ColorScheme? {
        selectedMode.colorScheme
    }
}
