//
//  BudgetPillView.swift
//  minus
//
//  Created by Isaac Emmanuel Serrano Altamirano on 09/05/26.
//

import SwiftUI

struct BudgetPillView: View {
    var title: String = "Para hoy"
    var amount: String = "1,270.23"

    var pillColor: Color = Color.minus.primaryAction

    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.minus.textPrimary.opacity(0.8))

            Spacer()

            Text(amount)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Color.minus.textPrimary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(pillColor.opacity(0.3))
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(pillColor.opacity(0.5), lineWidth: 1)
        )
    }
}

#Preview {
    BudgetPillView(title: "Para Hoy", amount: "$ 123.12", pillColor: Color.minus.success)
}
