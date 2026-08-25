//
//  PastPeriodsView.swift
//  minus
//

import SwiftUI

struct PastPeriodsView: View {
    @Environment(NavigationRouter.self) private var router
    @Environment(\.dependencies) private var dependencies
    @State private var periods: [PeriodKey] = []
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        Group {
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if periods.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(periods) { period in
                            Button {
                                router.navigate(to: .analytics(periodId: period.id))
                            } label: {
                                PastPeriodRow(period: period)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(16)
                }
            }
        }
        .background(Color.minus.background.ignoresSafeArea())
        .navigationTitle("Past Periods")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await load()
        }
        .alert("Error", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private func load() async {
        isLoading = true
        do {
            let all = try await dependencies.periodRepository.getAllPeriods()
            let now = Date()
            // Only periods that have actually concluded — excludes the open-ended active
            // period (endDate nil) and any period scheduled but not yet reached its end date.
            periods = all
                .filter { period in
                    guard let end = period.endDate else { return false }
                    return end <= now
                }
                .sorted { $0.startDate > $1.startDate }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 32))
                .foregroundStyle(Color.minus.textSecondary)
            Text("No past budget periods yet.")
                .font(.system(size: 15))
                .foregroundStyle(Color.minus.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(40)
    }
}

private struct PastPeriodRow: View {
    let period: PeriodKey

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        formatter.locale = Locale(identifier: "en_US")
        return formatter
    }()

    private var dateRangeText: String {
        "\(Self.dateFormatter.string(from: period.startDate)) – \(Self.dateFormatter.string(from: period.effectiveEndDate))"
    }

    private var amountText: String {
        let symbol = Currency.find(byCode: period.currency)?.symbol ?? "$"
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        return "\(symbol)\(formatter.string(from: period.totalBudget as NSDecimalNumber) ?? "0")"
    }

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(dateRangeText)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Color.minus.textPrimary)
                Text(period.periodType.displayTitle)
                    .font(.system(size: 12))
                    .foregroundStyle(Color.minus.textSecondary)
            }

            Spacer()

            Text(amountText)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.minus.textPrimary)

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color.minus.textSecondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color.minus.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

private class PreviewPeriodRepository: PeriodRepository {
    func save(period: PeriodKey) async throws {}
    func getPeriod(id: UUID) async throws -> PeriodKey? { nil }
    func getPeriod(byExternalId externalId: String) async throws -> PeriodKey? { nil }
    func getActivePeriod() async throws -> PeriodKey? { nil }
    func closePeriod(id: UUID, finalEndDate: Date) async throws {}

    func getAllPeriods() async throws -> [PeriodKey] {
        (0..<3).map { index in
            let start = Calendar.current.date(byAdding: .month, value: -(index + 1), to: Date())!
            let end = Calendar.current.date(byAdding: .day, value: 27, to: start)!
            return PeriodKey(
                id: UUID(),
                startDate: start,
                endDate: end,
                mappingNode: .activeBucket,
                totalBudget: 15000,
                currency: "MXN",
                remainingStrategy: .SPLIT_EQUALLY,
                periodType: .monthly,
                daysInPeriod: 28
            )
        }
    }
}

#Preview {
    NavigationStack {
        PastPeriodsView()
            .environment(NavigationRouter())
            .environment(\.dependencies, .preview(periodRepository: PreviewPeriodRepository()))
    }
}
