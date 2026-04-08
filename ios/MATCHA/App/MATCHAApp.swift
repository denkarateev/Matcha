import SwiftUI

@main
struct MATCHAApp: App {
    @State private var appState = AppState()

    private let environment: AppEnvironment = {
        #if DEBUG
        let processInfo = ProcessInfo.processInfo
        if processInfo.arguments.contains("-matcha-mock")
            || processInfo.arguments.contains("-UITest")
            || processInfo.environment["MATCHA_USE_MOCK"] == "1" {
            return .mock
        }
        #endif
        return .live
    }()

    var body: some Scene {
        WindowGroup {
            MatchaAppView(appState: appState, environment: environment)
                .task {
                    await appState.bootstrapIfNeeded(useLiveServices: environment.isLive, repository: environment.repository)
                }
        }
    }
}
