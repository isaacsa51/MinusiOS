//
//  Color+Categorical.swift
//  minus
//
//  Fixed-order categorical palette for charts (spending by category, etc).
//  Validated for CVD-safe adjacent contrast in both light and dark mode
//

import SwiftUI

extension Color {
    init(light: String, dark: String) {
        self.init(uiColor: UIColor(light: light, dark: dark))
    }

    /// 8 fixed hues, validated adjacent-pair CVD-safe in both appearances.
    /// Past 8 series, fold the tail into "Other" rather than adding a 9th slot.
    static let categorical: [Color] = [
        Color(light: "#2A78D6", dark: "#3987E5"), // blue
        Color(light: "#EB6834", dark: "#D95926"), // orange
        Color(light: "#1BAF7A", dark: "#199E70"), // aqua
        Color(light: "#EDA100", dark: "#C98500"), // yellow
        Color(light: "#E87BA4", dark: "#D55181"), // magenta
        Color(light: "#008300", dark: "#008300"), // green
        Color(light: "#4A3AA7", dark: "#9085E9"), // violet
        Color(light: "#E34948", dark: "#E66767"), // red
    ]

    static func categorical(at index: Int) -> Color {
        categorical[index % categorical.count]
    }
}

private extension UIColor {
    convenience init(light: String, dark: String) {
        self.init { traits in
            traits.userInterfaceStyle == .dark ? UIColor(hex: dark) : UIColor(hex: light)
        }
    }

    convenience init(hex: String) {
        var sanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        sanitized = sanitized.replacingOccurrences(of: "#", with: "")
        var value: UInt64 = 0
        Scanner(string: sanitized).scanHexInt64(&value)
        let r = CGFloat((value & 0xFF0000) >> 16) / 255
        let g = CGFloat((value & 0x00FF00) >> 8) / 255
        let b = CGFloat(value & 0x0000FF) / 255
        self.init(red: r, green: g, blue: b, alpha: 1.0)
    }
}
