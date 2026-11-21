//
//  AppDelegate.swift
//  CTF
//
//  Created by Mohamed Hadwa on 25/11/2025.
//

import UIKit
import FirebaseCore
import FirebaseMessaging
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate {
    // A tap can arrive before RootCoordinatorView subscribes during cold launch.
    static var pendingTappedPayload: PushPayload?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {

        print("📲 [FCM] AppDelegate launch; external SDKs enabled: \(AppServices.externalSDKsEnabled)")
        guard AppServices.externalSDKsEnabled else {
            print("⚠️ [FCM] Push setup skipped because external SDKs are disabled")
            return true
        }

        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
        print("✅ [FCM] Firebase configured")

        UNUserNotificationCenter.current().delegate = self
        Messaging.messaging().delegate = self
        print("✅ [FCM] Messaging and notification delegates registered")
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            let status = settings.authorizationStatus
            print("🔔 [FCM] Notification authorization status: \(status.rawValue)")
            if status == .authorized || status == .provisional {
                self.registerForRemoteNotifications(application)
            } else if status == .notDetermined {
                self.requestNotificationPermission(application)
            } else {
                print("⚠️ [APNs] Notification permission is denied or restricted")
            }
        }

        return true
    }

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        guard AppServices.externalSDKsEnabled else { return }
        print("✅ [APNs] Remote notification registration succeeded (\(deviceToken.count) bytes)")
        Messaging.messaging().apnsToken = deviceToken
        print("✅ [FCM] APNs token assigned; requesting FCM token")
        fetchAndSavePushNotificationToken()
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print("⚠️ [APNs] Failed to register for remote notifications: \(error.localizedDescription)")
    }

    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable : Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        handleIncomingPush(userInfo: userInfo, source: .backgroundOrSilent)
        completionHandler(.newData)
    }

    private enum PushSource {
        case foreground
        case backgroundOrSilent
        case tap
    }

    private func handleIncomingPush(userInfo: [AnyHashable: Any], source: PushSource) {
        guard let payload = PushPayload(userInfo: userInfo) else { return }

        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .notificationsShouldRefresh, object: nil)
            switch source {
            case .foreground, .backgroundOrSilent:
                NotificationCenter.default.post(name: .pushDidReceiveForeground, object: payload)
            case .tap:
                Self.pendingTappedPayload = payload
                NotificationCenter.default.post(name: .pushDidTap, object: payload)
            }
        }
    }
}

extension AppDelegate: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("🔥 [FCM] New registration token: \(fcmToken ?? "nil")")
        savePushNotificationToken(fcmToken)
    }
}

private extension AppDelegate {
    func requestNotificationPermission(_ application: UIApplication) {
        print("🔔 [FCM] Requesting notification permission at launch")
        Task { @MainActor in
            do {
                let granted = try await UNUserNotificationCenter.current().requestAuthorization(
                    options: [.alert, .badge, .sound]
                )
                print("🔔 [FCM] Notification permission granted: \(granted)")
                guard granted else { return }
                registerForRemoteNotifications(application)
            } catch {
                print("⚠️ [FCM] Notification permission request failed: \(error.localizedDescription)")
            }
        }
    }

    func registerForRemoteNotifications(_ application: UIApplication) {
        DispatchQueue.main.async {
            print("📡 [APNs] Registering for remote notifications")
            application.registerForRemoteNotifications()
        }
    }

    func fetchAndSavePushNotificationToken() {
        Messaging.messaging().token { [weak self] token, error in
            if let error {
                print("⚠️ [FCM] Failed to read registration token: \(error.localizedDescription)")
                return
            }
            print("✅ [FCM] Registration token received (\(token?.count ?? 0) characters)")
            self?.savePushNotificationToken(token)
        }
    }

    func savePushNotificationToken(_ token: String?) {
        guard let token, !token.isEmpty else { return }
        UserDefaults.pushNotificationToken = token
        print("🔥 [FCM] Registration token saved")
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        let userInfo = notification.request.content.userInfo
        handleIncomingPush(userInfo: userInfo, source: .foreground)
        completionHandler([.banner, .sound, .badge])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        handleIncomingPush(userInfo: userInfo, source: .tap)
        completionHandler()
    }
}
