//
//  EditorViewModel.swift
//  minus
//
//  Created by Isaac Emmanuel Serrano Altamirano on 08/05/26.
//

import SwiftUI

@Observable
class EditorViewModel {
    /// Raw numeric string without formatting (e.g. "4250.50")
    private(set) var rawAmount: String = "0"

    /// Formatted display string with grouping separators (e.g. "4,250.50")
    var amount: String {
        CurrencyInputFormatter.format(rawAmount)
    }
    
    func processNumber(button: NumpadButtonArgs) {
        if button.type == .number, let numberValue = button.label {
            // Limit decimal places to 2
            if let dotIndex = rawAmount.firstIndex(of: ".") {
                let decimals = rawAmount[rawAmount.index(after: dotIndex)...]
                if decimals.count >= 2 { return }
            }
            if rawAmount == "0" {
                rawAmount = numberValue
            } else {
                rawAmount += numberValue
            }
        }
        
        if button.type == .action, button.icon == "delete.left" {
            if rawAmount.count > 1 {
                rawAmount.removeLast()
            } else {
                rawAmount = "0"
            }
        }
                
        if button.type == .action, button.label == "." {
            if !rawAmount.contains(".") {
                rawAmount += "."
            }
        }
    }
    
    func saveTransaction() {
        print("TODO: implement current typed number as Transaction: \(rawAmount)")
    }
}
