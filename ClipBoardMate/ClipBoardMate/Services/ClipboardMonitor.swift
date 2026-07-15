import Foundation
import AppKit

protocol ClipboardMonitorDelegate: AnyObject {
    func didCaptureClipboardItem(_ item: ClipboardItem)
}

// Polls NSPasteboard.general.changeCount instead of continuously reading
// pasteboard contents, which keeps CPU usage negligible for a menu bar utility.
final class ClipboardMonitor {
    private let pasteboard = NSPasteboard.general
    private var changeCount: Int
    private var timer: Timer?
    weak var delegate: ClipboardMonitorDelegate?

    init() {
        self.changeCount = pasteboard.changeCount
    }

    func start() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.checkForChanges()
        }
        if let timer { RunLoop.current.add(timer, forMode: .common) }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func checkForChanges() {
        let currentCount = pasteboard.changeCount
        guard currentCount != changeCount else { return }
        changeCount = currentCount
        readClipboard()
    }

    private func readClipboard() {
        if let string = pasteboard.string(forType: .string),
           !string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            delegate?.didCaptureClipboardItem(ClipboardItem(type: .text, textContent: string))
            return
        }

        if let nsImage = NSImage(pasteboard: pasteboard),
           let tiff = nsImage.tiffRepresentation {
            delegate?.didCaptureClipboardItem(ClipboardItem(type: .image, imageData: tiff))
        }
    }
}
