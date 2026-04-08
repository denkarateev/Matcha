import SwiftUI

struct OfflineBanner: View {
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 13, weight: .semibold))
            Text("No connection. Some features may be limited")
                .font(.system(size: 13, weight: .medium))
            Spacer()
        }
        .foregroundStyle(.black)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(MatchaTokens.Colors.warning)
    }
}
