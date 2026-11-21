import SwiftUI
import UIKit

/// A scene-level window also covers sheets and full-screen flows without dismissing their drafts.
struct MaintenancePresentation: UIViewRepresentable {
    @ObservedObject var viewModel: MaintenanceViewModel

    func makeCoordinator() -> Coordinator { Coordinator(viewModel: viewModel) }

    func makeUIView(context: Context) -> WindowAnchor {
        let view = WindowAnchor()
        view.isUserInteractionEnabled = false
        view.sceneChanged = { [weak coordinator = context.coordinator] scene in
            coordinator?.update(scene: scene)
        }
        return view
    }

    func updateUIView(_ uiView: WindowAnchor, context: Context) {
        context.coordinator.update(scene: uiView.window?.windowScene)
    }

    static func dismantleUIView(_ uiView: WindowAnchor, coordinator: Coordinator) {
        uiView.sceneChanged = nil
        coordinator.dismiss()
    }

    final class WindowAnchor: UIView {
        var sceneChanged: ((UIWindowScene?) -> Void)?

        override func didMoveToWindow() {
            super.didMoveToWindow()
            sceneChanged?(window?.windowScene)
        }
    }

    @MainActor
    final class Coordinator {
        private let viewModel: MaintenanceViewModel
        private var maintenanceWindow: UIWindow?
        private weak var previousKeyWindow: UIWindow?

        init(viewModel: MaintenanceViewModel) { self.viewModel = viewModel }

        func update(scene: UIWindowScene?) {
            guard viewModel.isPresented else {
                dismiss()
                return
            }
            guard let scene else { return }
            guard maintenanceWindow == nil else { return }

            previousKeyWindow = scene.windows.first(where: \.isKeyWindow)
            previousKeyWindow?.endEditing(true)
            let window = UIWindow(windowScene: scene)
            window.windowLevel = .alert + 1
            let host = UIHostingController(rootView: MaintenanceView(viewModel: viewModel).preferredColorScheme(.light))
            host.view.accessibilityViewIsModal = true
            window.rootViewController = host
            maintenanceWindow = window
            window.makeKeyAndVisible()
            UIAccessibility.post(notification: .screenChanged, argument: nil)
        }

        func dismiss() {
            guard let window = maintenanceWindow else { return }
            let wasKeyWindow = window.isKeyWindow
            window.isHidden = true
            window.rootViewController = nil
            maintenanceWindow = nil
            if wasKeyWindow { previousKeyWindow?.makeKey() }
            previousKeyWindow = nil
            UIAccessibility.post(notification: .screenChanged, argument: nil)
        }
    }
}
