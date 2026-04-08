import Observation
import SwiftUI

struct MatchaAppView: View {
    @Bindable var appState: AppState
    let environment: AppEnvironment

    var body: some View {
        Group {
            if appState.isBootstrapping {
                // Splash / loading screen while auth bootstrap is in progress
                VStack(spacing: 16) {
                    Spacer()
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(MatchaTokens.Colors.accent)
                    Text("MATCHA")
                        .font(.title.bold())
                        .foregroundStyle(.white)
                    ProgressView()
                        .tint(MatchaTokens.Colors.accent)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(MatchaTokens.Colors.background.ignoresSafeArea())
            } else if appState.onboardingComplete {
                MatchaTabShellView(appState: appState, environment: environment)
            } else {
                OnboardingFlowView(appState: appState)
            }
        }
        .preferredColorScheme(.dark)
        .tint(MatchaTokens.Colors.accent)
        .background(MatchaTokens.Colors.background.ignoresSafeArea())
    }
}
