import SwiftUI

// MARK: - ToastType

enum ToastType {
    case success
    case error
    case info

    var icon: String {
        switch self {
        case .success: return "checkmark.circle.fill"
        case .error:   return "xmark.circle.fill"
        case .info:    return "info.circle.fill"
        }
    }

    var iconColor: Color {
        switch self {
        case .success: return MatchaTokens.Colors.success
        case .error:   return MatchaTokens.Colors.danger
        case .info:    return MatchaTokens.Colors.accent
        }
    }

    var borderColor: Color {
        switch self {
        case .success: return MatchaTokens.Colors.success.opacity(0.35)
        case .error:   return MatchaTokens.Colors.danger.opacity(0.35)
        case .info:    return MatchaTokens.Colors.accent.opacity(0.35)
        }
    }
}

// MARK: - ToastMessage

struct ToastMessage: Equatable {
    let id: UUID
    let message: String
    let type: ToastType

    init(message: String, type: ToastType = .info) {
        self.id = UUID()
        self.message = message
        self.type = type
    }

    static func == (lhs: ToastMessage, rhs: ToastMessage) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Toast View

private struct MatchaToastView: View {
    let toast: ToastMessage
    var onDismiss: () -> Void

    @State private var isVisible = false

    var body: some View {
        HStack(spacing: MatchaTokens.Spacing.small) {
            Image(systemName: toast.type.icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(toast.type.iconColor)

            Text(toast.message)
                .font(MatchaTokens.Typography.subheadline)
                .foregroundStyle(MatchaTokens.Colors.textPrimary)
                .lineLimit(2)

            Spacer(minLength: 0)

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(MatchaTokens.Colors.textSecondary)
            }
            .accessibilityLabel("Dismiss notification")
        }
        .padding(.horizontal, MatchaTokens.Spacing.medium)
        .padding(.vertical, MatchaTokens.Spacing.small + 2)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .background(Color.black.opacity(0.55), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(toast.type.borderColor, lineWidth: 1)
        }
        .matchaShadow(MatchaTokens.Shadow.level2)
        .offset(y: isVisible ? 0 : -80)
        .opacity(isVisible ? 1 : 0)
        .onAppear {
            withAnimation(MatchaTokens.Animations.sheetPresent) {
                isVisible = true
            }
            Task {
                try? await Task.sleep(for: .seconds(3))
                dismiss()
            }
        }
        .accessibilityLabel(toast.message)
    }

    private func dismiss() {
        withAnimation(MatchaTokens.Animations.cardDismiss) {
            isVisible = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            onDismiss()
        }
    }
}

// MARK: - ViewModifier

struct MatchaToastModifier: ViewModifier {
    @Binding var toast: ToastMessage?

    func body(content: Content) -> some View {
        ZStack(alignment: .top) {
            content

            if let current = toast {
                MatchaToastView(toast: current) {
                    toast = nil
                }
                .padding(.horizontal, MatchaTokens.Spacing.large)
                .padding(.top, MatchaTokens.Spacing.small)
                .transition(.move(edge: .top).combined(with: .opacity))
                .zIndex(999)
            }
        }
    }
}

// MARK: - View extension

extension View {
    /// Presents a Matcha-styled toast overlay when `toast` is non-nil.
    /// The binding is automatically cleared after the auto-dismiss delay.
    ///
    /// Usage:
    /// ```swift
    /// @State private var toast: ToastMessage?
    /// myView.matchaToast($toast)
    /// // trigger: toast = ToastMessage(message: "Saved!", type: .success)
    /// ```
    func matchaToast(_ toast: Binding<ToastMessage?>) -> some View {
        modifier(MatchaToastModifier(toast: toast))
    }
}

// MARK: - Preview

#Preview("MatchaToast") {
    @Previewable @State var toast: ToastMessage? = nil

    ZStack {
        MatchaTokens.Colors.background.ignoresSafeArea()

        VStack(spacing: MatchaTokens.Spacing.medium) {
            Button("Show success") {
                toast = ToastMessage(message: "Collab confirmed!", type: .success)
            }
            .buttonStyle(MatchaPrimaryButtonStyle())

            Button("Show error") {
                toast = ToastMessage(message: "Something went wrong. Please try again.", type: .error)
            }
            .buttonStyle(MatchaSecondaryButtonStyle())

            Button("Show info") {
                toast = ToastMessage(message: "Your profile is in review.", type: .info)
            }
            .buttonStyle(MatchaSecondaryButtonStyle())
        }
        .padding(MatchaTokens.Spacing.large)
    }
    .matchaToast($toast)
    .preferredColorScheme(.dark)
}
