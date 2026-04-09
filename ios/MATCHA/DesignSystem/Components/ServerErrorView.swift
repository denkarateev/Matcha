import SwiftUI

struct ServerErrorView: View {
    var message: String = "Something went wrong"
    var onRetry: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.icloud.fill")
                .font(.system(size: 44))
                .foregroundStyle(MatchaTokens.Colors.textMuted)

            Text(message)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.white)

            Text("Pull to refresh")
                .font(.system(size: 14))
                .foregroundStyle(.white.opacity(0.4))

            if let onRetry {
                Button(action: onRetry) {
                    Text("Try Again")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(MatchaTokens.Colors.accent, in: Capsule())
                }
                .padding(.top, 8)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(MatchaTokens.Colors.background)
    }
}
