import SwiftUI

struct RecurrenceOptionsSheet: View {
    @Environment(\.dismiss) var dismiss
    var viewModel: EditorViewModel

    var body: some View {
        VStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 2.5)
                .fill(Color.minus.textSecondary.opacity(0.4))
                .frame(width: 36, height: 5)
                .padding(.top, 10)

            ScrollView {
                VStack(spacing: 24) {
                    Text("Pago Recurrente")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(Color.minus.textPrimary)
                        .padding(.top, 16)

                    VStack(spacing: 0) {
                        frequencyRow

                        if viewModel.selectedFrequency == .MONTHLY {
                            Divider()
                                .padding(.leading, 52)

                            subscriptionDayRow
                        }

                        Divider()
                            .padding(.leading, 52)

                        endDateRow
                    }
                    .background(Color.minus.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                    Button {
                        dismiss()
                    } label: {
                        Text("Listo")
                            .font(.system(size: 18, weight: .bold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.minus.primaryAction)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                }
                .padding(20)
            }
        }
        .background(Color.minus.background.ignoresSafeArea())
        .presentationSizing(.fitted)
    }

    private var frequencyRow: some View {
        Menu {
            ForEach([RecurrentFrequency.WEEKLY, .BIWEEKLY, .MONTHLY], id: \.self) { freq in
                Button {
                    viewModel.selectedFrequency = freq
                } label: {
                    HStack {
                        Text(freq.displayName)
                        if viewModel.selectedFrequency == freq {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 18))
                    .foregroundStyle(Color.minus.textSecondary)
                    .frame(width: 24)

                Text("Frecuencia")
                    .font(.body)
                    .foregroundStyle(Color.minus.textPrimary)

                Spacer()

                Text(viewModel.selectedFrequency.displayName)
                    .font(.subheadline)
                    .foregroundStyle(Color.minus.textSecondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
    }

    private var subscriptionDayRow: some View {
        HStack(spacing: 14) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 18))
                .foregroundStyle(Color.minus.textSecondary)
                .frame(width: 24)

            Text("Día del mes")
                .font(.body)
                .foregroundStyle(Color.minus.textPrimary)

            Spacer()

            Picker("", selection: Bindable(viewModel).subscriptionDay) {
                ForEach(1...31, id: \.self) { day in
                    Text("\(day)").tag(day)
                }
            }
            .pickerStyle(.menu)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    private var endDateRow: some View {
        HStack(spacing: 14) {
            Image(systemName: "calendar")
                .font(.system(size: 18))
                .foregroundStyle(Color.minus.textSecondary)
                .frame(width: 24)

            Text("Fecha límite")
                .font(.body)
                .foregroundStyle(Color.minus.textPrimary)

            Spacer()

            DatePicker("", selection: Bindable(viewModel).recurrentEndDate, displayedComponents: .date)
                .labelsHidden()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}
