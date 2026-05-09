//
//  EditorViewModel.swift
//  minus
//
//  Created by Isaac Emmanuel Serrano Altamirano on 08/05/26.
//

import SwiftUI

@Observable
class EditorViewModel {
    var amount: String = "0"
    
    func processNumber(button: NumpadButtonArgs) {
        if button.type == .number, let numberValue = button.label {
            if amount == "0" {
                amount = numberValue
            } else {
                amount += numberValue
            }
        }
        
        if button.type == .action, button.icon == "delete.left" {
            if amount.count > 1 {
                amount.removeLast()
            } else {
                amount = "0"
                }
            }
                
            if button.type == .action, button.label == "." {
                if !amount.contains(".") {
                    amount += "."
                }
            }
    }
    
    func saveTransaction() {
        print("TODO: implement current typed number as Transaction: \(amount)")
    }
}
