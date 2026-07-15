import Foundation
import SwiftData

enum AutoDeleteOption: Int, Codable, CaseIterable, Identifiable {
    case never = 0
    case oneDay = 1
    case sevenDays = 7
    case thirtyDays = 30

    var id: Int { rawValue }

    var label: String {
        switch self {
        case .never: return "Never"
        case .oneDay: return "1 day"
        case .sevenDays: return "7 days"
        case .thirtyDays: return "30 days"
        }
    }
}

@Model
final class AppSettings {
    @Attribute(.unique) var id: UUID
    var autoDeleteOptionRaw: Int
    var maxHistoryItems: Int

    init(
        id: UUID = UUID(),
        autoDeleteOption: AutoDeleteOption = .sevenDays,
        maxHistoryItems: Int = 500
    ) {
        self.id = id
        self.autoDeleteOptionRaw = autoDeleteOption.rawValue
        self.maxHistoryItems = maxHistoryItems
    }

    var autoDeleteOption: AutoDeleteOption {
        get { AutoDeleteOption(rawValue: autoDeleteOptionRaw) ?? .never }
        set { autoDeleteOptionRaw = newValue.rawValue }
    }
}
