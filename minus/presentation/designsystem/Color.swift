//
//  Color.swift
//  minus
//
//  Created by Isaac Emmanuel Serrano Altamirano on 10/05/26.
//

import SwiftUI

extension Color {
    static let minus = MinusTheme()
}

struct MinusTheme {
    // main colors
    let background = Color(uiColor: .systemBackground)
    let surface = Color(uiColor: .secondarySystemBackground)
    let surfaceSecondary = Color(uiColor: .tertiarySystemBackground)

    // accents
    let primaryAction = Color(red: 0.19, green: 0.72, blue: 0.39)
    let success = Color(red: 0.29, green: 0.86, blue: 0.48)
    let destructive = Color.red

    // texts
    let textPrimary = Color.primary
    let textSecondary = Color.secondary

    // utilities
    let divider = Color.primary.opacity(0.15)
}
