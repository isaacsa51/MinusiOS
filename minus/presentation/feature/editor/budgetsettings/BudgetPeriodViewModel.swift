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

    // Spending tracking
    private(set) var spentToday: Decimal = 0

    private let getCurrentPeriodUseCase: GetCurrentPeriodIdIUseCase
    private let createBudgetPeriodUseCase: CreateBudgetPeriodUseCase
    private let transactionRepository: TransactionRepository

    init(periodRepo: PeriodRepository, transactionRepo: TransactionRepository) {
        self.getCurrentPeriodUseCase = GetCurrentPeriodIdIUseCase(repository: periodRepo)
        self.createBudgetPeriodUseCase = CreateBudgetPeriodUseCase(repository: periodRepo)
        self.transactionRepository = transactionRepo
    }


    var pillTitle: String {
        guard activePeriod != nil else { return "Sin presupuesto" }
        return isExceeded ? "Presupuesto excedido" : "Para hoy"
    }

    var dailyBudget: Decimal {
        guard let period = activePeriod else { return 0 }
        let settings = BudgetSettings(
            totalBudget: period.totalBudget,
            period: period.periodType,
            startDate: period.startDate,
            endDate: period.endDate,
            currency: period.currency,
            daysInPeriod: period.daysInPeriod,
            remainingBudgetStrategy: period.remainingStrategy
        )
        return settings.calculateDailyBudget()
    }

    var pillAmount: String {
        guard activePeriod != nil else { return "$0" }
        let symbol = Currency.find(byCode: activePeriod!.currency)?.symbol ?? "$"
        let remaining = dailyBudget - spentToday
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return "\(symbol)\(formatter.string(from: remaining as NSDecimalNumber) ?? "0.00")"
    }

    /// 0.0 = nothing spent, 1.0 = fully spent, >1.0 = exceeded
    var spendingProgress: Double {
        guard dailyBudget > 0 else { return 0 }
        return NSDecimalNumber(decimal: spentToday / dailyBudget).doubleValue
    }

    var isExceeded: Bool {
        spendingProgress >= 1.0
    }

    /// Interpolates green → yellow → red based on spending progress
    var pillColor: Color {
        guard activePeriod != nil else { return Color.minus.textSecondary }
        let progress = min(spendingProgress, 1.0)
        if progress < 0.5 {
            // Green → Yellow
            let t = progress / 0.5
            return Color(
                red: t * 0.95,
                green: 0.75 + (1.0 - t) * 0.11,
                blue: 0.39 * (1.0 - t)
            )
        } else {
            // Yellow → Red
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

        do {
            let todayTransactions = try await transactionRepository.getTransactions(
                between: startOfToday, and: endOfToday
            )
            // Only count transactions for the active period
            let periodTransactions = todayTransactions.filter { $0.periodId == period.id && !$0.isDeleted }
            spentToday = periodTransactions.reduce(Decimal.zero) { $0 + $1.amount }
        } catch {
            errorMessage = error.localizedDescription
        }
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
