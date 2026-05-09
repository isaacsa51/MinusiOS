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
                .foregroundColor(.white)
                .padding(.trailing, 20)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 180)
        .background(Color.black)
        
        Divider().background(Color.gray.opacity(0.3))
        
        Spacer()
        
        NumpadView( onButtonTapped: { button in
            if button.icon ==  "save" {
                viewModel.saveTransaction()
            } else {
                viewModel.processNumber(button: button)
            }
        })
        .padding(.bottom, 20)
        
        Spacer()
        
            .background(Color.black.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        router.navigate(to: .history)
                    }) {
                        Image(systemName: "list.bullet")
                            .foregroundColor(.white)
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

