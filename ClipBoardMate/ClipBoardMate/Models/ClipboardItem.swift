import Foundation
import SwiftData
import SwiftUI

enum ClipboardItemType: String, Codable {
    case text
    case image
    case file
}

@Model
final class ClipboardItem {
    @Attribute(.unique) var id: UUID
    var type: ClipboardItemType
    var textContent: String?
    var imageData: Data?
    var fileName: String?
    var fileURL: String?
    var createdAt: Date
    var pinned: Bool

    init(
        id: UUID = UUID(),
        type: ClipboardItemType,
        textContent: String? = nil,
        imageData: Data? = nil,
        fileName: String? = nil,
        fileURL: String? = nil,
        createdAt: Date = Date(),
        pinned: Bool = false
    ) {
        self.id = id
        self.type = type
        self.textContent = textContent
        self.imageData = imageData
        self.fileName = fileName
        self.fileURL = fileURL
        self.createdAt = createdAt
        self.pinned = pinned
    }

    var isText: Bool { type == .text }
    var isImage: Bool { type == .image }
    var isFile: Bool { type == .file }

    var imageThumbnail: Image? {
        guard let data = imageData, let nsImage = NSImage(data: data) else { return nil }
        return Image(nsImage: nsImage)
    }
}
