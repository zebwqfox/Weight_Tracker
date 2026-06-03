import Foundation

enum DeepSeekModel: String, CaseIterable {
    case v4Pro   = "deepseek-v4-pro"
    case v4Flash = "deepseek-v4-flash"

    var displayName: String {
        switch self {
        case .v4Pro:   return "V4-Pro（精准）"
        case .v4Flash: return "V4-Flash（快速）"
        }
    }

    static var stored: DeepSeekModel {
        let raw = UserDefaults.standard.string(forKey: "deepseek_model") ?? v4Pro.rawValue
        return DeepSeekModel(rawValue: raw) ?? .v4Pro
    }
}
