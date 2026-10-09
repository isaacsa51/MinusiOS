//
//  CalculateReservedChargesUseCase.swift
//  minus
//

import Foundation

/// One recurring payment's share of the reserve: every occurrence it still has
/// coming up in the current period, collapsed into a single line.
struct ReservedCharge: Identifiable {
    /// The template transaction this was projected from.
    let id: UUID
    let name: String
    /// The template's amount multiplied by how many times it falls due in the window.
    let amount: Decimal
    let occurrences: [Date]
}

struct ReservedChargesBreakdown {
    /// Chronological by first occurrence.
    let charges: [ReservedCharge]
    let total: Decimal

    static let empty = ReservedChargesBreakdown(charges: [], total: 0)
}

/// Sums every recurring charge due later in the active period, so the budget can
/// set them aside from day one instead of deducting each one on its due date.
///
/// Occurrences are projected rather than stored, so there's no way to tell a
/// charge that's already been recorded from one that hasn't. The window
/// therefore opens *tomorrow*: anything due today is still spendable out of
/// today's budget, and reserving it would deduct it a second time the moment
/// the user records it.
class CalculateReservedChargesUseCase {
    private let transactionRepository: TransactionRepository

    init(transactionRepository: TransactionRepository) {
        self.transactionRepository = transactionRepository
    }

    func execute(
        period: PeriodKey,
        referenceDate: Date = Date(),
        calendar: Calendar = .current
    ) async throws -> ReservedChargesBreakdown {
        let startOfToday = calendar.startOfDay(for: referenceDate)
        guard let windowStart = calendar.date(byAdding: .day, value: 1, to: startOfToday) else { return .empty }
        let windowEnd = calendar.startOfDay(for: period.effectiveEndDate)
        guard windowStart <= windowEnd else { return .empty }

        // Templates created in an earlier period keep charging into this one, so
        // this can't be scoped to the active period's transactions.
        let templates = try await transactionRepository.getAllTransactions()
            .filter { !$0.isDeleted && !$0.isIncome && $0.recurrentFrequency != nil }

        var charges: [ReservedCharge] = []
        for template in templates {
            guard let frequency = template.recurrentFrequency else { continue }

            let occurrences = RecurrenceSchedule.occurrences(
                frequency: frequency,
                anchor: template.createdAt,
                recurrentEndDate: template.recurrentEndDate,
                subscriptionDay: template.subscriptionDay,
                from: windowStart,
                through: windowEnd,
                calendar: calendar
            )
            guard !occurrences.isEmpty else { continue }

            charges.append(
                ReservedCharge(
                    id: template.id,
                    name: Self.displayName(for: template),
                    amount: template.amount * Decimal(occurrences.count),
                    occurrences: occurrences
                )
            )
        }

        charges.sort { lhs, rhs in
            guard let lhsFirst = lhs.occurrences.first, let rhsFirst = rhs.occurrences.first else {
                return false
            }
            return lhsFirst == rhsFirst ? lhs.name < rhs.name : lhsFirst < rhsFirst
        }

        return ReservedChargesBreakdown(
            charges: charges,
            total: charges.reduce(Decimal.zero) { $0 + $1.amount }
        )
    }

    private static func displayName(for transaction: Transaction) -> String {
        let name = transaction.categoryName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return name.isEmpty ? String(localized: "Uncategorized") : name
    }
}
