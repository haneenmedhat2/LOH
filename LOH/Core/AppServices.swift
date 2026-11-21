import Foundation

/// Gates external services and SDK integrations.
enum AppServices {
    static let isEnabled = false // Legacy optional services remain disabled.
    static let externalSDKsEnabled = true

    static func remoteURL(_ value: String?) -> URL? {
        guard isEnabled, let value else { return nil }
        return URL(string: value)
    }
}

/// Temporary, in-memory identity for reviewing the UI. Never creates a real session.
enum AuthPreviewSession {
    static var user: User?
}
