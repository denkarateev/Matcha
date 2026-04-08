@MainActor
struct AppEnvironment {
    let repository: any MatchaRepository
    let isLive: Bool

    static let mock = AppEnvironment(repository: MockMatchaRepository(), isLive: false)
    static let live = AppEnvironment(repository: APIMatchaRepository(), isLive: true)
}
