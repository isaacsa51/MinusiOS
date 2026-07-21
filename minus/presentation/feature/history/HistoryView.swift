//
//  HistoryView.swift
//  minus
//
//  Placeholder for the transactions history screen.
//  Rendered inside TopSheetContainer from EditorView.
//

import SwiftUI

struct HistoryView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                ForEach(0..<8) { i in
                    HStack {
                        Text("Sample transaction #\(i + 1)")
                            .foregroundStyle(Color.minus.textSecondary)
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.minus.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    TopSheetContainer(isPresented: .constant(true)) {
        HistoryView()
    }
}
