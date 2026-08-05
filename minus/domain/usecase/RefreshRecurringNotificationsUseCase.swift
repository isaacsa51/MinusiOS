import Foundation

class RefreshRecurringNotificationsUseCase {
    private let transactionRepository: TransactionRepository

    init(transactionRepository: TransactionRepository) {
        self.transactionRepository = transactionRepository
    }

    func execute() async {
        guard let transactions = try? await transactionRepository.getAllTransactions() else { return }

        for transaction in transactions {
            guard let frequency = transaction.recurrentFrequency else { continue }
            RecurringNotificationService.schedule(
                transactionId: transaction.id,
                amount: transaction.amount,
                categoryName: transaction.categoryName,
                frequency: frequency,
                startDate: transaction.createdAt,
                endDate: transaction.recurrentEndDate,
                subscriptionDay: transaction.subscriptionDay
            )
        }
    }
}
