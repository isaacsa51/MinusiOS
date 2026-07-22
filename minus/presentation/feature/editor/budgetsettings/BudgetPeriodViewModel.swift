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
    private let getCurrentPeriodUseCase: GetCurrentPeriodIdIUseCase
    private let createBudgetPeriodUseCase: CreateBudgetPeriodUseCase

    init(periodRepo: PeriodRepository) {
        self.getCurrentPeriodUseCase = GetCurrentPeriodIdIUseCase(repository: periodRepo)
        self.createBudgetPeriodUseCase = CreateBudgetPeriodUseCase(repository: periodRepo)
    }


    var pillTitle: String {
        activePeriod != nil ? "Para hoy" : "Sin presupuesto"
    }

    var pillAmount: String {
        guard let period = activePeriod else { return "$0" }
        let settings = BudgetSettings(
            totalBudget: period.totalBudget,
            period: period.periodType,
            startDate: period.startDate,
            endDate: period.endDate,
            currency: period.currency,
            daysInPeriod: period.daysInPeriod,
            remainingBudgetStrategy: period.remainingStrategy
        )
        let daily = settings.calculateDailyBudget()
        let symbol = Currency.find(byCode: period.currency)?.symbol ?? "$"

        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return "\(symbol)\(formatter.string(from: daily as NSDecimalNumber) ?? "0.00")"
    }

    var pillColor: Color {
        activePeriod != nil ? Color.minus.primaryAction : Color.minus.textSecondary
    }

    func checkActivePeriod() async {
        isLoading = true
        do {
            activePeriod = try await getCurrentPeriodUseCase.execute()
            if activePeriod == nil {
                showNewBudgetSheet = true
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
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
