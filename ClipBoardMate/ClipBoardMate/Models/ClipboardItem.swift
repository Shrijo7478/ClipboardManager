import Foundation
import SwiftData
import SwiftUI

enum ClipboardItemType: String, Codable {
    case text
    case image
}

@Model
final class ClipboardItem {
    @Attribute(.unique) var id: UUID
    var type: ClipboardItemType
    var textContent: String?
    var imageData: Data?
    var createdAt: Date
    var pinned: Bool

    init(
        id: UUID = UUID(),
        type: ClipboardItemType,
        textContent: String? = nil,
        imageData: Data? = nil,
        createdAt: Date = Date(),
        pinned: Bool = false
    ) {
        self.id = id
        self.type = type
        self.textContent = textContent
        self.imageData = imageData
        self.createdAt = createdAt
        self.pinned = pinned
    }

    var isText: Bool { type == .text }
    var isImage: Bool { type == .image }

    var imageThumbnail: Image? {
        guard let data = imageData, let nsImage = NSImage(data: data) else { return nil }
        return Image(nsImage: nsImage)
    }
}
