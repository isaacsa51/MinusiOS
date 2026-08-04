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

    var showCarryOverPrompt = false
    private(set) var pendingCarryOverAmount: Decimal = 0
    private var pendingSettings: BudgetSettings?

    private(set) var carryOverPreview: PendingCarryOver?

    var selectedSplitMode: BudgetPeriod = .daily
    private(set) var spentInSplit: Decimal = 0
    private(set) var spentInPeriod: Decimal = 0

    private let getCurrentPeriodUseCase: GetCurrentPeriodIdIUseCase
    private let createBudgetPeriodUseCase: CreateBudgetPeriodUseCase
    private let finishPeriodEarlyUseCase: FinishPeriodEarlyUseCase
    private let transactionRepository: TransactionRepository

    init(periodRepo: PeriodRepository, transactionRepo: TransactionRepository) {
        self.getCurrentPeriodUseCase = GetCurrentPeriodIdIUseCase(repository: periodRepo)
        self.createBudgetPeriodUseCase = CreateBudgetPeriodUseCase(repository: periodRepo, transactionRepository: transactionRepo)
        self.finishPeriodEarlyUseCase = FinishPeriodEarlyUseCase(repository: periodRepo)
        self.transactionRepository = transactionRepo
        if let saved = UserDefaults.standard.string(forKey: "selectedSplitMode"),
           let mode = BudgetPeriod(rawValue: saved) {
            self.selectedSplitMode = mode
        }
    }


    var pillTitle: String {
        guard activePeriod != nil else { return String(localized: "No budget") }
        if isExceeded { return String(localized: "Budget exceeded") }
        switch selectedSplitMode {
        case .daily: return String(localized: "For today")
        case .weekly: return String(localized: "This week")
        case .biweekly: return String(localized: "This biweekly period")
        case .monthly: return String(localized: "This month")
        }
    }

    var splitBudget: Decimal {
        guard let period = activePeriod else { return 0 }
        var rounded = Decimal()
        var mutable = period.splitAmount(for: selectedSplitMode)
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
        return Color.spendingHeat(spendingProgress)
    }

    var periodSpendingProgress: Double {
        guard let period = activePeriod, period.totalBudget > 0 else { return 0 }
        return NSDecimalNumber(decimal: spentInPeriod / period.totalBudget).doubleValue
    }

    var periodAvailablePercentage: Int {
        let available = 1 - min(max(periodSpendingProgress, 0), 1)
        return Int((available * 100).rounded())
    }

    var periodSpentAmount: String {
        guard let period = activePeriod else { return "$0.00" }
        let symbol = Currency.find(byCode: period.currency)?.symbol ?? "$"
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return "\(symbol)\(formatter.string(from: spentInPeriod as NSDecimalNumber) ?? "0.00")"
    }

    var periodPillColor: Color {
        guard activePeriod != nil else { return Color.minus.textSecondary }
        return Color.spendingHeat(periodSpendingProgress)
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
            await refreshCarryOverPreview()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func refreshCarryOverPreview() async {
        carryOverPreview = try? await createBudgetPeriodUseCase.previewCarryOver()
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
            spentInSplit = periodTransactions.reduce(Decimal.zero) { total, tx in
                tx.isCredit ? total - tx.amount : total + tx.amount
            }

            let allPeriodTransactions = try await transactionRepository.getTransactions(forPeriod: period.id)
            spentInPeriod = allPeriodTransactions.reduce(Decimal.zero) { total, tx in
                tx.isCredit ? total - tx.amount : total + tx.amount
            }
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
            errorMessage = String(localized: "Enter a valid amount")
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
            if let pending = try await createBudgetPeriodUseCase.previewCarryOver(), pending.strategy == .ASK_ALWAYS {
                pendingSettings = settings
                pendingCarryOverAmount = pending.amount
                showCarryOverPrompt = true
                return
            }
            activePeriod = try await createBudgetPeriodUseCase.execute(settings: settings)
            showNewBudgetSheet = false
            await refreshCarryOverPreview()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func confirmCarryOver(include: Bool) async {
        guard let settings = pendingSettings else { return }
        showCarryOverPrompt = false
        pendingSettings = nil

        do {
            activePeriod = try await createBudgetPeriodUseCase.execute(settings: settings, carryOverDecision: include)
            showNewBudgetSheet = false
            await refreshCarryOverPreview()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func finishPeriodEarly() async {
        do {
            try await finishPeriodEarlyUseCase.execute()
            activePeriod = nil
            resetForm()
            showNewBudgetSheet = true
            await refreshCarryOverPreview()
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

    func populateFormFromActivePeriod() {
        guard let period = activePeriod else { return }
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        formBudgetAmount = formatter.string(from: period.totalBudget as NSDecimalNumber) ?? ""
        formStartDate = period.startDate
        formEndDate = period.effectiveEndDate
        formCurrency = Currency.find(byCode: period.currency) ?? Currency.all[0]
        formRemainingStrategy = period.remainingStrategy
    }
}
