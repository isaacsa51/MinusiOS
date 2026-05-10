//
//  EditorView.swift
//  minus
//
//  Created by Isaac Emmanuel Serrano Altamirano on 08/05/26.
//

import Foundation
import SwiftUI

struct EditorView: View {
    @Environment(NavigationRouter.self) var router // here we get the instace of Router
    @State private var viewModel = EditorViewModel()

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            Text(viewModel.amount)
                .font(.system(size: 64, weight: .bold))
                .foregroundStyle(Color.minus.textPrimary)
                .padding(.trailing, 20)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 180)
        .background(Color.minus.background)

        Divider().background(Color.minus.divider)

        Spacer()

        NumpadView(onButtonTapped: { button in
            if button.icon == "save" {
                viewModel.saveTransaction()
            } else {
                viewModel.processNumber(button: button)
            }
        })
        .padding(.bottom, 20)

        Spacer()

            .background(Color.minus.background.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        router.navigate(to: .settings)
                    }) {
                        Image(systemName: "gearshape")
                            .foregroundStyle(Color.minus.textPrimary)
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        router.navigate(to: .history)
                    }) {
                        Image(systemName: "list.bullet")
                            .foregroundStyle(Color.minus.textPrimary)
                    }
                }
            }
    }
}

#Preview {
    NavigationStack {
        EditorView()
            .environment(NavigationRouter())
    }
}
