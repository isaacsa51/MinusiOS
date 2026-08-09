//
//  SettingsViewModel.swift
//  minus
//

import Foundation

@MainActor
@Observable
class SettingsViewModel {
    var isExporting = false
    var exportedFileURL: URL?
    var errorMessage: String?

    var isImporting = false
    var importResultMessage: String?

    private let exportBackupUseCase: ExportBackupUseCase
    private let importBackupUseCase: ImportBackupUseCase
    private let splitModePreferenceRepository: SplitModePreferenceRepository
    private let creditCardPreferenceRepository: CreditCardPreferenceRepository

    init(
        periodRepo: PeriodRepository,
        transactionRepo: TransactionRepository,
        splitModePreferenceRepo: SplitModePreferenceRepository,
        creditCardPreferenceRepo: CreditCardPreferenceRepository
    ) {
        self.exportBackupUseCase = ExportBackupUseCase(periodRepository: periodRepo, transactionRepository: transactionRepo)
        self.importBackupUseCase = ImportBackupUseCase(periodRepository: periodRepo, transactionRepository: transactionRepo)
        self.splitModePreferenceRepository = splitModePreferenceRepo
        self.creditCardPreferenceRepository = creditCardPreferenceRepo
    }

    func exportCSV() async {
        isExporting = true
        errorMessage = nil
        do {
            let csv = try await exportBackupUseCase.execute(
                creditCardCutoffDay: creditCardPreferenceRepository.getCutoffDay()
            )
            exportedFileURL = try writeToTempFile(csv)
        } catch {
            errorMessage = error.localizedDescription
        }
        isExporting = false
    }

    func importCSV(from url: URL) async {
        isImporting = true
        errorMessage = nil
        importResultMessage = nil

        let didAccess = url.startAccessingSecurityScopedResource()
        defer { if didAccess { url.stopAccessingSecurityScopedResource() } }

        do {
            let csv = try String(contentsOf: url, encoding: .utf8)
            let result = try await importBackupUseCase.execute(csv: csv)

            if let cutoffDay = result.creditCardCutoffDay {
                creditCardPreferenceRepository.setCutoffDay(cutoffDay)
                creditCardPreferenceRepository.setCreditCardPaymentsEnabled(true)
            }
            if let splitMode = result.splitMode {
                splitModePreferenceRepository.setSelectedSplitMode(splitMode)
            }

            importResultMessage = String(
                localized: "Imported \(result.importedTransactions) new and updated \(result.updatedTransactions) existing transactions across \(result.createdPeriods) new period(s)."
            )
        } catch {
            errorMessage = error.localizedDescription
        }
        isImporting = false
    }

    private func writeToTempFile(_ content: String) throws -> URL {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd-HHmm"
        let filename = "minus_backup-\(formatter.string(from: Date())).csv"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        try content.write(to: url, atomically: true, encoding: .utf8)
        return url
    }
}
