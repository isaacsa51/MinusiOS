//
//  WidgetPalette.swift
//  MinusWidget
//

import SwiftUI

struct WidgetPalette {
    let background: Color
    let textPrimary: Color
    let textSecondary: Color

    static let accent = Color(red: 0.19, green: 0.72, blue: 0.39)

    static let light = WidgetPalette(
        background: Color(red: 0.9647, green: 0.9451, blue: 0.8941),
        textPrimary: Color(red: 0.1059, green: 0.1059, blue: 0.0902),
        textSecondary: Color(red: 0.4784, green: 0.4667, blue: 0.4275)
    )

    static let dark = WidgetPalette(
        background: Color(red: 0.1059, green: 0.1059, blue: 0.0902),
        textPrimary: Color(red: 0.9647, green: 0.9451, blue: 0.8941),
        textSecondary: Color(red: 0.6039, green: 0.5882, blue: 0.5412)
    )
}

extension WidgetPalette {
    private static let categoricalLight: [Color] = [
        Color(red: 0.1647, green: 0.4706, blue: 0.8392), // blue
        Color(red: 0.9216, green: 0.4078, blue: 0.2039), // orange
        Color(red: 0.1059, green: 0.6863, blue: 0.4784), // aqua
        Color(red: 0.9294, green: 0.6314, blue: 0.0),    // yellow
        Color(red: 0.9098, green: 0.4824, blue: 0.6431), // magenta
        Color(red: 0.0,    green: 0.5137, blue: 0.0),    // green
        Color(red: 0.2902, green: 0.2275, blue: 0.6549), // violet
        Color(red: 0.8902, green: 0.2863, blue: 0.2824)  // red
    ]

    private static let categoricalDark: [Color] = [
        Color(red: 0.2235, green: 0.5294, blue: 0.898),  // blue
        Color(red: 0.851,  green: 0.349,  blue: 0.149),  // orange
        Color(red: 0.098,  green: 0.6196, blue: 0.4392), // aqua
        Color(red: 0.7882, green: 0.5216, blue: 0.0),    // yellow
        Color(red: 0.8353, green: 0.3176, blue: 0.5059), // magenta
        Color(red: 0.0,    green: 0.5137, blue: 0.0),    // green
        Color(red: 0.5647, green: 0.5216, blue: 0.9137), // violet
        Color(red: 0.902,  green: 0.4039, blue: 0.4039)  // red
    ]

    static func categoricalColor(for name: String, dark: Bool) -> Color {
        let palette = dark ? categoricalDark : categoricalLight
        let index = abs(name.hashValue) % palette.count
        return palette[index]
    }
}

extension Color {
    static func spendingHeat(_ progress: Double) -> Color {
        let clamped = min(max(progress, 0), 1.0)
        if clamped < 0.5 {
            let t = clamped / 0.5
            return Color(red: t * 0.95, green: 0.75 + (1.0 - t) * 0.11, blue: 0.39 * (1.0 - t))
        } else {
            let t = (clamped - 0.5) / 0.5
            return Color(red: 0.95 + t * 0.05, green: 0.75 * (1.0 - t * 0.7), blue: 0.0)
        }
    }
}
