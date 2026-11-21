import SwiftUI

private struct ScreenLoggingModifier: ViewModifier {
    let name: String
    func body(content: Content) -> some View {
        content
            .onAppear {
                log()
            }
            .onChange(of: name) { _ in
                log()
            }
    }
    private func log() {
        #if DEBUG
            print("[Screen] \(name)")
        #endif
    }
}

extension View {
    /// Log a static screen name only; never include route arguments or user data.
    func logScreen(_ name: String = String(describing: Self.self)) -> some View {
        modifier(ScreenLoggingModifier(name: name))
    }
}
