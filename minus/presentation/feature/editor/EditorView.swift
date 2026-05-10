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
    @State private var showBudgetSheet = false
    
    var body: some View {
        VStack(spacing: 0) {
            
            // rendering the header
            HStack(spacing: 16) {
                BudgetPillView()
                    .frame(maxWidth: .infinity)
                    .onTapGesture {
                        showBudgetSheet = true
                    }
                
                Button(action: { /* Lógica de analíticas */ }) {
                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Button(action: { router.navigate(to: .settings) }) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            
            Spacer()
            
            HStack {
                Spacer()
                Text(viewModel.amount)
                    .font(.system(size: 80, weight: .light))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
            
            Capsule()
                .fill(Color.gray.opacity(0.5))
                .frame(width: 40, height: 4)
                .padding(.bottom, 16)
            
            NumpadView(onButtonTapped: { button in
                if button.icon == "checkmark" {
                    viewModel.saveTransaction()
                } else {
                    viewModel.processNumber(button: button)
                }
            })
            .padding(.bottom, 32)
            
        }
        .sheet(isPresented: $showBudgetSheet) {
            BudgetDetailsSheet()
                .presentationDetents([.fraction(0.65), .large])
                .presentationDragIndicator(.visible)
        }
        .background(Color.black.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .gesture(
            DragGesture()
                .onEnded { value in
                    if value.translation.height > 50 && abs(value.translation.width) < 50 {
                        router.navigate(to: .history)
                    }
                }
        )
    }
}

#Preview {
    NavigationStack {
        EditorView()
            .environment(NavigationRouter())
    }
}

