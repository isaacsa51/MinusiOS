//
//  AppTheme.swift
//  minus
//
//  This app's SwiftThemeKit configuration. Colors/buttons/text fields are
//  left at ThemeKit's defaults — this app already has its own color system
//  (Color.minus, Color.categorical, Color.spendingHeat) and hand-built
//  components (BudgetPillView, the analytics cards, etc.), so adopting
//  ThemeKit's color/component layer on top would just duplicate that.
//
//  What ThemeKit actually fills a real gap on is typography/spacing/radii —
//  today those are hardcoded ad hoc per view (a scan of the presentation
//  layer turned up ~35 distinct font-size/weight pairs and 7 different
//  corner radii for what are conceptually the same handful of styles). The
//  scale below maps to the sizes already in real, common use rather than
//  ThemeKit's own suggested numbers, so adopting it doesn't shift anything
//  visually on its own — it only starts paying off as call sites migrate
//  from raw `.font(.system(size:))`/`.padding(N)`/`cornerRadius(N)` to the
//  token-based modifiers ThemeKit provides (`.font(.titleMedium)`,
//  `.padding(.md)`, `.cornerRadius(.xl)`, etc).

import SwiftUI
import SwiftThemeKit

enum AppTheme {
    /// Hero/headline numbers — the big rounded dollar amounts (period totals,
    /// spending-card amounts, stat-tile amounts).
    private static let typography = ThemeTypography(
        displayLarge: .system(size: 34, weight: .bold, design: .rounded),
        displayMedium: .system(size: 28, weight: .bold, design: .rounded),
        displaySmall: .system(size: 22, weight: .bold, design: .rounded),
        headlineLarge: .system(size: 24, weight: .semibold),
        headlineMedium: .system(size: 20, weight: .semibold),
        headlineSmall: .system(size: 18, weight: .semibold),
        titleLarge: .system(size: 18, weight: .medium),
        titleMedium: .system(size: 16, weight: .medium),
        titleSmall: .system(size: 14, weight: .medium),
        labelLarge: .system(size: 14, weight: .semibold),
        labelMedium: .system(size: 13, weight: .medium),
        labelSmall: .system(size: 12, weight: .medium),
        bodyLarge: .system(size: 16, weight: .regular),
        bodyMedium: .system(size: 15, weight: .regular),
        bodySmall: .system(size: 13, weight: .regular),
        buttonText: .system(size: 16, weight: .bold)
    )

    /// `.md`/`.xl` are the two real workhorses here — `.md` (12pt) is the
    /// common inter-row/stack spacing, `.xl` (20pt) is the near-universal
    /// card outer padding.
    private static let spacing = ThemeSpacing(
        xs: 4,
        sm: 8,
        md: 12,
        lg: 16,
        xl: 20,
        xxl: 32
    )

    /// `.xl` (20pt) is this app's dominant card corner radius by a wide
    /// margin; the others fold in the handful of smaller radii used for
    /// rows, chips, and buttons.
    private static let radii = ThemeRadii(
        xs: 4,
        sm: 8,
        md: 12,
        lg: 16,
        xl: 20,
        pill: 9999
    )

    static let light: Theme = .defaultLight.copy(
        typography: typography,
        spacing: spacing,
        radii: radii
    )

    static let dark: Theme = .defaultDark.copy(
        typography: typography,
        spacing: spacing,
        radii: radii
    )
}
