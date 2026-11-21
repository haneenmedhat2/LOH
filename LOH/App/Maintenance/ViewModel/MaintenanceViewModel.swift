import Combine
import Foundation

@MainActor
final class MaintenanceViewModel: ObservableObject {
    static let shared = MaintenanceViewModel()

    @Published private(set) var isPresented = false
    @Published private(set) var isRetrying = false
    @Published private(set) var errorMessage: String?

    private var checkAvailability: (() async throws -> Bool)?
    private var waitingRequests: [UUID: CheckedContinuation<Void, Error>] = [:]
    private var revision = 0

    /// Keep failed reads pending so their screens can finish loading after recovery.
    func waitForRecovery(checkAvailability: @escaping () async throws -> Bool) async throws {
        let id = UUID()
        try await withTaskCancellationHandler {
            try Task.checkCancellation()
            try await withCheckedThrowingContinuation { continuation in
                waitingRequests[id] = continuation
                if self.checkAvailability == nil { self.checkAvailability = checkAvailability }
                revision += 1
                isPresented = true
            }
        } onCancel: {
            Task { @MainActor [weak self] in
                self?.waitingRequests.removeValue(forKey: id)?.resume(throwing: CancellationError())
            }
        }
        try Task.checkCancellation()
    }

    func retry() async {
        guard !isRetrying, let checkAvailability else { return }
        isRetrying = true
        errorMessage = nil
        let retryRevision = revision
        defer { isRetrying = false }

        do {
            let available = try await checkAvailability()
            try Task.checkCancellation()
            // A newer maintenance response takes priority over an older probe.
            guard available, revision == retryRevision else {
                errorMessage = "maintenance.stillUnavailable".localized
                return
            }
            self.checkAvailability = nil
            isPresented = false
            let requests = waitingRequests.values
            waitingRequests.removeAll()
            for request in requests { request.resume() }
        } catch is CancellationError {
            // A cancelled check does not mean that maintenance has ended.
        } catch {
            errorMessage = "maintenance.retryFailed".localized
        }
    }
}
