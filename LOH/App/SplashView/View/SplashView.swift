import SwiftUI

struct SplashView: View {
    @EnvironmentObject var appCoordinator: AppCoordinator

    var body: some View {
        SplashContentView()
            .alert(
                "Error".localized,
                isPresented: Binding(
                    get: {
                        appCoordinator.restorationError != nil
                    }, set: { _ in })
            ) {
                Button("api.retry".localized) {
                    appCoordinator.decideInitialRoot()
                }
                Button("api.backToLogin".localized) {
                    appCoordinator.forgetSession()
                }
            } message: {
                Text(appCoordinator.restorationError ?? "")
            }
            .task {
                #if DEBUG
                if ProcessInfo.processInfo.arguments.contains("-lohPreviewLoader") { return }
                #endif
                do {
                    try await Task.sleep(nanoseconds: 1_800_000_000)
                    try Task.checkCancellation()
                    appCoordinator.decideInitialRoot()
                } catch {
                    // Leaving splash cancels its pending navigation.
                }
            }
    }
}
