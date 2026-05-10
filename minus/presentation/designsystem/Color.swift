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
    let background = Color.black
    let surface = Color(uiColor: .darkGray).opacity(0.8)
    let surfaceSecondary = Color(.secondarySystemGroupedBackground)
    
    // accents
    let primaryAction = Color(red: 0.85, green: 0.45, blue: 0.25)
    let success = Color(red: 0.3, green: 0.4, blue: 0.2)
    let destructive = Color.red
    
    // texts
    let textPrimary = Color.white
    let textSecondary = Color.gray}
