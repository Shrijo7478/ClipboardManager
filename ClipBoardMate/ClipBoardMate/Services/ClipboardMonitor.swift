import Foundation
import AppKit
import UniformTypeIdentifiers

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
    private func isImageFile(_ url: URL) -> Bool {
        guard
            let type = try? url.resourceValues(forKeys: [.contentTypeKey]).contentType
        else {
            return false
        }
        
        return type.conforms(to: .image)
    }
    
    private func fileIconData(for url: URL) -> Data? {
        let icon = NSWorkspace.shared.icon(forFile: url.path)
        return icon.tiffRepresentation
    }
    
    private func readClipboard() {
        
        // 1. File copied from Finder
        if let fileURL = pasteboard.readObjects(forClasses: [NSURL.self])?.first as? URL {
            
            // Image file
            if isImageFile(fileURL),
               let image = NSImage(contentsOf: fileURL),
               let tiff = image.tiffRepresentation {
                
                delegate?.didCaptureClipboardItem(
                    ClipboardItem(
                        type: .image,
                        imageData: tiff,
                        fileName: fileURL.lastPathComponent,
                        fileURL: fileURL.path
                    )
                )
                return
            }
            
            // Non-image file
            let iconData = fileIconData(for: fileURL)
            
            delegate?.didCaptureClipboardItem(
                ClipboardItem(
                    type: .file,
                    imageData: iconData,
                    fileName: fileURL.lastPathComponent,
                    fileURL: fileURL.path
                )
            )
            
            return
        }
        
        // 2. Images copied from Preview, Safari, Photos, screenshots, etc.
        if let nsImage = NSImage(pasteboard: pasteboard),
           let tiff = nsImage.tiffRepresentation {
            
            delegate?.didCaptureClipboardItem(
                ClipboardItem(
                    type: .image,
                    imageData: tiff
                )
            )
            return
        }
        
        // 3. Text
        if let string = pasteboard.string(forType: .string),
           !string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            
            delegate?.didCaptureClipboardItem(
                ClipboardItem(
                    type: .text,
                    textContent: string
                )
            )
        }
    }
}
