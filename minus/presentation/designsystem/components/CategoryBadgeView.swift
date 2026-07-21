//
//  CategoryBadgeView.swift
//  minus
//

import SwiftUI

struct CategoryBadgeView: View {
    let name: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(name)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(isSelected ? Color.minus.background : Color.minus.textPrimary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
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
