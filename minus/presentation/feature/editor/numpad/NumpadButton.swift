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
                .foregroundColor(buttonForegroundColor)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(buttonBackgroundColor)
                .clipShape(Capsule())
            }
        .background(Color.black)
    }
    
    private var buttonBackgroundColor: Color{
        switch type {
        case .number: return Color(.darkGray).opacity(0.8)
        case .action: return Color(.lightGray).opacity(0.8)
        case .op: return .orange
        }
    }
    
    private var buttonForegroundColor: Color {
        switch type {
        case .action: return .black
        case .number, .op: return .white
        }
    }
    
    
}
