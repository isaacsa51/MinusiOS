//
//  ExportBackupUseCase.swift
//  minus
//

import Foundation

class ExportBackupUseCase {
    private let periodRepository: PeriodRepository
    private let transactionRepository: TransactionRepository

    init(periodRepository: PeriodRepository, transactionRepository: TransactionRepository) {
        self.periodRepository = periodRepository
        self.transactionRepository = transactionRepository
    }

    func execute(creditCardCutoffDay: Int? = nil) async throws -> String {
        let activePeriod = try await periodRepository.getActivePeriod()
        let allPeriods = try await periodRepository.getAllPeriods()
        let transactions = try await transactionRepository.getAllTransactions()

        let periodIdentities: [UUID: String] = Dictionary(
            uniqueKeysWithValues: allPeriods.map { ($0.id, $0.externalId ?? $0.id.uuidString) }
        )

        var lines: [String] = [Self.header]
        if let activePeriod {
            lines.append(metaRow(for: activePeriod, creditCardCutoffDay: creditCardCutoffDay))
        }
        lines.append(contentsOf: transactions.map { row(for: $0, periodIdentities: periodIdentities) })

        return lines.joined(separator: "\r\n")
    }

    private static let header = [
        "date", "amount", "comment", "is_recurrent", "frequency", "end_date", "sub_day",
        "id", "is_credit", "is_credit_paid", "period_id", "created_at",
        "budget_total", "budget_period", "budget_start_date", "budget_end_date",
        "currency_code", "days_in_period", "rollover_enabled", "rollover_carry_forward",
        "remaining_budget_strategy", "current_period_started_at_millis", "current_period_id",
        "credit_card_cutoff_day", "split_mode"
    ].joined(separator: ",")

    private func row(for transaction: Transaction, periodIdentities: [UUID: String]) -> String {
        let date: String = Self.dateTimeFormatter.string(from: transaction.createdAt)
        let amount: String = amountString(transaction.amount)
        let comment: String = transaction.categoryName ?? ""
        let isRecurrent: String = transaction.isRecurrent ? "1" : "0"
        let frequency: String = transaction.recurrentFrequency?.rawValue ?? ""
        let endDate: String = transaction.recurrentEndDate.map(Self.dateFormatter.string(from:)) ?? ""
        let subDay: String = transaction.subscriptionDay.map(String.init) ?? ""
        let isCredit: String = transaction.isCreditCardCharge ? "1" : "0"
        let isCreditPaid: String = transaction.isCreditCardPaid ? "1" : "0"
        let periodId: String = periodIdentities[transaction.periodId] ?? transaction.periodId.uuidString
        let createdAt: String = String(millis(transaction.createdAt))

        let fields: [String] = [
            date, amount, comment, isRecurrent, frequency, endDate, subDay,
            transaction.clientGeneratedId, isCredit, isCreditPaid, periodId, createdAt,
            "", "", "", "", "", "", "", "", "", "", "", "", ""
        ]
        return fields.map(csvField).joined(separator: ",")
    }

    private func metaRow(for period: PeriodKey, creditCardCutoffDay: Int?) -> String {
        let hasCarryOver = period.carryOverAmount > 0 ? "1" : "0"

        return [
            "__META__", "", "", "", "", "", "", "", "", "", "", "",
            amountString(period.totalBudget, minimumFractionDigits: 2),
            period.periodType.rawValue.uppercased(),
            Self.dateFormatter.string(from: period.startDate),
            Self.dateFormatter.string(from: period.effectiveEndDate),
            period.currency,
            String(period.daysInPeriod),
            hasCarryOver,
            hasCarryOver,
            period.remainingStrategy.rawValue,
            String(millis(period.startDate)),
            period.externalId ?? period.id.uuidString,
            creditCardCutoffDay.map(String.init) ?? "",
            ""
        ]
        .map(csvField)
        .joined(separator: ",")
    }

    private func millis(_ date: Date) -> Int64 {
        Int64((date.timeIntervalSince1970 * 1000).rounded())
    }

    private func amountString(_ amount: Decimal, minimumFractionDigits: Int = 0) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = false
        formatter.minimumFractionDigits = minimumFractionDigits
        formatter.maximumFractionDigits = 2
        formatter.decimalSeparator = "."
        return formatter.string(from: amount as NSDecimalNumber) ?? "0"
    }

    private func csvField(_ value: String) -> String {
        guard value.contains(",") || value.contains("\"") || value.contains("\n") else {
            return value
        }
        return "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\""
    }

    private static let dateTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()
}
