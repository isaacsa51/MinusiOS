//
//  CategoryBadgeView.swift
//  minus
//

import SwiftUI

struct CategoryBadgeView: View {
    let name: String
    let isSelected: Bool
    let onTap: () -> Void

    // Referenced by CategoryInputRow's text input so the two stay the same
    // height as a single source of truth, rather than two hardcoded values
    // that could drift apart.
    static let height: CGFloat = 34

    var body: some View {
        Button(action: onTap) {
            Text(name)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(isSelected ? Color.minus.background : Color.minus.textPrimary)
                .padding(.horizontal, 12)
                .frame(height: Self.height)
                .background(isSelected ? Color.minus.primaryAction : Color.minus.surface)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(Color.minus.divider, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}
