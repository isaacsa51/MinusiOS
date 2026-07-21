//
//  EditorViewModel.swift
//  minus
//
//  Created by Isaac Emmanuel Serrano Altamirano on 08/05/26.
//

import SwiftUI
import SwiftData

@Observable
class EditorViewModel {
    private(set) var rawAmount: String = "0"
    
    var categoryText: String = ""
    
    private(set) var savedCategories: [Category] = []
    
    private(set) var transactions: [Transaction] = []

    var hasValue: Bool {
        rawAmount != "0"
    }

    var amount: String {
        CurrencyInputFormatter.format(rawAmount)
    }
    
    private var addExpenseUseCase: AddNewExpenseUseCase?
    private var transactionRepository: TransactionRepository?
    
    func configure(context: ModelContext) {
        let txRepo = TransactionRepositoryImpl(context: context)
        let periodRepo = PeriodReportRepositoryImpl(context: context)
        self.transactionRepository = txRepo
        self.addExpenseUseCase = AddNewExpenseUseCase(repository: txRepo, periodRepo: periodRepo)
    }
    
    func processNumber(button: NumpadButtonArgs) {
        if button.type == .number, let numberValue = button.label {
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
        let categoryName = trimmed.isEmpty ? nil : trimmed
        let categoryId = UUID()
        
        if let name = categoryName,
           !savedCategories.contains(where: { $0.name == name }) {
            savedCategories.append(Category(
                id: categoryId,
                name: name,
                lastUsedAt: Date(),
                createdAt: Date()
            ))
        }
        
        Task {
            do {
                try await addExpenseUseCase?.execute(
                    amount: amountValue,
                    categoryId: categoryId,
                    categoryName: categoryName
                )
                await loadTransactions()
            } catch {
                print("Failed to save transaction: \(error)")
            }
        }
        
        rawAmount = "0"
        categoryText = ""
    }
    
    func loadTransactions() async {
        do {
            let fetched = try await transactionRepository?.getAllTransactions() ?? []
            await MainActor.run {
                self.transactions = fetched
                var seen = Set<String>()
                for tx in fetched {
                    if let name = tx.categoryName, !name.isEmpty, seen.insert(name).inserted {
                        if !savedCategories.contains(where: { $0.name == name }) {
                            savedCategories.append(Category(
                                id: tx.categoryId,
                                name: name,
                                lastUsedAt: tx.createdAt,
                                createdAt: tx.createdAt
                            ))
                        }
                    }
                }
            }
        } catch {
            print("Failed to load transactions: \(error)")
        }
    }
    
    func clearAll() {
        rawAmount = "0"
        categoryText = ""
    }
    
    func selectCategory(_ category: Category) {
        categoryText = category.name ?? ""
    }
}
