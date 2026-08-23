import Foundation
import SwiftData
import AppKit
import Combine

@MainActor
final class ClipboardViewModel: ObservableObject, ClipboardMonitorDelegate {
    @Published var items: [ClipboardItem] = []
    @Published var searchQuery: String = ""
    @Published var settings: AppSettings

    private let repository: ClipboardRepositoryProtocol
    private let monitor: ClipboardMonitor
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
        self.repository = ClipboardRepository(context: context)
        self.monitor = ClipboardMonitor()

        if let loaded = try? context.fetch(FetchDescriptor<AppSettings>()).first {
            self.settings = loaded
        } else {
            let defaults = AppSettings()
            context.insert(defaults)
            try? context.save()
            self.settings = defaults
        }

        self.monitor.delegate = self
        self.items = repository.fetchAll()
        applyAutoDeleteIfNeeded()
        monitor.start()
    }

    deinit {
        monitor.stop()
    }

    func didCaptureClipboardItem(_ item: ClipboardItem) {
        repository.addOrUpdate(item)
        enforceMaxHistorySize()
        applyAutoDeleteIfNeeded()
        items = repository.fetchAll()
    }

    var pinnedItems: [ClipboardItem] { filteredItems.filter { $0.pinned } }
    var recentItems: [ClipboardItem] { filteredItems.filter { !$0.pinned } }

    private var filteredItems: [ClipboardItem] {
        guard !searchQuery.isEmpty else { return items }
        let q = searchQuery.lowercased()
        return items.filter { item in
            if let text = item.textContent?.lowercased(), text.contains(q) { return true }
            return item.isImage
        }
    }

    func togglePin(_ item: ClipboardItem) {
        item.pinned.toggle()
        try? context.save()
        items = repository.fetchAll()
    }

    func deleteItem(_ item: ClipboardItem) {
        repository.delete(item)
        items = repository.fetchAll()
    }

    func clearAll() {
        repository.clearAll()
        items = []
    }

    func copyToPasteboard(_ item: ClipboardItem) {
        let pb = NSPasteboard.general
        pb.clearContents()
        if item.isText, let text = item.textContent {
            pb.setString(text, forType: .string)
        } else if item.isImage, let data = item.imageData, let nsImage = NSImage(data: data) {
            pb.writeObjects([nsImage])
        } else if item.isFile, let path = item.fileURL {
            let url = URL(fileURLWithPath: path)
            pb.writeObjects([url as NSURL])
        }
    }

    func updateAutoDelete(option: AutoDeleteOption) {
        settings.autoDeleteOption = option
        try? context.save()
        applyAutoDeleteIfNeeded()
        items = repository.fetchAll()
    }

    func updateMaxHistory(_ max: Int) {
        settings.maxHistoryItems = max
        try? context.save()
        enforceMaxHistorySize()
        items = repository.fetchAll()
    }

    private func applyAutoDeleteIfNeeded() {
        let days = settings.autoDeleteOption.rawValue
        if days > 0 { repository.deleteOlderThan(days: days) }
    }

    private func enforceMaxHistorySize() {
        let all = repository.fetchAll()
        let max = settings.maxHistoryItems
        guard all.count > max, max > 0 else { return }
        let toDelete = all.dropFirst(max)
        for item in toDelete { context.delete(item) }
        try? context.save()
    }
}
