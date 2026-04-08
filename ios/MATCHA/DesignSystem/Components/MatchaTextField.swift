import SwiftUI

// MARK: - Validation State

enum MatchaFieldState: Equatable {
    case normal
    case focused
    case success
    case error(String)

    var borderColor: Color {
        switch self {
        case .normal:         return MatchaTokens.Colors.outline
        case .focused:        return MatchaTokens.Colors.accent
        case .success:        return MatchaTokens.Colors.success
        case .error:          return MatchaTokens.Colors.danger
        }
    }

    var errorMessage: String? {
        if case .error(let msg) = self { return msg }
        return nil
    }
}

// MARK: - MatchaTextField

struct MatchaTextField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    var fieldState: MatchaFieldState = .normal
    var keyboardType: UIKeyboardType = .default
    var autocapitalization: TextInputAutocapitalization = .sentences
    var autocorrectionDisabled: Bool = false
    var contentType: UITextContentType? = nil

    @FocusState private var isFocused: Bool

    private var effectiveState: MatchaFieldState {
        isFocused ? .focused : fieldState
    }

    var body: some View {
        VStack(alignment: .leading, spacing: MatchaTokens.Spacing.xSmall) {
            HStack(spacing: MatchaTokens.Spacing.small) {
                leadingIcon
                inputField
                trailingIcon
            }
            .padding(.horizontal, MatchaTokens.Spacing.medium)
            .padding(.vertical, 14)
            .background(MatchaTokens.Colors.elevated, in: RoundedRectangle(cornerRadius: MatchaTokens.Radius.button, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: MatchaTokens.Radius.button, style: .continuous)
                    .strokeBorder(effectiveState.borderColor, lineWidth: isFocused ? 1.5 : 1)
            }
            .animation(MatchaTokens.Animations.buttonPress, value: isFocused)
            .animation(MatchaTokens.Animations.buttonPress, value: fieldState)

            if let message = fieldState.errorMessage {
                errorLabel(message)
            }
        }
    }

    @ViewBuilder
    private var leadingIcon: some View {
        Image(systemName: icon)
            .font(.system(size: 16, weight: .medium))
            .foregroundStyle(isFocused ? MatchaTokens.Colors.accent : MatchaTokens.Colors.textSecondary)
            .frame(width: 20)
            .animation(MatchaTokens.Animations.buttonPress, value: isFocused)
    }

    @ViewBuilder
    private var inputField: some View {
        TextField(placeholder, text: $text)
            .font(MatchaTokens.Typography.body)
            .foregroundStyle(MatchaTokens.Colors.textPrimary)
            .tint(MatchaTokens.Colors.accent)
            .keyboardType(keyboardType)
            .textInputAutocapitalization(autocapitalization)
            .autocorrectionDisabled(autocorrectionDisabled)
            .focused($isFocused)
            .apply {
                if let type = contentType {
                    $0.textContentType(type)
                } else {
                    $0
                }
            }
    }

    @ViewBuilder
    private var trailingIcon: some View {
        switch fieldState {
        case .success:
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(MatchaTokens.Colors.success)
                .font(.system(size: 16))
                .transition(.scale.combined(with: .opacity))
        case .error:
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundStyle(MatchaTokens.Colors.danger)
                .font(.system(size: 16))
                .transition(.scale.combined(with: .opacity))
        default:
            EmptyView()
        }
    }

    private func errorLabel(_ message: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 11))
            Text(message)
                .font(MatchaTokens.Typography.caption)
        }
        .foregroundStyle(MatchaTokens.Colors.danger)
        .padding(.horizontal, MatchaTokens.Spacing.xSmall)
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}

// MARK: - MatchaSecureField

struct MatchaSecureField: View {
    let placeholder: String
    @Binding var text: String
    var fieldState: MatchaFieldState = .normal
    var contentType: UITextContentType? = .password

    @FocusState private var isFocused: Bool
    @State private var isVisible: Bool = false

    private var effectiveState: MatchaFieldState {
        isFocused ? .focused : fieldState
    }

    var body: some View {
        VStack(alignment: .leading, spacing: MatchaTokens.Spacing.xSmall) {
            HStack(spacing: MatchaTokens.Spacing.small) {
                Image(systemName: "lock")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(isFocused ? MatchaTokens.Colors.accent : MatchaTokens.Colors.textSecondary)
                    .frame(width: 20)
                    .animation(MatchaTokens.Animations.buttonPress, value: isFocused)

                Group {
                    if isVisible {
                        TextField(placeholder, text: $text)
                            .textContentType(.password)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                    } else {
                        SecureField(placeholder, text: $text)
                            .textContentType(contentType ?? .password)
                    }
                }
                .font(MatchaTokens.Typography.body)
                .foregroundStyle(MatchaTokens.Colors.textPrimary)
                .tint(MatchaTokens.Colors.accent)
                .focused($isFocused)

                Button {
                    isVisible.toggle()
                } label: {
                    Image(systemName: isVisible ? "eye.slash" : "eye")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(MatchaTokens.Colors.textSecondary)
                }
                .accessibilityLabel(isVisible ? "Hide password" : "Show password")
            }
            .padding(.horizontal, MatchaTokens.Spacing.medium)
            .padding(.vertical, 14)
            .background(MatchaTokens.Colors.elevated, in: RoundedRectangle(cornerRadius: MatchaTokens.Radius.button, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: MatchaTokens.Radius.button, style: .continuous)
                    .strokeBorder(effectiveState.borderColor, lineWidth: isFocused ? 1.5 : 1)
            }
            .animation(MatchaTokens.Animations.buttonPress, value: isFocused)
            .animation(MatchaTokens.Animations.buttonPress, value: fieldState)

            if let message = fieldState.errorMessage {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 11))
                    Text(message)
                        .font(MatchaTokens.Typography.caption)
                }
                .foregroundStyle(MatchaTokens.Colors.danger)
                .padding(.horizontal, MatchaTokens.Spacing.xSmall)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }
}

// MARK: - View apply helper (avoids repetitive if-let chains)

private extension View {
    @ViewBuilder
    func apply<Content: View>(@ViewBuilder transform: (Self) -> Content) -> some View {
        transform(self)
    }
}

// MARK: - Preview

#Preview("MatchaTextField States") {
    VStack(spacing: MatchaTokens.Spacing.medium) {
        MatchaTextField(
            icon: "envelope",
            placeholder: "Email address",
            text: .constant(""),
            fieldState: .normal,
            keyboardType: .emailAddress,
            autocapitalization: .never
        )

        MatchaTextField(
            icon: "person",
            placeholder: "Display name",
            text: .constant("Ari Tanaka"),
            fieldState: .success
        )

        MatchaTextField(
            icon: "at",
            placeholder: "Instagram handle",
            text: .constant("@bad_handle!"),
            fieldState: .error("Only letters, numbers and underscores")
        )

        MatchaSecureField(
            placeholder: "Password",
            text: .constant(""),
            fieldState: .error("Minimum 8 characters"),
            contentType: .newPassword
        )
    }
    .padding(MatchaTokens.Spacing.large)
    .background(MatchaTokens.Colors.background)
    .preferredColorScheme(.dark)
}
