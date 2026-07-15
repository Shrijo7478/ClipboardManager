import Foundation
import SwiftData

protocol ClipboardRepositoryProtocol {
    func addOrUpdate(_ item: ClipboardItem)
    func fetchAll() -> [ClipboardItem]
    func delete(_ item: ClipboardItem)
    func deleteOlderThan(days: Int)
    func clearAll()
}

final class ClipboardRepository: ClipboardRepositoryProtocol {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func addOrUpdate(_ item: ClipboardItem) {
        if let last = fetchAll().first {
            if item.isText, last.isText, last.textContent == item.textContent { return }
            if item.isImage, last.isImage, last.imageData == item.imageData { return }
        }
        context.insert(item)
        try? context.save()
    }

    func fetchAll() -> [ClipboardItem] {
        let descriptor = FetchDescriptor<ClipboardItem>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    func delete(_ item: ClipboardItem) {
        context.delete(item)
        try? context.save()
    }

    func deleteOlderThan(days: Int) {
        guard days > 0 else { return }
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        for item in fetchAll() where item.createdAt < cutoff {
            context.delete(item)
        }
        try? context.save()
    }

    func clearAll() {
        for item in fetchAll() { context.delete(item) }
        try? context.save()
    }
}
