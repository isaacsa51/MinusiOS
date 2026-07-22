import SwiftUI

struct TopSheetContainer<Content: View>: View {
    @Binding var isPresented: Bool
    let content: () -> Content

    @State private var sheetDragOffset: CGFloat = 0

    private let dismissThreshold: CGFloat = 60
    private let resistance: CGFloat = 0.6
    private let sheetHeightFraction: CGFloat = 0.88

    init(
        isPresented: Binding<Bool>,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self._isPresented = isPresented
        self.content = content
    }

    var body: some View {
        ZStack(alignment: .top) {
            if isPresented {
                scrim
                sheet
            }
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.85), value: isPresented)
    }

    private var scrim: some View {
        Color.black
            .opacity(0.4)
            .ignoresSafeArea()
            .contentShape(Rectangle())
            .onTapGesture { close() }
            .transition(.opacity)
    }

    private var sheet: some View {
        VStack(spacing: 0) {
            header
            divider
            content()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            dismissHandle
        }
        .frame(maxWidth: .infinity, alignment: .top)
        .frame(maxHeight: UIScreen.main.bounds.height * sheetHeightFraction, alignment: .top)
        .padding(.top, 50)
        .background(Color.minus.background)
        .clipShape(
            UnevenRoundedRectangle(
                bottomLeadingRadius: 24,
                bottomTrailingRadius: 24,
                style: .continuous
            )
        )
        .ignoresSafeArea(edges: .top)
        .offset(y: sheetDragOffset)
        .transition(.move(edge: .top))
    }

    private var header: some View {
        HStack {
            Text("Historial")
                .font(.headline)
                .foregroundStyle(Color.minus.textPrimary)
            Spacer()
            Button(action: { close() }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(Color.minus.textSecondary)
            }
            .accessibilityLabel("Cerrar")
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 12)
    }

    private var divider: some View {
        Rectangle()
            .fill(Color.minus.divider)
            .frame(height: 0.5)
    }

    private var dismissHandle: some View {
        VStack(spacing: 6) {
            Divider()
            Capsule()
                .fill(Color.minus.textSecondary.opacity(0.4))
                .frame(width: 36, height: 4)
                .padding(.top, 6)
        }
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
        .gesture(
            DragGesture()
                .onChanged { value in
                    guard value.translation.height < 0 else { return }
                    sheetDragOffset = value.translation.height * resistance
                }
                .onEnded { value in
                    if value.translation.height < -dismissThreshold {
                        close()
                    } else {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                            sheetDragOffset = 0
                        }
                    }
                }
        )
    }

    private func close() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
            isPresented = false
            sheetDragOffset = 0
        }
    }
}

extension View {
    func topSheet<Content: View>(
        isPresented: Binding<Bool>,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        overlay {
            TopSheetContainer(isPresented: isPresented, content: content)
        }
    }
}
