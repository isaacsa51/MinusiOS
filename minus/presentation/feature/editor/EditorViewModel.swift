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
    
    /// Category text typed by the user
    var categoryText: String = ""
    
    /// Previously saved categories shown as badges
    private(set) var savedCategories: [Category] = []

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
        guard let amountValue = Double(rawAmount), amountValue > 0 else { return }
        
        let trimmed = categoryText.trimmingCharacters(in: .whitespacesAndNewlines)
        let category = Category(
            id: UUID(),
            name: trimmed.isEmpty ? nil : trimmed,
            lastUsedAt: Date(),
            createdAt: Date()
        )
        
        // Add to saved categories if it has a name and isn't already saved
        if let name = category.name,
           !savedCategories.contains(where: { $0.name == name }) {
            savedCategories.append(category)
        }
        
        print("Transaction: \(rawAmount), category: \(category.name ?? "none"), categoryId: \(category.id)")
        
        // Reset inputs
        rawAmount = "0"
        categoryText = ""
    }
    
    func selectCategory(_ category: Category) {
        categoryText = category.name ?? ""
    }
}
