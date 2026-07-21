//
//  NumpadView.swift
//  minus
//
//  Created by Isaac Emmanuel Serrano Altamirano on 08/05/26.
//

import SwiftUI

struct NumpadView: View {
    let onButtonTapped: (NumpadButtonArgs) -> Void

    let columnsMatrix: [[NumpadButtonArgs]] = [
        [
            NumpadButtonArgs(label: nil, icon: "divide", type: .op),
            NumpadButtonArgs(label: "7", icon: nil, type: .number),
            NumpadButtonArgs(label: "4", icon: nil, type: .number),
            NumpadButtonArgs(label: "1", icon: nil, type: .number),
            NumpadButtonArgs(label: "0", icon: nil, type: .number)
        ],
        [
            NumpadButtonArgs(label: nil, icon: "multiply", type: .op),
            NumpadButtonArgs(label: "8", icon: nil, type: .number),
            NumpadButtonArgs(label: "5", icon: nil, type: .number),
            NumpadButtonArgs(label: "2", icon: nil, type: .number),
            NumpadButtonArgs(label: ".", icon: nil, type: .action)
        ],
        [
            NumpadButtonArgs(label: nil, icon: "plus", type: .op),
            NumpadButtonArgs(label: "9", icon: nil, type: .number),
            NumpadButtonArgs(label: "6", icon: nil, type: .number),
            NumpadButtonArgs(label: "3", icon: nil, type: .number),
            NumpadButtonArgs(label: nil, icon: "equal", type: .op)
        ],
        [
            NumpadButtonArgs(label: nil, icon: "minus", type: .op),
            NumpadButtonArgs(label: nil, icon: "delete.left", type: .action),
            NumpadButtonArgs(label: nil, icon: "checkmark", isTall: true, type: .op)
        ]
    ]

    var body: some View {
        HStack(spacing: 12) {
            ForEach(columnsMatrix.indices, id: \.self) { colIndex in
                VStack(spacing: 12) {
                    ForEach(columnsMatrix[colIndex]) { button in
                        NumpadButton(label: button.label, icon: button.icon, type: button.type, isTall: button.isTall) {
                            onButtonTapped(button)
                        }
                    }
                }
                .frame(maxHeight: .infinity)
            }
        }
        .background(Color.minus.background)
        .fixedSize(horizontal: false, vertical: true)
        .padding(.horizontal, 16)
    }
}
