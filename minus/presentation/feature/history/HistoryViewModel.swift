//
//  HistoryViewModel.swift
//  minus
//

import Foundation

@MainActor
@Observable
class HistoryViewModel {
    private(set) var transactions: [Transaction] = []
    var errorMessage: String?

    private let transactionRepository: TransactionRepository
    private let deleteTransactionUseCase: DeleteTransactionUseCase

    init(transactionRepository: TransactionRepository) {
        self.transactionRepository = transactionRepository
        self.deleteTransactionUseCase = DeleteTransactionUseCase(repository: transactionRepository)
    }

    func load() async {
        do {
            transactions = try await transactionRepository.getAllTransactions()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteTransaction(id: UUID) async {
        do {
            try await deleteTransactionUseCase.execute(transactionId: id)
            await load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
