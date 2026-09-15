import SwiftUI
import SwiftData
import ServiceManagement

struct ClipboardMainView: View {
    @EnvironmentObject private var viewModel: ClipboardViewModel
    @FocusState private var searchFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            header
                .padding(.horizontal, 14)
                .padding(.top, 12)
                .padding(.bottom, 8)

            searchBar
                .padding(.horizontal, 14)
                .padding(.bottom, 8)

            Divider()
                .opacity(0.12)

            if viewModel.items.isEmpty {
                emptyState
            } else {
                listContent
            }

            Divider()
                .opacity(0.12)

            settingsSection
                .padding(14)
        }
        .frame(width: 420, height: 520)
        .glassEffect(.regular, in: .rect(cornerRadius: 18))
        .background(WindowAccessor())
    }

    private var header: some View {
        HStack {
            Text("Clipboard History")
                .font(.system(size: 15, weight: .semibold))
            Spacer()
            Button { NSApp.terminate(nil) } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
            .keyboardShortcut("q", modifiers: [.command])
        }
    }

    private var searchBar: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
                .font(.system(size: 12))

            TextField(
                "Search clipboard history",
                text: $viewModel.searchQuery
            )
            .textFieldStyle(.plain)
            .font(.system(size: 13))
            .focused($searchFocused)

            if !searchFocused && viewModel.searchQuery.isEmpty {
                Text("⌘F")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 7)
        .background(
            Color.primary.opacity(searchFocused ? 0.08 : 0.045),
            in: .rect(cornerRadius: 9)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 9)
                .stroke(
                    Color.primary.opacity(searchFocused ? 0.10 : 0.04),
                    lineWidth: 0.5
                )
        }
        .animation(.easeInOut(duration: 0.15), value: searchFocused)
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "doc.on.clipboard")
                .font(.system(size: 28))
                .foregroundColor(.secondary)
                .padding(10)
                .background(
                    Color.primary.opacity(0.04),
                    in: .rect(cornerRadius: 10)
                )
            Text("No clipboard history yet")
                .font(.system(size: 13, weight: .medium))
            Text("Copy some text, images, or files and they'll appear here.")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var listContent: some View {
        ScrollView {
            GlassEffectContainer (spacing: 4){
                VStack(alignment: .leading, spacing: 4) {
                    if !viewModel.pinnedItems.isEmpty {
                        sectionHeader(icon: "pin.fill", label: "Pinned", tint: .orange)
                        ForEach(viewModel.pinnedItems) { item in
                            ClipboardRowView(
                                item: item,
                                onCopy: { viewModel.copyToPasteboard(item) },
                                onPinToggle: { viewModel.togglePin(item) },
                                onDelete: { viewModel.deleteItem(item) }
                            )
                        }
                        Divider().padding(.vertical, 4)
                    }

                    if !viewModel.recentItems.isEmpty {
                        sectionHeader(icon: "clock", label: "Recent", tint: .secondary)
                        ForEach(viewModel.recentItems) { item in
                            ClipboardRowView(
                                item: item,
                                onCopy: { viewModel.copyToPasteboard(item) },
                                onPinToggle: { viewModel.togglePin(item) },
                                onDelete: { viewModel.deleteItem(item) }
                            )
                        }
                    }
                }
                .padding(.horizontal, 10)
                .padding(.top, 7)
            }
        }
    }

    private func sectionHeader(icon: String, label: String, tint: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundColor(tint)
            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.secondary)
        }
        .padding(.leading, 3)
    }

    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Settings")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.secondary)
                .padding(.leading, 2)

            VStack(spacing: 0) {
                HStack {
                    Text("Auto-delete")
                        .font(.system(size: 12))

                    Spacer()

                    Picker("", selection: Binding(
                        get: { viewModel.settings.autoDeleteOption },
                        set: { viewModel.updateAutoDelete(option: $0) }
                    )) {
                        ForEach(AutoDeleteOption.allCases) { option in
                            Text(option.label)
                                .tag(option)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 120)
                    .font(.system(size: 12))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)

                Divider()
                    .opacity(0.08)
                    .padding(.horizontal, 10)

                HStack {
                    Text("Max history")
                        .font(.system(size: 12))

                    Spacer()

                    TextField("", value: Binding(
                        get: { viewModel.settings.maxHistoryItems },
                        set: { viewModel.updateMaxHistory($0) }
                    ), formatter: NumberFormatter())
                    .frame(width: 50)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 12))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)

                Divider()
                    .opacity(0.08)
                    .padding(.horizontal, 10)

                HStack {
                    Text("Launch at Login")
                        .font(.system(size: 12))

                    Spacer()

                    Toggle("", isOn: Binding(
                        get: {
                            SMAppService.mainApp.status == .enabled
                        },
                        set: { enabled in
                            do {
                                if enabled {
                                    try SMAppService.mainApp.register()
                                } else {
                                    try SMAppService.mainApp.unregister()
                                }
                            } catch {
                                print("Launch at Login error: \(error)")
                            }
                        }
                    ))
                    .toggleStyle(.switch)
                    .labelsHidden()
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
            }
            .background(
                Color.primary.opacity(0.035),
                in: .rect(cornerRadius: 11)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 11)
                    .stroke(
                        Color.primary.opacity(0.05),
                        lineWidth: 0.5
                    )
            }

            HStack {
                Spacer()

                Button("Clear All") {
                    viewModel.clearAll()
                }
                .buttonStyle(.plain)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.red)
                .keyboardShortcut("k", modifiers: [.command])
            }
            .padding(.top, 1)
        }
    }
    private struct WindowAccessor: NSViewRepresentable {
        func makeNSView(context: Context) -> NSView {
            let view = NSView()
            DispatchQueue.main.async {
                if let window = view.window {
                    window.isOpaque = false
                    window.backgroundColor = .clear
                    window.hasShadow = true
                }
            }
            return view
        }
        func updateNSView(_ nsView: NSView, context: Context) {}
    }
}
