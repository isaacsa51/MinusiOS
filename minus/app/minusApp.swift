//
//  minusApp.swift
//  minus
//
//  Created by Isaac Emmanuel Serrano Altamirano on 07/05/26.
//

import SwiftUI
import SwiftData
import SwiftThemeKit
import UserNotifications

@main
struct minusApp: App {

    // Create single instance of the navigator(router)
    @State private var router = NavigationRouter()
    @State private var themeManager = ThemeManager()

    let container: ModelContainer
    private let dependencies: AppDependencies

    init() {
        container = ModelContainerProvider.makeContainer()
        let periodRepository = PeriodReportRepositoryImpl(context: container.mainContext)
        let transactionRepository = TransactionRepositoryImpl(context: container.mainContext)
        dependencies = AppDependencies(
            transactionRepository: transactionRepository,
            periodRepository: periodRepository,
            splitModePreferenceRepository: UserDefaultsSplitModePreferenceRepository(),
            creditCardPreferenceRepository: UserDefaultsCreditCardPreferenceRepository()
        )

        UNUserNotificationCenter.current().delegate = NotificationPresenter.shared
        RecurringNotificationService.requestAuthorizationIfNeeded()

        // Self-heals both widget snapshots for state that already existed before
        // this sync existed, or if a reload was ever missed — not just on mutation.
        Task { @MainActor in
            let active = try? await periodRepository.getActivePeriod()
            BudgetOverviewSnapshotWriter.refresh(activePeriod: active)

            guard let active else {
                SpendingHeatmapSnapshotWriter.refresh(period: nil, expenses: [])
                return
            }
            let analytics = try? await GetPeriodAnalyticsUseCase(transactionRepository: transactionRepository)
                .execute(periodId: active.id)
            SpendingHeatmapSnapshotWriter.refresh(period: active, expenses: analytics?.expenses ?? [])
        }
    }

    var body: some Scene {
        WindowGroup {
            NavigationStack(path: $router.path) {
                ThemeProvider(light: AppTheme.light, dark: AppTheme.dark) {
                    // initial screen is numpad
                    EditorView()
                        .navigationDestination(for: Destinations.self) { destination in
                            // here the Router checks what to render
                            switch destination {
                            case .editor:
                                EditorView()
                            case .settings:
                                SettingsView()
                            case .history:
                                HistoryScreen()
                            case .analytics(let periodId):
                                AnalyticsView(periodId: periodId)
                            case .pastPeriods:
                                PastPeriodsView()
                            }
                        }
                        .tint(Color.minus.primaryAction)
                }
            }
            .ignoresSafeArea(.keyboard)
            .preferredColorScheme(themeManager.colorScheme)
            .environment(router)
            .environment(themeManager)
            .environment(\.dependencies, dependencies)
            .modelContainer(container)
        }
    }
}
