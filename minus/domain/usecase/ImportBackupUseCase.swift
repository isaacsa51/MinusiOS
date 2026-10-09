//
//  ImportBackupUseCase.swift
//  minus
//

import Foundation

struct ImportBackupResult {
    let importedTransactions: Int
    let updatedTransactions: Int
    let createdPeriods: Int
    let creditCardCutoffDay: Int?
    let splitMode: BudgetPeriod?
}

enum ImportBackupError: LocalizedError, Equatable {
    case emptyFile
    case missingHeader

    var errorDescription: String? {
        switch self {
        case .emptyFile:
            return String(localized: "The selected file is empty.")
        case .missingHeader:
            return String(localized: "The file doesn't look like a minus CSV backup.")
        }
    }
}

class ImportBackupUseCase {
    private let periodRepository: PeriodRepository
    private let transactionRepository: TransactionRepository

    init(periodRepository: PeriodRepository, transactionRepository: TransactionRepository) {
        self.periodRepository = periodRepository
        self.transactionRepository = transactionRepository
    }

    func execute(csv: String) async throws -> ImportBackupResult {
        var lines = csv
            .replacingOccurrences(of: "\r\n", with: "\n")
            .split(separator: "\n", omittingEmptySubsequences: true)
            .map(String.init)

        guard !lines.isEmpty else { throw ImportBackupError.emptyFile }

        let header = parseCSVLine(lines.removeFirst())
        guard header.contains("date"), header.contains("amount") else {
            throw ImportBackupError.missingHeader
        }
        let columnIndex = Dictionary(uniqueKeysWithValues: header.enumerated().map { ($1, $0) })

        var metaFields: [String: String]?
        // Past periods, keyed by their external (Android) id. Each carries the
        // budget total and date range that nothing else in the file records.
        var archivedRows: [String: [String: String]] = [:]
        var transactionRows: [[String: String]] = []

        for line in lines {
            let fields = parseCSVLine(line)
            var row: [String: String] = [:]
            for (name, index) in columnIndex where index < fields.count {
                row[name] = fields[index]
            }
            switch row["date"] {
            case "__META__":
                metaFields = row
            case "__ARCHIVED__":
                if let externalId = Self.nonEmpty(row["period_id"]) {
                    archivedRows[externalId] = row
                }
            default:
                transactionRows.append(row)
            }
        }

        let creditCardCutoffDay = metaFields?["credit_card_cutoff_day"].flatMap { Int($0) }
        let splitMode = metaFields?["split_mode"].flatMap { BudgetPeriod(rawValue: $0.lowercased()) }

        var periodIdCache: [String: UUID] = [:]
        var createdPeriods = 0

        if let metaFields, let currentExternalId = metaFields["current_period_id"], !currentExternalId.isEmpty {
            let localId = try await resolvedPeriodId(
                forExternalId: currentExternalId,
                fallback: { self.period(from: metaFields, externalId: currentExternalId) },
                createdCount: &createdPeriods
            )
            periodIdCache[currentExternalId] = localId
        }

        for (externalId, row) in archivedRows where periodIdCache[externalId] == nil {
            periodIdCache[externalId] = try await resolvedPeriodId(
                forExternalId: externalId,
                fallback: { self.period(from: row, externalId: externalId) },
                createdCount: &createdPeriods
            )
        }

        var importedCount = 0
        var updatedCount = 0

        for row in transactionRows {
            guard let dateString = row["date"], let createdAt = Self.dateTimeFormatter.date(from: dateString),
                  let amountString = row["amount"], let amount = Decimal(string: amountString), amount > 0
            else { continue }

            let externalPeriodId = (row["period_id"]?.isEmpty == false) ? row["period_id"]! : "0"
            let localPeriodId: UUID
            if let cached = periodIdCache[externalPeriodId] {
                localPeriodId = cached
            } else {
                localPeriodId = try await resolvedPeriodId(
                    forExternalId: externalPeriodId,
                    fallback: {
                        PeriodKey(
                            id: UUID(),
                            startDate: createdAt,
                            endDate: createdAt,
                            mappingNode: .activeBucket,
                            totalBudget: 0,
                            currency: Self.nonEmpty(metaFields?["currency_code"]) ?? "USD",
                            remainingStrategy: .SPLIT_EQUALLY,
                            periodType: .monthly,
                            daysInPeriod: 30,
                            externalId: externalPeriodId
                        )
                    },
                    createdCount: &createdPeriods
                )
                periodIdCache[externalPeriodId] = localPeriodId
            }

            let externalTransactionId = (row["id"]?.isEmpty == false) ? row["id"]! : UUID().uuidString
            // Android renamed this column to "category"; older iOS exports
            // still say "comment".
            let categoryName = Self.nonEmpty(row["category"]) ?? Self.nonEmpty(row["comment"])
            let extraNote = Self.nonEmpty(row["extra_note"])
            let isRecurrent = row["is_recurrent"] == "1"
            let frequency = isRecurrent ? row["frequency"].flatMap(RecurrentFrequency.init(rawValue:)) : nil
            let recurrentEndDate = row["end_date"].flatMap { $0.isEmpty ? nil : Self.dateFormatter.date(from: $0) } ?? nil
            let subscriptionDay = row["sub_day"].flatMap { Int($0) }
            let isCreditCardCharge = row["is_credit"] == "1"
            let isCreditCardPaid = row["is_credit_paid"] == "1"

            if let existing = try await transactionRepository.getTransaction(byClientGeneratedId: externalTransactionId) {
                let updated = Transaction(
                    id: existing.id,
                    amount: amount,
                    createdAt: createdAt,
                    clientGeneratedId: existing.clientGeneratedId,
                    periodId: localPeriodId,
                    recurrentFrequency: frequency,
                    recurrentEndDate: recurrentEndDate,
                    subscriptionDay: subscriptionDay,
                    categoryId: existing.categoryId,
                    categoryName: categoryName,
                    isIncome: existing.isIncome,
                    isCreditCardCharge: isCreditCardCharge,
                    isCreditCardPaid: isCreditCardPaid,
                    extraNote: extraNote
                )
                try await transactionRepository.save(transaction: updated)
                updatedCount += 1
            } else {
                let created = Transaction(
                    id: UUID(),
                    amount: amount,
                    createdAt: createdAt,
                    clientGeneratedId: externalTransactionId,
                    periodId: localPeriodId,
                    recurrentFrequency: frequency,
                    recurrentEndDate: recurrentEndDate,
                    subscriptionDay: subscriptionDay,
                    categoryId: UUID(),
                    categoryName: categoryName,
                    isIncome: false,
                    isCreditCardCharge: isCreditCardCharge,
                    isCreditCardPaid: isCreditCardPaid,
                    extraNote: extraNote
                )
                try await transactionRepository.save(transaction: created)
                importedCount += 1
            }
        }

        return ImportBackupResult(
            importedTransactions: importedCount,
            updatedTransactions: updatedCount,
            createdPeriods: createdPeriods,
            creditCardCutoffDay: creditCardCutoffDay,
            splitMode: splitMode
        )
    }

