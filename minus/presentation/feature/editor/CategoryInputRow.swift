//
//  CategoryInputRow.swift
//  minus
//

import SwiftUI

struct CategoryInputRow: View {
    let viewModel: EditorViewModel
    @FocusState private var isInputFocused: Bool

    private var showBadges: Bool {
        !isInputFocused && !viewModel.savedCategories.isEmpty
    }

    var body: some View {
        HStack(spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "tag")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.minus.textSecondary)
                TextField("Category", text: Bindable(viewModel).categoryText)
                    .font(.system(size: 15))
                    .foregroundStyle(Color.minus.textPrimary)
                    .textInputAutocapitalization(.words)
                    .submitLabel(.done)
                    .focused($isInputFocused)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.minus.surface)
            .clipShape(Capsule())
            .frame(maxWidth: isInputFocused ? .infinity : 140)

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
                }
                .transition(.opacity)
            }
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
