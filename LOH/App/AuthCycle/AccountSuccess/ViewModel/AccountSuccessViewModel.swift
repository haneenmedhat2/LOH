import SwiftUI
import UserNotifications

@MainActor final class AccountSuccessViewModel: ObservableObject {
    @Published private(set) var notificationsEnabled = false
    @Published private(set) var requestingPermission = false
    @Published var permissionError: String?

    func refreshPermission() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        notificationsEnabled = settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional
    }

    func enableNotifications() async {
        guard !requestingPermission else { return }
        requestingPermission = true
        defer { requestingPermission = false }
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        print("🔔 [FCM] Notification permission before request: \(settings.authorizationStatus.rawValue)")
        guard settings.authorizationStatus == .notDetermined else {
            await refreshPermission()
            print("ℹ️ [FCM] Notification permission was already decided")
            return
        }
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
            print("🔔 [FCM] Notification permission granted: \(granted)")
            if granted && AppServices.externalSDKsEnabled {
                print("📡 [APNs] Registering after notification permission request")
                UIApplication.shared.registerForRemoteNotifications()
            }
            await refreshPermission()
        } catch {
            print("⚠️ [FCM] Notification permission request failed: \(error.localizedDescription)")
            permissionError = error.localizedDescription
        }
    }
}