    private func resolvedPeriodId(
        forExternalId externalId: String,
        fallback: () throws -> PeriodKey,
        createdCount: inout Int
    ) async throws -> UUID {
        if let existing = try await periodRepository.getPeriod(byExternalId: externalId) {
            return existing.id
        }
        let newPeriod = try fallback()
        try await periodRepository.save(period: newPeriod)
        createdCount += 1
        return newPeriod.id
    }

    /// Builds a period from either a `__META__` row (the active period) or an
    /// `__ARCHIVED__` one (a closed period). Archived rows carry fewer columns,
    /// so the gaps fall back to what the date range implies.
    private func period(from fields: [String: String], externalId: String) -> PeriodKey {
        let totalBudget = Self.nonEmpty(fields["budget_total"]).flatMap { Decimal(string: $0) } ?? 0
        let periodType = Self.nonEmpty(fields["budget_period"])
            .flatMap { BudgetPeriod(rawValue: $0.lowercased()) } ?? .monthly
        let startDate = Self.nonEmpty(fields["budget_start_date"])
            .flatMap { Self.dateFormatter.date(from: $0) } ?? Date()
        let endDate = Self.nonEmpty(fields["budget_end_date"])
            .flatMap { Self.dateFormatter.date(from: $0) }
        let currency = Self.nonEmpty(fields["currency_code"]) ?? "USD"
        let strategy = Self.nonEmpty(fields["remaining_budget_strategy"])
            .flatMap { RemainingBudgetStrategy(rawValue: $0) } ?? .SPLIT_EQUALLY
        let daysInPeriod = Self.nonEmpty(fields["days_in_period"]).flatMap { Int($0) }
            ?? endDate.map { Self.inclusiveDayCount(from: startDate, to: $0) }
            ?? 30

        return PeriodKey(
            id: UUID(),
            startDate: startDate,
            endDate: endDate,
            mappingNode: .activeBucket,
            totalBudget: totalBudget,
            currency: currency,
            remainingStrategy: strategy,
            periodType: periodType,
            daysInPeriod: daysInPeriod,
            externalId: externalId
        )
    }

    /// A present-but-blank CSV field means "absent", not "empty string".
    private static func nonEmpty(_ value: String?) -> String? {
        guard let value, !value.isEmpty else { return nil }
        return value
    }

    private static func inclusiveDayCount(from start: Date, to end: Date) -> Int {
        let calendar = Calendar.current
        let days = calendar.dateComponents(
            [.day],
            from: calendar.startOfDay(for: start),
            to: calendar.startOfDay(for: end)
        ).day ?? 0
        return max(1, days + 1)
    }

    private func parseCSVLine(_ line: String) -> [String] {
        var fields: [String] = []
        var current = ""
        var inQuotes = false
        let chars = Array(line)
        var i = 0
        while i < chars.count {
            let char = chars[i]
            if inQuotes {
                if char == "\"" {
                    if i + 1 < chars.count, chars[i + 1] == "\"" {
                        current.append("\"")
                        i += 1
                    } else {
                        inQuotes = false
                    }
                } else {
                    current.append(char)
                }
            } else if char == "\"" {
                inQuotes = true
            } else if char == "," {
                fields.append(current)
                current = ""
            } else {
                current.append(char)
            }
            i += 1
        }
        fields.append(current)
        return fields
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
