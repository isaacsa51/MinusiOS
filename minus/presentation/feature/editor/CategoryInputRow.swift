import SwiftUI

struct CategoryInputRow: View {
    let viewModel: EditorViewModel
    @FocusState private var isInputFocused: Bool

    private var showBadges: Bool {
        !isInputFocused && !viewModel.savedCategories.isEmpty
    }

    var body: some View {
        HStack(spacing: 8) {
            if showBadges {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(viewModel.savedCategories) { category in
                            if let name = category.name {
                                CategoryBadgeView(
                                    name: name,
                                    isSelected: viewModel.categoryText == name,
                                    onTap: { viewModel.selectCategory(category) }
                                )
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .defaultScrollAnchor(.trailing)
                .transition(.opacity)
            }

            HStack(spacing: 6) {
                Image(systemName: "tag")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.minus.textSecondary)
                // Single line always; fixedSize makes the field hug its
                // content width instead of wrapping, so the capsule grows
                // wider as you type rather than growing taller.
                TextField("Category", text: Bindable(viewModel).categoryText)
                    .font(.system(size: 15))
                    .foregroundStyle(Color.minus.textPrimary)
                    .textInputAutocapitalization(.words)
                    .submitLabel(.done)
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
                    .focused($isInputFocused)

                if isInputFocused {
                    Button {
                        isInputFocused = false
                    } label: {
                        Image(systemName: "checkmark")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(minHeight: CategoryBadgeView.height)
            .background(Color.minus.surface)
            .clipShape(Capsule())
            // No maxWidth cap when unfocused: the capsule sizes to its
            // content (via fixedSize above) down to this minimum, and
            // layoutPriority makes it win space over the chip scroll view
            // — which just shows fewer chips (still reachable by scrolling)
            // as the input claims more of the row instead of either
            // truncating the input or wrapping its text.
            .frame(minWidth: 140, maxWidth: isInputFocused ? .infinity : nil)
            .layoutPriority(1)
        }
        .animation(.easeInOut(duration: 0.2), value: isInputFocused)
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
        .frame(height: viewModel.hasValue ? nil : 0, alignment: .top)
        .clipped()
        .opacity(viewModel.hasValue ? 1 : 0)
        .animation(.easeInOut(duration: 0.2), value: viewModel.hasValue)
    }
}
