import SwiftUI

@MainActor
final class AppRefreshController: ObservableObject {
    private var task: Task<Void, Never>?
    private var requestID = UUID()

    func refresh(_ action: @escaping @MainActor () async -> Void) async {
        task?.cancel()
        let id = UUID()
        requestID = id
        let task = Task { await action() }
        self.task = task
        await task.value
        if requestID == id { self.task = nil }
    }

    func cancel() {
        task?.cancel()
        task = nil
    }
}

private struct AppRefreshable: ViewModifier {
    let action: @MainActor () async -> Void
    @StateObject private var controller = AppRefreshController()

    func body(content: Content) -> some View {
        content
            .refreshable { await controller.refresh(action) }
            .onDisappear { controller.cancel() }
    }
}

extension View {
    func appRefreshable(action: @escaping @MainActor () async -> Void) -> some View {
        modifier(AppRefreshable(action: action))
    }
}
