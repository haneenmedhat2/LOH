//
//  ResponseHandler.swift
//  NewSwiftUIBase
//
//  Created by Mohamed Hadwa on 22/12/2023.
//

import Foundation

struct APIEnvelope<Value: Decodable>: Decodable {
    let key: String
    let msg: String?
    let data: Value?
}

struct APIEmpty: Decodable { init(from decoder: Decoder) throws {} }

enum APIError: LocalizedError {
    case server(String), invalidResponse, unauthorized, missingSession, secureStorage
    case pushNotificationTokenUnavailable
    case interruptedByMaintenance
    var errorDescription: String? {
        switch self {
        case .server(let message): return message
        case .invalidResponse: return NSLocalizedString("api.invalidResponse", comment: "")
        case .unauthorized: return NSLocalizedString("api.sessionExpired", comment: "")
        case .missingSession: return NSLocalizedString("api.missingSession", comment: "")
        case .secureStorage: return NSLocalizedString("api.secureStorage", comment: "")
        case .pushNotificationTokenUnavailable:
            return NSLocalizedString("api.pushTokenUnavailable", comment: "")
        case .interruptedByMaintenance: return "maintenance.requestNotCompleted".localized
        }
    }
}

extension Notification.Name {
    static let lohSessionExpired = Notification.Name("lohSessionExpired")
}

protocol ResponseHandler {
    func get<T: Decodable>(_ endpoint: Endpoint<T>, progress: ((_ progress: Int)-> Void)?) async throws -> T
}

struct DefaultResponseHandler: ResponseHandler {
    
    private let networkExecuter: NetworkExecuter
    private let maintenance: MaintenanceViewModel?
    
    init(networkExecuter: NetworkExecuter = DefaultNetworkExecuter(), maintenance: MaintenanceViewModel? = nil) {
        self.networkExecuter = networkExecuter
        self.maintenance = maintenance
    }
    
    func get<T: Decodable>(_ endpoint: Endpoint<T>, progress: ((_ progress: Int)-> Void)? = nil) async throws -> T {
        var data = try await self.networkExecuter.execute(endpoint, progress: progress)
        APILogger.printApiResponse(data, for: endpoint.server + endpoint.path)
        while APIResponseStatus.isMaintenance(data) {
            try Task.checkCancellation()
            let maintenance = await MainActor.run { self.maintenance ?? MaintenanceViewModel.shared }
            // Never replay a write/upload to check whether maintenance has ended.
            let probe = maintenanceProbe(for: endpoint)
            try await maintenance.waitForRecovery { [networkExecuter] in
                let response = try await networkExecuter.execute(probe, progress: nil)
                let status = try JSONDecoder().decode(APIResponseStatus.self, from: response)
                guard !status.key.isEmpty else { throw APIError.invalidResponse }
                return !status.isMaintenance
            }
            try Task.checkCancellation()
            guard endpoint.method == .get else { throw APIError.interruptedByMaintenance }
            data = try await networkExecuter.execute(endpoint, progress: progress)
            APILogger.printApiResponse(data, for: endpoint.server + endpoint.path)
        }
        return try endpoint.decoder.decode(data: data)
    }

    private func maintenanceProbe<T>(for endpoint: Endpoint<T>) -> Endpoint<APIEmpty> {
        Endpoint(
            server: endpoint.server,
            path: endpoint.method == .get ? endpoint.path : "search-offers",
            queries: endpoint.method == .get ? endpoint.queries : nil,
            headerType: endpoint.headerType
        )
    }
    
}

extension DefaultResponseHandler {
    func send<Value: Decodable>(
        _ endpoint: Endpoint<APIEnvelope<Value>>,
        language: String
    ) async throws -> APIEnvelope<Value> {
        let response = try await get(endpoint)
        guard ["success", "needActive", "selectCity", "selectInterests"].contains(response.key) else {
            if ["unauthenticated", "blocked"].contains(response.key),
               let token = Self.token(from: endpoint.headerType) {
                NotificationCenter.default.post(name: .lohSessionExpired, object: token)
            }
            throw response.msg.map(APIError.server) ?? APIError.invalidResponse
        }
        return response
    }

    func data<Value: Decodable>(
        from endpoint: Endpoint<APIEnvelope<Value>>,
        language: String
    ) async throws -> Value {
        let response = try await send(endpoint, language: language)
        guard response.key == "success", let data = response.data else { throw APIError.invalidResponse }
        return data
    }

    func perform(
        _ endpoint: Endpoint<APIEnvelope<APIEmpty>>,
        language: String
    ) async throws {
        let response = try await send(endpoint, language: language)
        guard response.key == "success" else { throw APIError.invalidResponse }
    }

    private static func token(from headerType: RequestHeaderType) -> String? {
        switch headerType {
        case .authorized(let token): return token
        case .ifAuthourized(let token): return token
        case .unauthorized: return nil
        }
    }
}
