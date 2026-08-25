//
//  SettingsView.swift
//  minus
//
//  Created by Isaac Emmanuel Serrano Altamirano on 10/05/26.
//

import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @Environment(ThemeManager.self) private var themeManager
    @Environment(\.dependencies) private var dependencies
    @AppStorage("showPastPeriodExpenses") private var showPastPeriodExpenses = true
    @AppStorage("useCreditCardPayments") private var useCreditCardPayments = false
    @AppStorage("creditCardCutoffDay") private var creditCardCutoffDay = 0
    @State private var viewModel: SettingsViewModel?
    @State private var showCutoffPrompt = false
    @State private var cutoffDayInput = ""
    @State private var showFileImporter = false

    var body: some View {
        List {
            Section("Apariencia") {
                Picker(
                    "Tema",
                    selection: Binding(
                        get: { themeManager.selectedMode },
                        set: { themeManager.selectedMode = $0 }
                    )
                ) {
                    ForEach(
                        AppThemeMode.allCases
                    ) { mode in
                        Text(
                            mode.title
                        )
                        .tag(
                            mode
                        )
                    }
                }
                .pickerStyle(.segmented)

                Text("El tema se guarda automáticamente y se aplica en toda la app.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section("Historial") {
                Toggle("Mostrar gastos de periodos anteriores", isOn: $showPastPeriodExpenses)
                    .tint(Color.minus.primaryAction)

                Text("Muestra u oculta los gastos de periodos de presupuesto pasados en el historial.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section("Tarjeta de crédito") {
                Toggle("Uso de pagos con tarjeta de crédito", isOn: $useCreditCardPayments)
                    .tint(Color.minus.primaryAction)

                if useCreditCardPayments {
                    Button {
                        cutoffDayInput = creditCardCutoffDay > 0 ? String(creditCardCutoffDay) : ""
                        showCutoffPrompt = true
                    } label: {
                        HStack {
                            Text("Día de corte")
                                .foregroundStyle(Color.minus.textPrimary)
                            Spacer()
                            Text(creditCardCutoffDay > 0 ? "\(creditCardCutoffDay)" : "Sin definir")
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Text("Marca tus gastos como pagos con tarjeta de crédito desde el numpad y lleva el seguimiento según el día de corte.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section("Datos") {
                Button {
                    Task { await viewModel?.exportCSV() }
                } label: {
                    HStack {
                        Label("Exportar backup en CSV", systemImage: "square.and.arrow.up")
                        if viewModel?.isExporting == true {
                            Spacer()
                            ProgressView()
                        }
                    }
                }
                .disabled(viewModel == nil || viewModel?.isExporting == true)

                Button {
                    showFileImporter = true
                } label: {
                    HStack {
                        Label("Importar backup CSV", systemImage: "square.and.arrow.down")
                        if viewModel?.isImporting == true {
                            Spacer()
                            ProgressView()
                        }
                    }
                }
                .disabled(viewModel == nil || viewModel?.isImporting == true)

                if let errorMessage = viewModel?.errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }

                if let importResultMessage = viewModel?.importResultMessage {
                    Text(importResultMessage)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Text("Exporta o importa tus transacciones, pagos recurrentes y los datos del periodo de presupuesto en formato CSV, compatible con la app de Android.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Ajustes")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            guard viewModel == nil else { return }
            viewModel = SettingsViewModel(
                periodRepo: dependencies.periodRepository,
                transactionRepo: dependencies.transactionRepository,
                splitModePreferenceRepo: dependencies.splitModePreferenceRepository,
                creditCardPreferenceRepo: dependencies.creditCardPreferenceRepository
            )
        }
        .sheet(isPresented: Binding(
            get: { viewModel?.exportedFileURL != nil },
            set: { isPresented in if !isPresented { viewModel?.exportedFileURL = nil } }
        )) {
            if let url = viewModel?.exportedFileURL {
                ActivityShareSheet(activityItems: [url])
            }
        }
        .fileImporter(
            isPresented: $showFileImporter,
            allowedContentTypes: [.commaSeparatedText, .plainText],
            onCompletion: { result in
                switch result {
                case .success(let url):
                    Task { await viewModel?.importCSV(from: url) }
                case .failure(let error):
                    viewModel?.errorMessage = error.localizedDescription
                }
            }
        )
        .alert("Día de corte de tu tarjeta", isPresented: $showCutoffPrompt) {
            TextField("Día del mes (1-31)", text: $cutoffDayInput)
                .keyboardType(.numberPad)
            Button("Guardar") {
                if let day = Int(cutoffDayInput), (1...31).contains(day) {
                    creditCardCutoffDay = day
                }
            }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("Indica el día del mes en el que corta tu tarjeta de crédito.")
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView()
            .environment(ThemeManager())
    }
}
