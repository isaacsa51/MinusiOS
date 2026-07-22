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
    var progress: Double = 0.0
    var isExceeded: Bool = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Capsule()
                    .fill(pillColor.opacity(0.15))

                Capsule()
                    .fill(pillColor.opacity(0.35))
                    .frame(width: geo.size.width * min(CGFloat(progress), 1.0))
                    .frame(maxWidth: .infinity, alignment: .leading)

                // Border
                Capsule()
                    .stroke(pillColor.opacity(0.5), lineWidth: 1)

                // Content
                if isExceeded {
                    Text("Presupuesto excedido")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(pillColor)
                } else {
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
                }
            }
        }
        .frame(height: 44)
        .animation(.easeInOut(duration: 0.3), value: progress)
    }
}

#Preview {
    VStack(spacing: 12) {
        BudgetPillView(title: "Para hoy", amount: "$1,270.23", pillColor: Color.minus.success, progress: 0.2)
        BudgetPillView(title: "Para hoy", amount: "$500.00", pillColor: .yellow, progress: 0.5)
        BudgetPillView(title: "Para hoy", amount: "$100.00", pillColor: .orange, progress: 0.8)
        BudgetPillView(title: "Presupuesto excedido", amount: "$0", pillColor: .red, progress: 1.0, isExceeded: true)
    }
    .padding()
}
