//
//  SettingsView.swift
//  minus
//
//  Created by Isaac Emmanuel Serrano Altamirano on 10/05/26.
//

import SwiftUI

struct SettingsView: View {
    @Environment(ThemeManager.self) private var themeManager

    var body: some View {
        List {
            Section("Apariencia") {
                Picker("Tema", selection: $themeManager.selectedMode) {
                    ForEach(AppThemeMode.allCases) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
                .pickerStyle(.segmented)

                Text("El tema se guarda automáticamente y se aplica en toda la app.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Ajustes")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        SettingsView()
            .environment(ThemeManager())
    }
}
