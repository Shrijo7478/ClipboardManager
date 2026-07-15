import SwiftUI
import SwiftData

// Privacy: Clipboard history is stored locally using SwiftData.
// No networking, telemetry, or cloud sync is implemented anywhere in this app.
// Clipboard data never leaves this device.

@main
struct ClipBoardMateApp: App {
    let modelContainer: ModelContainer
    @StateObject private var viewModel: ClipboardViewModel

    init() {
        let container: ModelContainer
        do {
            container = try ModelContainer(for: ClipboardItem.self, AppSettings.self)
        } catch {
            fatalError("Failed to create SwiftData ModelContainer: \(error)")
        }
        modelContainer = container
        _viewModel = StateObject(wrappedValue: ClipboardViewModel(context: container.mainContext))
    }

    var body: some Scene {
        MenuBarExtra("ClipBoardMate", systemImage: "doc.on.clipboard") {
            ClipboardMainView()
                .environmentObject(viewModel)
        }
        .menuBarExtraStyle(.window)
        .modelContainer(modelContainer)
    }
}
