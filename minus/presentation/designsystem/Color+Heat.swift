//
//  Color+Heat.swift
//  minus
//

import SwiftUI

extension Color {
    static func spendingHeat(_ progress: Double) -> Color {
        let clamped = min(max(progress, 0), 1.0)
        if clamped < 0.5 {
            let t = clamped / 0.5
            return Color(
                red: t * 0.95,
                green: 0.75 + (1.0 - t) * 0.11,
                blue: 0.39 * (1.0 - t)
            )
        } else {
            let t = (clamped - 0.5) / 0.5
            return Color(
                red: 0.95 + t * 0.05,
                green: 0.75 * (1.0 - t * 0.7),
                blue: 0.0
            )
        }
    }
}
