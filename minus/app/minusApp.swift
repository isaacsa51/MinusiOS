//
//  minusApp.swift
//  minus
//
//  Created by Isaac Emmanuel Serrano Altamirano on 07/05/26.
//

import SwiftUI
import SwiftData

@main
struct minusApp: App {
    
    // Create single instance of the navigator(router)
    @State private var router = NavigationRouter()
    
    let container: ModelContainer
    
    @AppStorage("selectedAppTheme") private var appTheme: ThemeManager = .system
    
    init() {
        do {
            container = try ModelContainer(for: TransactionEntity.self)
        } catch {
            fatalError("Error trying to init database: \(error.localizedDescription)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            NavigationStack(path: $router.path) {
                // initial screen is numpad
                EditorView()
                    .navigationDestination(for: Destinations.self) { destination in
                        // here the Router checks what to render
                        switch destination {
                        case .editor: EditorView()
                        case .settings: Text("Settings screen")
                        case .history: Text("Transactions History screen...")
                        }
                    }
                    .environment(router)
                    .preferredColorScheme(appTheme.colorScheme)
            }
            .modelContainer(container)
        }
    }
}
