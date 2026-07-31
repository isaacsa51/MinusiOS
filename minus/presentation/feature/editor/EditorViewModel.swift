//
//  EditorViewModel.swift
//  minus
//
//  Created by Isaac Emmanuel Serrano Altamirano on 08/05/26.
//

import SwiftUI

enum TransactionMode {
    case expense
    case income
    case decrease
}

@MainActor
@Observable
class EditorViewModel {
    private(set) var rawAmount: String = "0"
    private(set) var transactionMode: TransactionMode = .expense
    
    var categoryText: String = ""
    
    private(set) var savedCategories: [Category] = []
    
    var errorMessage: String?
    
    var onTransactionSaved: (() async -> Void)?

    // Edit mode state
    private(set) var editingTransactionId: UUID?
    var editingDate: Date?
    
    var isEditing: Bool { editingTransactionId != nil }

    // Recurrence state
    var isRecurring: Bool = false
    var selectedFrequency: RecurrentFrequency = .MONTHLY
    var subscriptionDay: Int = Calendar.current.component(.day, from: Date())
    var recurrentEndDate: Date = Calendar.current.date(byAdding: .year, value: 1, to: Date()) ?? Date()
    var showRecurrenceOptions: Bool = false
    


    var isIncomeOrDecreaseMode: Bool {
        transactionMode == .income || transactionMode == .decrease
    }

    var hasValue: Bool {
        rawAmount != "0" || isIncomeOrDecreaseMode
    }
    
    var hasExpression: Bool {
        rawAmount.contains(where: { Self.operatorSet.contains($0) })
    }

    var amount: String {
        let formatted = formatExpression(rawAmount)
        switch transactionMode {
        case .expense:
            return formatted
        case .income:
            return "+$\(formatted)"
        case .decrease:
            return "\u{2212}$\(formatted)"
        }
    }
    
    var expressionResult: String? {
        guard hasExpression else { return nil }
        guard let last = rawAmount.last, !Self.operatorSet.contains(last), last != "." else { return nil }
        guard let value = evaluate(rawAmount), value.isFinite else { return nil }
        let raw = formatResult(value)
        return "= \(CurrencyInputFormatter.formatWithSymbol(raw))"
    }
    
    private let addExpenseUseCase: AddNewExpenseUseCase
    private let editTransactionUseCase: EditTransactionUseCase
    private let transactionRepository: TransactionRepository
    
    private static let operatorSet: Set<Character> = ["+", "-", "*", "/"]
    
    init(transactionRepo: TransactionRepository, periodRepo: PeriodRepository) {
        self.transactionRepository = transactionRepo
        self.addExpenseUseCase = AddNewExpenseUseCase(repository: transactionRepo, periodRepo: periodRepo)
        self.editTransactionUseCase = EditTransactionUseCase(repository: transactionRepo)
    }
    
    func startEditing(id: UUID, amount: Double, categoryName: String?, date: Date, isCredit: Bool = false) {
        editingTransactionId = id
        editingDate = date
        transactionMode = isCredit ? .income : .expense
        
        // Format the amount: remove trailing zeros
        let formatted = String(format: "%.2f", amount)
        var result = formatted
        if result.contains(".") {
            while result.hasSuffix("0") { result.removeLast() }
            if result.hasSuffix(".") { result.removeLast() }
        }
        rawAmount = result
        categoryText = categoryName ?? ""
    }
    
