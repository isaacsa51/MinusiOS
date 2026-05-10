//
//  AppThemeMode.swift
//  minus
//
//  Created by Isaac Emmanuel Serrano Altamirano on 10/05/26.
//

import SwiftUI

enum AppThemeMode: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system:
            return "Seguir sistema"
        case .light:
            return "Claro"
        case .dark:
            return "Oscuro"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system:
            return nil
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
}
