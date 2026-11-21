import Foundation

struct AuthEndpoints {
    private init() {}
}

enum FCMDeviceIdentity {
    static var current: String? {
        guard let token = UserDefaults.standard.string(forKey: "pushNotificationToken") else {
            return nil
        }
        let value = token.trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }
}

extension AuthEndpoints {
    static
    func login(phone: String, countryCode: String, password: String, deviceID: String) -> Endpoint<APIEnvelope<APIUser>> {
        return Endpoint(
            method: .post,
            path: "login",
            body: ["phone": phone, "country_code": countryCode, "password": password,
                   "device_id": deviceID, "device_type": "ios"]
        )
    }

    static
    func signup(model: UserRegisterModel) -> Endpoint<APIEnvelope<SignupData>> {
        var body = APIParameters()
        if let name = model.name { body["name"] = name }
        if let phone = model.phone { body["phone"] = phone }
        if let countryCode = model.countryCode {
            body["country_code"] = countryCode.replacingOccurrences(of: "+", with: "")
        }
        if let email = model.email, !email.isEmpty { body["email"] = email }
        if let password = model.password { body["password"] = password }
        if let terms = model.terms { body["terms"] = terms }
        return Endpoint(
            method: .post,
            path: "sign-up",
            body: body
        )
    }

    static
    func activate(phone: String, countryCode: String, code: String, deviceID: String) -> Endpoint<APIEnvelope<APIUser>> {
        return Endpoint(
            method: .patch,
            path: "activate",
            body: ["phone": phone, "country_code": countryCode, "code": code,
                   "device_id": deviceID, "device_type": "ios"]
        )
    }

    static
    func sendRecoveryCode(phone: String, countryCode: String) -> Endpoint<APIEnvelope<APIEmpty>> {
        return Endpoint(
            method: .post,
            path: "forget-password-send-code",
            body: ["phone": phone, "country_code": countryCode]
        )
    }

    static
    func resendCode(phone: String, countryCode: String) -> Endpoint<APIEnvelope<APIEmpty>> {
        return Endpoint(
            path: "resend-code",
            queries: ["phone": phone, "country_code": countryCode]
        )
    }

    static
    func resetPassword(phone: String, countryCode: String, password: String) -> Endpoint<APIEnvelope<APIEmpty>> {
        return Endpoint(
            method: .post,
            path: "reset-password",
            body: ["phone": phone, "country_code": countryCode, "password": password]
        )
    }

    static
    func profile(token: String) -> Endpoint<APIEnvelope<APIUser>> {
        return Endpoint(
            path: "profile",
            headerType: .authorized(token: token)
        )
    }
    static
    func options(cities: Bool, token: String) -> Endpoint<APIEnvelope<[AuthOption]>> {
        return Endpoint(
            path: cities ? "cities" : "interests",
            headerType: .authorized(token: token)
        )
    }
    static
    func selectCity(id: Int, token: String) -> Endpoint<APIEnvelope<APIEmpty>> {
        return Endpoint(
            method: .post,
            path: "select-city",
            body: ["city_id": id],
            headerType: .authorized(token: token)
        )
    }
    static
    func selectInterests(ids: [Int], token: String) -> Endpoint<APIEnvelope<APIEmpty>> {
        return Endpoint(
            method: .post,
            path: "select-interest",
            body: ["interest_ids": ids],
            headerType: .authorized(token: token)
        )
    }
    static
    func logout(token: String) -> Endpoint<APIEnvelope<APIEmpty>> {
        return Endpoint(
            method: .delete,
            path: "sign-out",
            headerType: .authorized(token: token)
        )
    }
}
