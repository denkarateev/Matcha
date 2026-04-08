import Network
import Observation

@MainActor
@Observable
final class NetworkMonitor {
    static let shared = NetworkMonitor()

    var isConnected: Bool = true

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    private var hasReceivedFirstUpdate = false

    private init() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.hasReceivedFirstUpdate = true
                // satisfied = connected, unsatisfied = no connection
                // requiresConnection = e.g. VPN not yet established (treat as connected)
                self.isConnected = path.status != .unsatisfied
            }
        }
        monitor.start(queue: queue)
    }
}
