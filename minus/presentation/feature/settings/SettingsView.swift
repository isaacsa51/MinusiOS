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
    @State private var reserveUpcomingCharges = false

    var body: some View {
        List {
            Section("Appearance") {
                Picker(
                    "Theme",
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

                Text("The theme saves automatically and applies across the app.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section("History") {
                Toggle("Show past period expenses", isOn: $showPastPeriodExpenses)
                    .tint(Color.minus.primaryAction)

                Text("Shows or hides past budget periods' expenses in the history.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section("Credit Card") {
                Toggle("Use credit card payments", isOn: $useCreditCardPayments)
                    .tint(Color.minus.primaryAction)

                if useCreditCardPayments {
                    Button {
                        cutoffDayInput = creditCardCutoffDay > 0 ? String(creditCardCutoffDay) : ""
                        showCutoffPrompt = true
                    } label: {
                        HStack {
                            Text("Cutoff day")
                                .foregroundStyle(Color.minus.textPrimary)
                            Spacer()
                            Text(creditCardCutoffDay > 0 ? "\(creditCardCutoffDay)" : "Not set")
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Text("Mark your expenses as credit card charges from the numpad and track them by cutoff day.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section("Budget") {
                Toggle("Reserve upcoming charges", isOn: Binding(
                    get: { reserveUpcomingCharges },
                    set: { newValue in
                        reserveUpcomingCharges = newValue
                        dependencies.reservedChargesPreferenceRepository
                            .setReserveUpcomingChargesEnabled(newValue)
                    }
                ))
                .tint(Color.minus.primaryAction)

                Text("Sets aside every recurring charge due later in the current period from day one, instead of deducting each one on its due date. Your remaining budget and daily amount will only show what is truly free to spend.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section("Data") {
                Button {
                    Task { await viewModel?.exportCSV() }
                } label: {
                    HStack {
                        Label("Export CSV backup", systemImage: "square.and.arrow.up")
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
                        Label("Import CSV backup", systemImage: "square.and.arrow.down")
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

                Text("Export or import your transactions, recurring payments, and budget period data in CSV format, compatible with the Android app.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            reserveUpcomingCharges = dependencies.reservedChargesPreferenceRepository
                .isReserveUpcomingChargesEnabled()
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
        .alert("Your card's cutoff day", isPresented: $showCutoffPrompt) {
            TextField("Day of month (1-31)", text: $cutoffDayInput)
                .keyboardType(.numberPad)
            Button("Save") {
                if let day = Int(cutoffDayInput), (1...31).contains(day) {
                    creditCardCutoffDay = day
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Enter the day of the month your credit card cuts off.")
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView()
            .environment(ThemeManager())
    }
}
