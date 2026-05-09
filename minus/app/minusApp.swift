//
//  minusApp.swift
//  minus
//
//  Created by Isaac Emmanuel Serrano Altamirano on 07/05/26.
//

import SwiftUI

@main
struct minusApp: App {
    
    // Create single instance of the navigator(router)
    @State private var router = NavigationRouter()
    
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
            }
        }
    }
}
