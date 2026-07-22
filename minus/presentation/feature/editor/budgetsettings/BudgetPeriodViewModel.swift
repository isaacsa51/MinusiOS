//
//  BudgetPeriodViewModel.swift
//  minus
//

import SwiftUI

@MainActor
@Observable
class BudgetPeriodViewModel {
    var activePeriod: PeriodKey?
    var isLoading = true
    var showNewBudgetSheet = false
    var errorMessage: String?
    var formBudgetAmount = ""
    var formStartDate = Date()
    var formEndDate = Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date()
    var formCurrency: Currency = Currency.all.first { $0.code == "MXN" } ?? Currency.all[0]
    var formRemainingStrategy: RemainingBudgetStrategy = .SPLIT_EQUALLY

    var selectedSplitMode: BudgetPeriod = .daily
    private(set) var spentInSplit: Decimal = 0

    private let getCurrentPeriodUseCase: GetCurrentPeriodIdIUseCase
    private let createBudgetPeriodUseCase: CreateBudgetPeriodUseCase
    private let transactionRepository: TransactionRepository

    init(periodRepo: PeriodRepository, transactionRepo: TransactionRepository) {
        self.getCurrentPeriodUseCase = GetCurrentPeriodIdIUseCase(repository: periodRepo)
        self.createBudgetPeriodUseCase = CreateBudgetPeriodUseCase(repository: periodRepo)
        self.transactionRepository = transactionRepo
        if let saved = UserDefaults.standard.string(forKey: "selectedSplitMode"),
           let mode = BudgetPeriod(rawValue: saved) {
            self.selectedSplitMode = mode
        }
    }


    var pillTitle: String {
        guard activePeriod != nil else { return "Sin presupuesto" }
        if isExceeded { return "Presupuesto excedido" }
        switch selectedSplitMode {
        case .daily: return "Para hoy"
        case .weekly: return "Esta semana"
        case .biweekly: return "Esta quincena"
        case .monthly: return "Este mes"
        }
    }

    var splitBudget: Decimal {
        guard let period = activePeriod else { return 0 }
        let totalDays = max(1, period.daysInPeriod)
        let daily = period.totalBudget / Decimal(totalDays)

        let multiplier: Int
        switch selectedSplitMode {
        case .daily: multiplier = 1
        case .weekly: multiplier = 7
        case .biweekly: multiplier = 14
        case .monthly: multiplier = totalDays
        }

        let result = daily * Decimal(min(multiplier, totalDays))
        var rounded = Decimal()
        var mutable = result
        NSDecimalRound(&rounded, &mutable, 2, .plain)
        return rounded
    }

    var pillAmount: String {
        guard activePeriod != nil else { return "$0" }
        let symbol = Currency.find(byCode: activePeriod!.currency)?.symbol ?? "$"
        let remaining = splitBudget - spentInSplit
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return "\(symbol)\(formatter.string(from: remaining as NSDecimalNumber) ?? "0.00")"
    }

    var spendingProgress: Double {
        guard splitBudget > 0 else { return 0 }
        return NSDecimalNumber(decimal: spentInSplit / splitBudget).doubleValue
    }

    var isExceeded: Bool {
        spendingProgress >= 1.0
    }

    var pillColor: Color {
        guard activePeriod != nil else { return Color.minus.textSecondary }
        let progress = min(spendingProgress, 1.0)
        if progress < 0.5 {
            let t = progress / 0.5
            return Color(
                red: t * 0.95,
                green: 0.75 + (1.0 - t) * 0.11,
                blue: 0.39 * (1.0 - t)
            )
        } else {
            let t = (progress - 0.5) / 0.5
            return Color(
                red: 0.95 + t * 0.05,
                green: 0.75 * (1.0 - t * 0.7),
                blue: 0.0
            )
        }
    }

    func checkActivePeriod() async {
        isLoading = true
        do {
            activePeriod = try await getCurrentPeriodUseCase.execute()
            if activePeriod == nil {
                showNewBudgetSheet = true
            } else {
                await loadSpending()
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func loadSpending() async {
        guard let period = activePeriod else { return }
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        let endOfToday = calendar.date(byAdding: .day, value: 1, to: startOfToday) ?? Date()

        let windowStart: Date
        switch selectedSplitMode {
        case .daily:
            windowStart = startOfToday
        case .weekly:
            windowStart = calendar.date(byAdding: .day, value: -6, to: startOfToday) ?? startOfToday
        case .biweekly:
            windowStart = calendar.date(byAdding: .day, value: -13, to: startOfToday) ?? startOfToday
        case .monthly:
            windowStart = period.startDate
        }

        let effectiveStart = max(windowStart, period.startDate)

        do {
            let transactions = try await transactionRepository.getTransactions(
                between: effectiveStart, and: endOfToday
            )
            let periodTransactions = transactions.filter { $0.periodId == period.id && !$0.isDeleted }
            spentInSplit = periodTransactions.reduce(Decimal.zero) { $0 + $1.amount }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func updateSplitMode(_ mode: BudgetPeriod) {
        selectedSplitMode = mode
        UserDefaults.standard.set(mode.rawValue, forKey: "selectedSplitMode")
        Task { await loadSpending() }
    }

    func applyNewBudget() async {
        let rawAmount = CurrencyInputFormatter.stripFormatting(formBudgetAmount)
        guard let amount = Decimal(string: rawAmount), amount > 0 else {
            errorMessage = "Ingresa un monto válido"
            return
        }

        let days = Calendar.current.dateComponents([.day], from: formStartDate, to: formEndDate).day ?? 30

        let settings = BudgetSettings(
            totalBudget: amount,
            period: .monthly,
            startDate: formStartDate,
            endDate: formEndDate,
            currency: formCurrency.code,
            daysInPeriod: max(1, days),
            remainingBudgetStrategy: formRemainingStrategy
        )

        do {
            activePeriod = try await createBudgetPeriodUseCase.execute(settings: settings)
            showNewBudgetSheet = false
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func resetForm() {
        formBudgetAmount = ""
        formStartDate = Date()
        formEndDate = Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date()
        formCurrency = Currency.all.first { $0.code == "MXN" } ?? Currency.all[0]
        formRemainingStrategy = .SPLIT_EQUALLY
    }
}
