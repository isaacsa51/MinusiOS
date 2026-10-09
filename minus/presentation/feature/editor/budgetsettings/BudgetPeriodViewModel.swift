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
    private var spentBeforeToday: Decimal = 0

    /// Recurring charges due later in this period, set aside from the spendable
    /// pool. Always `.empty` while the preference is off.
    private(set) var reservedCharges: ReservedChargesBreakdown = .empty

    private let getCurrentPeriodUseCase: GetCurrentPeriodIdIUseCase
    private let createBudgetPeriodUseCase: CreateBudgetPeriodUseCase
    private let finishPeriodEarlyUseCase: FinishPeriodEarlyUseCase
    private let calculateReservedChargesUseCase: CalculateReservedChargesUseCase
    private let transactionRepository: TransactionRepository
    private let splitModePreferenceRepository: SplitModePreferenceRepository
    private let reservedChargesPreferenceRepository: ReservedChargesPreferenceRepository
    // deinit runs nonisolated even on a @MainActor class, so these tokens — plain opaque
    // handles that are safe to read/remove from any thread — can't be MainActor-isolated.
    // The compiler suggests plain `nonisolated` here, but @Observable rewrites these into
    // accessors and rejects it: "cannot be applied to mutable stored properties".
    nonisolated(unsafe) private var splitModeObserverToken: NSObjectProtocol?
    nonisolated(unsafe) private var reservedChargesObserverToken: NSObjectProtocol?

    init(
        periodRepo: PeriodRepository,
        transactionRepo: TransactionRepository,
        splitModePreferenceRepo: SplitModePreferenceRepository,
        reservedChargesPreferenceRepo: ReservedChargesPreferenceRepository
    ) {
        self.getCurrentPeriodUseCase = GetCurrentPeriodIdIUseCase(repository: periodRepo)
        self.createBudgetPeriodUseCase = CreateBudgetPeriodUseCase(repository: periodRepo, transactionRepository: transactionRepo)
        self.finishPeriodEarlyUseCase = FinishPeriodEarlyUseCase(repository: periodRepo)
        self.calculateReservedChargesUseCase = CalculateReservedChargesUseCase(transactionRepository: transactionRepo)
        self.transactionRepository = transactionRepo
        self.splitModePreferenceRepository = splitModePreferenceRepo
        self.reservedChargesPreferenceRepository = reservedChargesPreferenceRepo
        if let saved = splitModePreferenceRepo.getSelectedSplitMode() {
            self.selectedSplitMode = saved
        }
        observeSplitModeChanges()
        observeReservedChargesChanges()
    }

    deinit {
        for token in [splitModeObserverToken, reservedChargesObserverToken] {
            guard let token else { continue }
            NotificationCenter.default.removeObserver(token)
        }
    }

    // Picks up selectedSplitMode changes written from elsewhere (e.g. a CSV import) while this
    // view model is already alive, since it's a plain var read once at init.
    private func observeSplitModeChanges() {
        splitModeObserverToken = NotificationCenter.default.addObserver(
            forName: .splitModeDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self,
                      let mode = self.splitModePreferenceRepository.getSelectedSplitMode(),
                      mode != self.selectedSplitMode
                else { return }
                self.selectedSplitMode = mode
                await self.loadSpending()
            }
        }
    }

    // The toggle lives in Settings, which writes through its own repository
    // instance — without this the pill would keep showing the old daily amount
    // until the editor's `.task` happened to run again.
    private func observeReservedChargesChanges() {
        reservedChargesObserverToken = NotificationCenter.default.addObserver(
            forName: .reserveUpcomingChargesDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.loadSpending()
            }
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
        splitAmount(for: selectedSplitMode)
    }

    func splitAmount(for mode: BudgetPeriod) -> Decimal {
        guard let period = activePeriod else { return 0 }
        var rounded = Decimal()
        var mutable = period.splitAmount(for: mode, dailyRate: dynamicDailyRate)
        NSDecimalRound(&rounded, &mutable, 2, .plain)
        return rounded
    }

    private var daysElapsedInPeriod: Int {
        guard let period = activePeriod else { return 0 }
        let calendar = Calendar.current
        return max(0, calendar.dateComponents(
            [.day],
            from: calendar.startOfDay(for: period.startDate),
            to: calendar.startOfDay(for: Date())
        ).day ?? 0)
    }

    private var remainingDaysInPeriod: Int {
        guard let period = activePeriod else { return 1 }
        return max(1, period.daysInPeriod - daysElapsedInPeriod)
    }

    /// What's actually divisible: the budget, less the lump held back for day
    /// one, less what's already gone, less anything set aside for charges still
    /// to come. Legitimately goes negative when those outrun the budget.
    private var freeToSpendPool: Decimal {
        guard let period = activePeriod else { return 0 }
        return (period.totalBudget - period.carryOverAmount)
            - spentBeforeToday
            - reservedCharges.total
    }

    private var dynamicDailyRate: Decimal {
        guard activePeriod != nil else { return 0 }
        return freeToSpendPool / Decimal(remainingDaysInPeriod)
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
        guard splitBudget > 0 else { return 1.0 }
        return NSDecimalNumber(decimal: spentInSplit / splitBudget).doubleValue
    }

    var isExceeded: Bool {
        splitBudget <= 0 || spendingProgress >= 1.0
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

    var periodTotalBudgetAmount: String {
        guard let period = activePeriod else { return "$0" }
        let symbol = Currency.find(byCode: period.currency)?.symbol ?? "$"
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 0
        return "\(symbol)\(formatter.string(from: period.totalBudget as NSDecimalNumber) ?? "0")"
    }

    var periodPillColor: Color {
        guard activePeriod != nil else { return Color.minus.textSecondary }
        return Color.spendingHeat(periodSpendingProgress)
    }

    /// One display row per recurring charge held back this period. Empty while
    /// the preference is off, which is also what hides the section in the UI.
    var reservedChargeRows: [ReservedChargeRow] {
        reservedCharges.charges.map {
            ReservedChargeRow(id: $0.id, name: $0.name, amount: formattedCurrency($0.amount))
        }
    }

    var reservedChargesTotalAmount: String {
        formattedCurrency(reservedCharges.total)
    }

    var budgetFormula: BudgetFormulaBreakdown? {
        guard let period = activePeriod else { return nil }

        let rate = dynamicDailyRate
        let windowDays = period.windowDays(for: selectedSplitMode)
        let dayOneBonus = period.isFirstWindow(for: selectedSplitMode) ? period.carryOverAmount : 0
        let remaining = splitBudget - spentInSplit

        var poolLines = [
            BudgetFormulaLine(
                label: String(localized: "Total budget"),
                amount: formattedCurrency(period.totalBudget)
            )
        ]
        if period.carryOverAmount > 0 {
            poolLines.append(BudgetFormulaLine(
                label: String(localized: "Held back for day one"),
                amount: formattedCurrency(period.carryOverAmount),
                sign: .minus
            ))
        }
        if spentBeforeToday != 0 {
            poolLines.append(BudgetFormulaLine(
                label: String(localized: "Spent before today"),
                amount: formattedCurrency(abs(spentBeforeToday)),
                // Net income before today adds to the pool instead of draining it.
                sign: spentBeforeToday > 0 ? .minus : .plus
            ))
        }
        if reservedCharges.total > 0 {
            poolLines.append(BudgetFormulaLine(
                label: String(localized: "Set aside for upcoming charges"),
                amount: reservedChargesTotalAmount,
                sign: .minus
            ))
        }
        poolLines.append(BudgetFormulaLine(
            label: String(localized: "Free to spend"),
            amount: formattedCurrency(freeToSpendPool),
            sign: .equals
        ))

        var leftLines = [
            BudgetFormulaLine(
                label: splitWindowLabel(windowDays: windowDays),
                amount: formattedCurrency(splitBudget - dayOneBonus)
            )
        ]
        if dayOneBonus > 0 {
            leftLines.append(BudgetFormulaLine(
                label: String(localized: "Carried over to day one"),
                amount: formattedCurrency(dayOneBonus),
                sign: .plus
            ))
        }
        if spentInSplit != 0 {
            leftLines.append(BudgetFormulaLine(
                label: String(localized: "What you spent"),
                amount: formattedCurrency(abs(spentInSplit)),
                sign: spentInSplit > 0 ? .minus : .plus
            ))
        }
        leftLines.append(BudgetFormulaLine(
            label: String(localized: "Total"),
            amount: formattedCurrency(remaining),
            sign: .equals
        ))

        let days = remainingDaysInPeriod
        return BudgetFormulaBreakdown(
            subtitle: "\(period.remainingStrategy.displayName) · \(selectedSplitMode.displayTitle)",
            poolLines: poolLines,
            numerator: formattedCurrency(freeToSpendPool),
            denominator: days == 1 ? String(localized: "1 day") : String(localized: "\(days) days"),
            dailyRate: formattedCurrency(rounded(rate)),
            reservedCharges: reservedChargeRows,
            reservedTotal: reservedChargesTotalAmount,
            leftLines: leftLines,
            total: formattedCurrency(remaining),
            shortfallNote: remaining < 0 ? shortfallNote : nil
        )
    }

    private func splitWindowLabel(windowDays: Int) -> String {
        switch selectedSplitMode {
        case .daily: return String(localized: "Budget for today")
        case .weekly: return String(localized: "Budget for this week (\(windowDays) days)")
        case .biweekly: return String(localized: "Budget for these two weeks (\(windowDays) days)")
        case .monthly: return String(localized: "Budget for this period (\(windowDays) days)")
        }
    }

    private var shortfallNote: String {
        if reservedCharges.total > 0, freeToSpendPool < 0 {
            return String(localized: "Charges still due outrun what's left in this period.")
        }
        return String(localized: "You've spent more than this allowance.")
    }

    private func rounded(_ value: Decimal) -> Decimal {
        var result = Decimal()
        var mutable = value
        NSDecimalRound(&result, &mutable, 2, .plain)
        return result
    }

    private func formattedCurrency(_ amount: Decimal) -> String {
        let symbol = activePeriod.flatMap { Currency.find(byCode: $0.currency)?.symbol } ?? "$"
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return "\(symbol)\(formatter.string(from: amount as NSDecimalNumber) ?? "0.00")"
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
                tx.isIncome ? total - tx.amount : total + tx.amount
            }

            let allPeriodTransactions = try await transactionRepository.getTransactions(forPeriod: period.id)
            spentInPeriod = allPeriodTransactions.reduce(Decimal.zero) { total, tx in
                tx.isIncome ? total - tx.amount : total + tx.amount
            }
            spentBeforeToday = allPeriodTransactions
                .filter { $0.createdAt < startOfToday }
                .reduce(Decimal.zero) { total, tx in
                    tx.isIncome ? total - tx.amount : total + tx.amount
                }

            if reservedChargesPreferenceRepository.isReserveUpcomingChargesEnabled() {
                reservedCharges = try await calculateReservedChargesUseCase.execute(period: period)
            } else {
                reservedCharges = .empty
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func updateSplitMode(_ mode: BudgetPeriod) {
        selectedSplitMode = mode
        splitModePreferenceRepository.setSelectedSplitMode(mode)
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

/// `ReservedCharge` flattened for display: ForEach needs an Identifiable
/// element, and key paths can't address tuple members.
struct ReservedChargeRow: Identifiable {
    let id: UUID
    let name: String
    let amount: String
}
