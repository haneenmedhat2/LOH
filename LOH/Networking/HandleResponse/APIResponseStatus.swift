import Foundation

struct APIResponseStatus: Decodable {
    let key: String

    var isMaintenance: Bool { key == "maintenance_mode" }

    static func isMaintenance(_ data: Data) -> Bool {
        (try? JSONDecoder().decode(Self.self, from: data))?.isMaintenance == true
    }
}
