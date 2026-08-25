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
        dependencies = AppDependencies(
            transactionRepository: TransactionRepositoryImpl(context: container.mainContext),
            periodRepository: PeriodReportRepositoryImpl(context: container.mainContext),
            splitModePreferenceRepository: UserDefaultsSplitModePreferenceRepository(),
            creditCardPreferenceRepository: UserDefaultsCreditCardPreferenceRepository()
        )

        UNUserNotificationCenter.current().delegate = NotificationPresenter.shared
        RecurringNotificationService.requestAuthorizationIfNeeded()
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
