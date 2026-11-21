import UIKit
import Combine

@MainActor
final class AccountProfileViewModel: ObservableObject {
    @Published var profile = AccountProfile()
    @Published var avatar: UIImage?
    @Published private(set) var profileImageRevision = UUID()
    @Published private(set) var cities: [AuthOption] = []
    @Published private(set) var profileLoaded = false
    let requests: AccountRequestController

    init(requests: AccountRequestController) { self.requests = requests }

    func loadSession() {
        guard !profileLoaded else { return }
        if let user = UserDefaults.apiUser {
            apply(user)
            return
        }
        let user = UserDefaults.user
        profile.name = user?.name ?? ""
        profile.email = user?.email ?? ""
        profile.phone = user?.phone ?? ""
        profile.imageURL = user?.image
    }
    private func apply(_ user: APIUser) {
        profile.name = user.name ?? ""
        profile.email = user.email ?? ""
        profile.phone = user.phone ?? ""
        profile.gender = user.gender ?? ""
        profile.cityID = user.cities.first?.id
        profile.city = user.cities.first?.name ?? ""
        profile.imageURL = user.image
        profileImageRevision = UUID()
        profile.hasBirthday = false
        if let date = AccountBirthDate.parse(user.birthDate) {
            profile.birthday = date
            profile.hasBirthday = true
        }
        profileLoaded = true
    }
    static var dateFormatter: DateFormatter {
        AccountBirthDate.apiFormatter
    }
    @discardableResult
    func loadProfile() async -> Bool {
        guard !requests.busy else { return false }
        profileLoaded = false
        return await requests.run { token, generation in
            let user: APIUser = try await requests.client.data(
                from: AuthEndpoints.profile(token: token), language: requests.language)
            try requests.check(token, generation)
            apply(user)
            avatar = nil
            UserDefaults.save(user)
        }
    }
    func loadProfileCities() async {
        await requests.run { token, generation in
            let options: [AuthOption] = try await requests.client.data(
                from: AuthEndpoints.options(cities: true, token: token), language: requests.language)
            try requests.check(token, generation)
            cities = options
        }
    }
    func saveProfile(_ draft: AccountProfile, image: UIImage?) async -> Bool {
        guard profileLoaded else { return false }
        return await requests.run { token, generation in
            var fields = [("name", draft.name.trimmingCharacters(in: .whitespacesAndNewlines)), ("mobile_type", "ios")]
            if draft.hasBirthday { fields.append(("birth_date", Self.dateFormatter.string(from: draft.birthday))) }
            if !draft.gender.isEmpty { fields.append(("gender", draft.gender)) }
            if !draft.email.isEmpty {
                fields.append(("email", draft.email.trimmingCharacters(in: .whitespacesAndNewlines)))
            }
            var files: [UploadData] = []
            if let image {
                guard let data = image.jpegData(compressionQuality: 0.8) else { throw APIError.invalidResponse }
                files = [UploadData(key: "image", data: data, mimeType: .jpeg, fileName: "profile")]
            }
            let previousCityID = profile.cityID
            var user: APIUser = try await requests.client.data(
                from: AccountEndpoints.updateProfile(fields: fields, files: files, token: token),
                language: requests.language)
            try requests.check(token, generation)
            apply(user)
            UserDefaults.save(user)
            if let image { avatar = image }
            if let cityID = draft.cityID, cityID != previousCityID {
                try await requests.client.perform(
                    AuthEndpoints.selectCity(id: cityID, token: token), language: requests.language)
                try requests.check(token, generation)
                if let city = cities.first(where: { $0.id == cityID }) {
                    user.cities = [city]
                    apply(user)
                    UserDefaults.save(user)
                }
            }
        }
    }

    func resetSession() {
        profile = AccountProfile()
        avatar = nil
        profileImageRevision = UUID()
        cities = []
        profileLoaded = false
    }
}
