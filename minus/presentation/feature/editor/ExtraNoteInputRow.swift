import SwiftUI

/// Optional free-text note for the transaction being entered. Sits under the
/// category row and, like it, collapses to nothing until there's an amount.
struct ExtraNoteInputRow: View {
    let viewModel: EditorViewModel
    @FocusState private var isInputFocused: Bool

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "text.alignleft")
                .font(.system(size: 14))
                .foregroundStyle(Color.minus.textSecondary)

            TextField("Add a note", text: Bindable(viewModel).extraNoteText, axis: .vertical)
                .font(.system(size: 15))
                .foregroundStyle(Color.minus.textPrimary)
                .textInputAutocapitalization(.sentences)
                .submitLabel(.done)
                .lineLimit(1...3)
                .focused($isInputFocused)

            if isInputFocused {
                Button {
                    isInputFocused = false
                } label: {
                    Image(systemName: "checkmark")
                        .font(.system(size: 13, weight: .semibold))
                }
                .transition(.scale.combined(with: .opacity))
            } else if !viewModel.extraNoteText.isEmpty {
                Button {
                    viewModel.extraNoteText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.minus.textSecondary)
                }
                .accessibilityLabel("Clear note")
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(minHeight: CategoryBadgeView.height)
        .background(Color.minus.surface)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .animation(.easeInOut(duration: 0.2), value: isInputFocused)
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
        .frame(height: viewModel.hasValue ? nil : 0, alignment: .top)
        .clipped()
        .opacity(viewModel.hasValue ? 1 : 0)
        .animation(.easeInOut(duration: 0.2), value: viewModel.hasValue)
    }
}
