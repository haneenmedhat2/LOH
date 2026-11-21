import Combine
import Foundation

struct AppStoreRelease: Codable, Equatable {
    let version: String
    let url: URL
}

@MainActor
final class AppUpdateViewModel: ObservableObject {
    static let shared = AppUpdateViewModel()

    @Published private(set) var requiredRelease: AppStoreRelease?
    private var isChecking = false
    private let cacheKey = "loh.requiredAppStoreRelease"

    init() {
        #if DEBUG
        // Required updates are a production gate. Never restore a cached gate
        // or query the App Store while running a Debug build.
        return
        #else
        if let data = UserDefaults.standard.data(forKey: cacheKey),
           let release = try? JSONDecoder().decode(AppStoreRelease.self, from: data),
           Self.isNewer(release.version, than: Self.installedVersion) {
            requiredRelease = release
        }
        #endif
    }

    func checkForUpdate() async {
        #if DEBUG
        return
        #else
        guard !isChecking, let bundleID = Bundle.main.bundleIdentifier else { return }
        isChecking = true
        defer { isChecking = false }

        var components = URLComponents(string: "https://itunes.apple.com/lookup")!
        components.queryItems = [
            URLQueryItem(name: "bundleId", value: bundleID),
            URLQueryItem(name: "country", value: "sa"),
            URLQueryItem(name: "entity", value: "software")
        ]
        guard let url = components.url else { return }

        do {
            var request = URLRequest(url: url)
            request.cachePolicy = .reloadIgnoringLocalCacheData
            request.timeoutInterval = 10
            let (data, response) = try await URLSession.shared.data(for: request)
            guard (response as? HTTPURLResponse)?.statusCode == 200 else { return }
            let lookup = try JSONDecoder().decode(AppStoreLookup.self, from: data)
            guard let listing = lookup.results.first(where: { $0.bundleId == bundleID }),
                  let storeURL = URL(string: listing.trackViewUrl),
                  storeURL.scheme == "https", storeURL.host == "apps.apple.com" else { return }

            if Self.isNewer(listing.version, than: Self.installedVersion) {
                let release = AppStoreRelease(version: listing.version, url: storeURL)
                requiredRelease = release
                UserDefaults.standard.set(try? JSONEncoder().encode(release), forKey: cacheKey)
            } else {
                requiredRelease = nil
                UserDefaults.standard.removeObject(forKey: cacheKey)
            }
        } catch {
            // Keep a previously confirmed update gate during a temporary network failure.
        }
        #endif
    }

    static var installedVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0"
    }

    static func isNewer(_ candidate: String, than installed: String) -> Bool {
        let candidateParts = candidate.split(separator: ".").compactMap { Int($0) }
        let installedParts = installed.split(separator: ".").compactMap { Int($0) }
        guard !candidateParts.isEmpty, !installedParts.isEmpty,
              candidateParts.count == candidate.split(separator: ".").count,
              installedParts.count == installed.split(separator: ".").count else { return false }
        for index in 0..<max(candidateParts.count, installedParts.count) {
            let new = index < candidateParts.count ? candidateParts[index] : 0
            let current = index < installedParts.count ? installedParts[index] : 0
            if new != current { return new > current }
        }
        return false
    }
}

private struct AppStoreLookup: Decodable {
    let results: [AppStoreListing]
}

private struct AppStoreListing: Decodable {
    let bundleId: String
    let version: String
    let trackViewUrl: String
}