    func processNumber(button: NumpadButtonArgs) {
        if button.type == .number, let numberValue = button.label {
            let segment = currentNumberSegment()
            if let dotIndex = segment.firstIndex(of: ".") {
                let decimals = segment[segment.index(after: dotIndex)...]
                if decimals.count >= 2 { return }
            }
            if rawAmount == "0" {
                rawAmount = numberValue
            } else if segment == "0" {
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
            } else if rawAmount == "0" && isIncomeOrDecreaseMode {
                transactionMode = .expense
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
        if button.icon == "equal" {
            if hasExpression, let result = evaluate(rawAmount), result.isFinite, result >= 0 {
                rawAmount = formatResult(result)
            }
            return
        }
        
        if rawAmount == "0" {
            if button.icon == "plus" {
                transactionMode = .income
            } else if button.icon == "minus" {
                transactionMode = .decrease
            }
            return
        }
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
            rawAmount = String(rawAmount.dropLast()) + op
        } else if lastChar == "." {
            rawAmount = String(rawAmount.dropLast()) + op
        } else {
            rawAmount += op
        }
    }
    
    private func currentNumberSegment() -> String {
        if let lastOpIndex = rawAmount.lastIndex(where: { Self.operatorSet.contains($0) }) {
            return String(rawAmount[rawAmount.index(after: lastOpIndex)...])
        }
        return rawAmount
    }
    
    private func evaluate(_ expr: String) -> Double? {
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
    
    private func formatResult(_ value: Double) -> String {
        let raw = String(format: "%.2f", value)
        var result = raw
        if result.contains(".") {
            while result.hasSuffix("0") { result.removeLast() }
            if result.hasSuffix(".") { result.removeLast() }
        }
        return result
    }
    
    func saveTransaction() {
        let amountValue: Decimal
        if hasExpression {
            guard let result = evaluate(rawAmount), result.isFinite, result > 0 else { return }
            amountValue = Decimal(string: formatResult(result)) ?? Decimal(result)
        } else {
            guard let value = Decimal(string: rawAmount), value > 0 else { return }
            amountValue = value
        }
        
        let trimmed = categoryText.trimmingCharacters(in: .whitespacesAndNewlines)
        let categoryName: String?
        if trimmed.isEmpty {
            switch transactionMode {
            case .income: categoryName = "Unnamed income"
            case .decrease: categoryName = "Unnamed decrease"
            case .expense: categoryName = nil
            }
        } else {
            categoryName = trimmed
        }
        let isCredit = transactionMode == .income
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
        
        if let editId = editingTransactionId {
            Task {
                do {
                    try await editTransactionUseCase.execute(
                        transactionId: editId,
                        newAmount: amountValue,
                        newCategoryName: categoryName,
                        newDate: editingDate,
                        newIsCredit: isCredit
                    )
                    await loadSavedCategories()
                    await onTransactionSaved?()
                } catch {
                    errorMessage = error.localizedDescription
                }
            }
        } else {
            let frequency: RecurrentFrequency? = isRecurring ? selectedFrequency : nil
            let endDate: Date? = isRecurring ? recurrentEndDate : nil
            let dayOfMonth: Int? = (isRecurring && selectedFrequency == .MONTHLY) ? subscriptionDay : nil

            Task {
                do {
                    try await addExpenseUseCase.execute(
                        amount: amountValue,
                        categoryId: categoryId,
                        categoryName: categoryName,
                        isCredit: isCredit,
                        recurrentFrequency: frequency,
                        recurrentEndDate: endDate,
                        subscriptionDay: dayOfMonth
                    )
                    await loadSavedCategories()
                    await onTransactionSaved?()
                } catch {
                    errorMessage = error.localizedDescription
                }
            }
        }
        
        rawAmount = "0"
        categoryText = ""
        editingTransactionId = nil
        editingDate = nil
        transactionMode = .expense
        resetRecurrence()
    }
    
    func loadSavedCategories() async {
        do {
            let fetched = try await transactionRepository.getAllTransactions()
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
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func clearAll() {
        rawAmount = "0"
        categoryText = ""
        editingTransactionId = nil
        editingDate = nil
        transactionMode = .expense
        resetRecurrence()
    }

    func resetRecurrence() {
        isRecurring = false
        selectedFrequency = .MONTHLY
        subscriptionDay = Calendar.current.component(.day, from: Date())
        recurrentEndDate = Calendar.current.date(byAdding: .year, value: 1, to: Date()) ?? Date()
        showRecurrenceOptions = false
    }
    
    func selectCategory(_ category: Category) {
        categoryText = category.name ?? ""
    }
}
