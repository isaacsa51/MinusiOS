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
    
    /// Whether the expression contains any operator
    var hasExpression: Bool {
        rawAmount.contains(where: { Self.operatorSet.contains($0) })
    }

    /// Formatted display string — formats each number segment and joins with operator symbols
    var amount: String {
        formatExpression(rawAmount)
    }
    
    /// Computed result of the expression, shown below the amount when there's an operator
    var expressionResult: String? {
        guard hasExpression else { return nil }
        guard let last = rawAmount.last, !Self.operatorSet.contains(last), last != "." else { return nil }
        guard let value = evaluate(rawAmount), value.isFinite else { return nil }
        let raw = formatResult(value)
        return "= \(CurrencyInputFormatter.formatWithSymbol(raw))"
    }
    
    private var addExpenseUseCase: AddNewExpenseUseCase?
    private var transactionRepository: TransactionRepository?
    
    private static let operatorSet: Set<Character> = ["+", "-", "*", "/"]
    
    func configure(context: ModelContext) {
        let txRepo = TransactionRepositoryImpl(context: context)
        let periodRepo = PeriodReportRepositoryImpl(context: context)
        self.transactionRepository = txRepo
        self.addExpenseUseCase = AddNewExpenseUseCase(repository: txRepo, periodRepo: periodRepo)
    }
    
    // MARK: - Input handling
    
    func processNumber(button: NumpadButtonArgs) {
        if button.type == .number, let numberValue = button.label {
            let segment = currentNumberSegment()
            // Limit decimal places to 2
            if let dotIndex = segment.firstIndex(of: ".") {
                let decimals = segment[segment.index(after: dotIndex)...]
                if decimals.count >= 2 { return }
            }
            if rawAmount == "0" {
                rawAmount = numberValue
            } else if segment == "0" {
                // Replace trailing "0" after an operator with the typed digit
                rawAmount = String(rawAmount.dropLast()) + numberValue
            } else {
                rawAmount += numberValue
            }
        }
        
        if button.type == .op {
            handleOperator(button)
        }
        
        if button.type == .action, button.icon == "delete.left" {
            if rawAmount.count > 1 {
                rawAmount.removeLast()
            } else {
                rawAmount = "0"
            }
        }
                
        if button.type == .action, button.label == "." {
            let segment = currentNumberSegment()
            if !segment.contains(".") {
                if segment.isEmpty {
                    rawAmount += "0."
                } else {
                    rawAmount += "."
                }
            }
        }
    }
    
    private func handleOperator(_ button: NumpadButtonArgs) {
        // Equal button: collapse expression to its result
        if button.icon == "equal" {
            if hasExpression, let result = evaluate(rawAmount), result.isFinite, result >= 0 {
                rawAmount = formatResult(result)
            }
            return
        }
        
        guard rawAmount != "0" else { return }
        guard let lastChar = rawAmount.last else { return }
        
        let op: String
        switch button.icon {
        case "plus": op = "+"
        case "minus": op = "-"
        case "multiply": op = "*"
        case "divide": op = "/"
        default: return
        }
        
        if Self.operatorSet.contains(lastChar) {
            // Replace last operator
            rawAmount = String(rawAmount.dropLast()) + op
        } else if lastChar == "." {
            // Remove trailing dot before adding operator
            rawAmount = String(rawAmount.dropLast()) + op
        } else {
            rawAmount += op
        }
    }
    
    /// Returns the number segment currently being typed (after the last operator)
    private func currentNumberSegment() -> String {
        if let lastOpIndex = rawAmount.lastIndex(where: { Self.operatorSet.contains($0) }) {
            return String(rawAmount[rawAmount.index(after: lastOpIndex)...])
        }
        return rawAmount
    }
    
    // MARK: - Expression evaluation
    
    private func evaluate(_ expr: String) -> Double? {
        // Tokenize into numbers and operators
        var numbers: [Double] = []
        var ops: [Character] = []
        var current = ""
        
        for char in expr {
            if Self.operatorSet.contains(char) {
                guard let num = Double(current) else { return nil }
                numbers.append(num)
                ops.append(char)
                current = ""
            } else {
                current += String(char)
            }
        }
        guard let lastNum = Double(current) else { return nil }
        numbers.append(lastNum)
        
        // First pass: * and / (higher precedence)
        var i = 0
        while i < ops.count {
            if ops[i] == "*" || ops[i] == "/" {
                if ops[i] == "/" && numbers[i + 1] == 0 { return nil }
                let result = ops[i] == "*" ? numbers[i] * numbers[i + 1] : numbers[i] / numbers[i + 1]
                numbers[i] = result
                numbers.remove(at: i + 1)
                ops.remove(at: i)
            } else {
                i += 1
            }
        }
        
        // Second pass: + and -
        var result = numbers[0]
        for i in 0..<ops.count {
            if ops[i] == "+" {
                result += numbers[i + 1]
            } else {
                result -= numbers[i + 1]
            }
        }
        
        return result
    }
    
    // MARK: - Formatting
    
    /// Formats the raw expression for display: each number gets grouping separators, operators become symbols
    private func formatExpression(_ expr: String) -> String {
        var result = ""
        var currentNumber = ""
        
        for char in expr {
            if Self.operatorSet.contains(char) {
                result += CurrencyInputFormatter.format(currentNumber)
                switch char {
                case "+": result += "+"
                case "-": result += "−"
                case "*": result += "×"
                case "/": result += "÷"
                default: break
                }
                currentNumber = ""
            } else {
                currentNumber += String(char)
            }
        }
        result += CurrencyInputFormatter.format(currentNumber)
        return result
    }
    
    /// Formats a computed result value, stripping unnecessary trailing zeros
    private func formatResult(_ value: Double) -> String {
        let raw = String(format: "%.2f", value)
        var result = raw
        if result.contains(".") {
            while result.hasSuffix("0") { result.removeLast() }
            if result.hasSuffix(".") { result.removeLast() }
        }
        return result
    }
    
    // MARK: - Saving
    
    func saveTransaction() {
        let amountValue: Double
        if hasExpression {
            guard let result = evaluate(rawAmount), result.isFinite, result > 0 else { return }
            amountValue = (result * 100).rounded() / 100
        } else {
            guard let value = Double(rawAmount), value > 0 else { return }
            amountValue = value
        }
        
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
