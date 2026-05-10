//
//  BudgetDetailsSheet.swift
//  minus
//
//  Created by Isaac Emmanuel Serrano Altamirano on 10/05/26.
//

import SwiftUI

struct BudgetDetailsSheet: View {
    @Environment(\.dismiss) var dismiss

    @State private var selectedPeriod: BudgetPeriod = .daily
    @State private var showEndPeriodAlert = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    SummaryCardView()

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Cómo quieres dividir el presupuesto?")
                            .font(.subheadline)
                            .foregroundStyle(Color.minus.textSecondary)
                            .padding(.horizontal, 4)

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            PeriodCard(title: "A diario", amount: "$123", isSelected: selectedPeriod == .daily) {
                                selectedPeriod = .daily
                            }

                            PeriodCard(title: "Semanal", amount: "$800", isSelected: selectedPeriod == .weekly) {
                                selectedPeriod = .weekly
                            }

                            PeriodCard(title: "Quincenal", amount: "$1,500", isSelected: selectedPeriod == .biweekly) {
                                selectedPeriod = .biweekly
                            }

                            PeriodCard(title: "Mensual", amount: "$12,123", isSelected: selectedPeriod == .monthly) {
                                selectedPeriod = .monthly
                            }
                        }
                    }

                    Spacer(minLength: 20)

                    Button(role: .destructive) {
                        showEndPeriodAlert = true
                    } label: {
                        Text("Finalizar periodo de ahorro antes de tiempo")
                            .font(.system(size: 16, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.minus.destructive.opacity(0.15))
                            .foregroundStyle(Color.minus.destructive)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                }
                .padding(20)
            }
            .background(Color.minus.background.ignoresSafeArea())
            .navigationTitle("Detalles del periodo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(Color.minus.textSecondary)
                    }
                }
            }
            // generate "alert dialog" for ending early the period
            .confirmationDialog("Terminar periodo actual?", isPresented: $showEndPeriodAlert, titleVisibility: .visible) {
                Button("Finalizar y crear uno nuevo", role: .destructive) {
                    // TODO: call FinishPeriodEarlyUseCase or delegate it into the viewmodel to not tight UI with business logic
                    dismiss()
                }

                Button("Cancelar", role: .cancel) { }
            } message: {
                Text("Esta acción cerrará el historial de este periodo y se te pedirá información sobre el nuevo periodo.")
            }
        }
    }
}
