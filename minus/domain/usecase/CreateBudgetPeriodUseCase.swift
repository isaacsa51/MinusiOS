//
//  CreateBudgetPeriodUseCase.swift
//  minus
//

import Foundation

struct PendingCarryOver {
    let amount: Decimal
    let strategy: RemainingBudgetStrategy
}

class CreateBudgetPeriodUseCase {
    private let repository: PeriodRepository
    private let transactionRepository: TransactionRepository

    init(repository: PeriodRepository, transactionRepository: TransactionRepository) {
        self.repository = repository
        self.transactionRepository = transactionRepository
    }

    func previewCarryOver() async throws -> PendingCarryOver? {
        guard let previous = try await repository.getAllPeriods().first else { return nil }
        let remaining = try await remainingBudget(for: previous)
        guard remaining > 0 else { return nil }
        return PendingCarryOver(amount: remaining, strategy: previous.remainingStrategy)
    }

    func execute(settings: BudgetSettings, carryOverDecision: Bool = true) async throws -> PeriodKey {
        let previous = try await repository.getAllPeriods().first

        if let previous, previous.endDate == nil || previous.endDate! > Date() {
            try await repository.closePeriod(id: previous.id, finalEndDate: Date())
        }
        if let previous {
            PeriodEndNotificationService.cancel(periodId: previous.id)
        }

        var carryOver: Decimal = 0
        if let previous {
            let remaining = try await remainingBudget(for: previous)
            if remaining > 0 {
                switch previous.remainingStrategy {
                case .SPLIT_EQUALLY, .ADD_TO_FIRST_DAY:
                    carryOver = remaining
                case .ASK_ALWAYS:
                    carryOver = carryOverDecision ? remaining : 0
                }
            }
        }

        let firstDayBonus = (previous?.remainingStrategy == .ADD_TO_FIRST_DAY) ? carryOver : 0

        let newPeriod = PeriodKey(
            id: UUID(),
            startDate: settings.startDate,
            endDate: settings.getPeriodEndDate(),
            mappingNode: .activeBucket,
            totalBudget: settings.totalBudget + carryOver,
            currency: settings.currency,
            remainingStrategy: settings.remainingBudgetStrategy,
            periodType: settings.period,
            daysInPeriod: settings.getDaysForPeriod(),
            carryOverAmount: firstDayBonus
        )

        try await repository.save(period: newPeriod)

        if let endDate = newPeriod.endDate {
            PeriodEndNotificationService.schedule(periodId: newPeriod.id, endDate: endDate)
        }

        return newPeriod
    }

    private func remainingBudget(for period: PeriodKey) async throws -> Decimal {
        let transactions = try await transactionRepository.getTransactions(forPeriod: period.id)
        let spent = transactions.reduce(Decimal.zero) { total, tx in
            tx.isCredit ? total - tx.amount : total + tx.amount
        }
        return period.totalBudget - spent
    }
}
