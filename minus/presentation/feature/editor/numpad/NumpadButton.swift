//
//  NumpadButton.swift
//  minus
//
//  Created by Isaac Emmanuel Serrano Altamirano on 08/05/26.
//

import SwiftUI

enum NumpadButtonType {
    case number
    case op
    case action
}

struct NumpadButtonArgs: Identifiable {
    let id = UUID()
    let label: String?
    let icon: String?
    var isTall: Bool = false
    let type: NumpadButtonType
}

struct NumpadButton: View {
    let label: String?
    let icon: String?
    let type: NumpadButtonType
    var isTall: Bool = false
    let action: () -> Void

    var body: some View {
        if isTall {
            buttonContent
        } else {
            buttonContent.aspectRatio(1, contentMode: .fit)
        }
    }

    private var buttonContent: some View {
        Button(action: action) {
            Group {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 28, weight: .semibold))
                } else if let label = label {
                    Text(label)
                        .font(.system(size: 34, weight: .regular))
                }
            }
            .foregroundStyle(buttonForegroundColor)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(buttonBackgroundColor)
            .clipShape(Capsule())
        }
        .background(Color.minus.background)
    }

    private var buttonBackgroundColor: Color {
        switch type {
        case .number:
            return Color.minus.surface
        case .action:
            return Color.minus.surfaceSecondary
        case .op:
            return Color.minus.primaryAction
        }
    }

    private var buttonForegroundColor: Color {
        switch type {
        case .action:
            return Color.minus.textPrimary
        case .number, .op:
            return Color.minus.textPrimary
        }
    }
}
