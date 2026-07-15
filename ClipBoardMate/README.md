# ClipBoardMate

A native macOS menu bar clipboard manager built with Swift, SwiftUI, and SwiftData.
No Electron, no web tech, no network calls, no telemetry. Clipboard data is
stored only in a local SwiftData store on your Mac.

## Why this ZIP is Swift source files, not a ready .xcodeproj

Xcode's project file (.pbxproj) is a fragile binary-adjacent format tied to a
specific Xcode version and machine-generated UUIDs. Hand-writing one outside
Xcode is a common cause of "cannot open project / corrupted" errors. This ZIP
gives you the complete, correct Swift source tree instead. Creating the empty
project shell in Xcode takes under two minutes, then you drag these files in.
That is the reliable path and what the steps below walk you through.

## Folder structure

```
ClipBoardMate/
  README.md
  ClipBoardMate/
    ClipBoardMateApp.swift        (app entry point, MenuBarExtra, owns the ViewModel)
    Info.plist                    (LSUIElement = YES, etc.)
    ClipBoardMate.entitlements    (App Sandbox)
    Models/
      ClipboardItem.swift
      AppSettings.swift
    Services/
      ClipboardMonitor.swift
      ClipboardRepository.swift
    ViewModels/
      ClipboardViewModel.swift
    Views/
      ClipboardMainView.swift
      ClipboardRowView.swift
```

## Setup steps, in order

1. Open Xcode, File > New > Project > macOS > App.
2. Product Name: ClipBoardMate. Interface: SwiftUI. Language: Swift.
   Minimum Deployment: macOS 14.0. Leave "Use Core Data" unchecked.
3. Xcode creates ClipBoardMateApp.swift and ContentView.swift. Delete
   ContentView.swift (right-click it, Delete, Move to Trash) since this app
   has no ContentView.
4. In Finder, open this ZIP's ClipBoardMate folder. Drag the Models,
   Services, ViewModels, and Views folders, plus ClipBoardMate.entitlements,
   into your Xcode project navigator (drop them onto the top-level
   ClipBoardMate group, next to the existing ClipBoardMateApp.swift).
   When prompted choose "Copy items if needed" and "Create groups", and make
   sure your app target's checkbox is ticked.
5. Open the ClipBoardMateApp.swift from this ZIP and copy its full contents
   over the auto-generated one in Xcode (replace entirely).
6. Select your project in the navigator > target > Signing & Capabilities.
   Click "+ Capability" and add "App Sandbox" if not already present. Then
   under Build Settings, search "Code Signing Entitlements" and set the path
   to ClipBoardMate/ClipBoardMate.entitlements.
7. Select target > Info tab. Add a new row: key "Application is agent
   (UIElement)" (raw key LSUIElement), type Boolean, value YES. This hides
   the Dock icon. (Alternatively point the target's "Info.plist File" build
   setting at the provided Info.plist directly.)
8. Confirm target > General > Minimum Deployments is macOS 14.0.
9. Press Cmd+R to build and run. There is no Dock icon; look for a small
   clipboard icon in the menu bar near the clock. Click it to open the panel.
10. Copy some text or an image anywhere on your Mac and watch it appear in
    the list within about half a second.

## Architecture summary

- View layer (SwiftUI): ClipboardMainView (search, sections, settings) and
  ClipboardRowView (per-item preview, pin, copy, delete).
- ViewModel (MVVM): ClipboardViewModel is created once in
  ClipBoardMateApp.init() and injected into the view tree via
  .environmentObject, so there is a single source of truth and no duplicate
  ModelContext instances.
- Domain and persistence: ClipboardItem and AppSettings are SwiftData
  @Model classes; ClipboardRepository wraps all fetch/insert/delete logic
  and de-duplicates consecutive identical items.
- Services: ClipboardMonitor polls NSPasteboard.general.changeCount on a
  0.5s Timer and notifies its delegate only when the count actually changes.

## How clipboard monitoring works

NSPasteboard.general.changeCount increments every time anything on the
system changes the clipboard. ClipboardMonitor polls this integer on a
Timer instead of continuously reading pasteboard contents, so CPU usage
stays negligible. On a detected change it reads a string first, then falls
back to NSImage, wraps the result in a ClipboardItem, and hands it to the
ViewModel through a delegate callback.

## Where local data is stored

SwiftData persists ClipboardItem and AppSettings records in an
app-sandboxed SQLite-backed store under
~/Library/Containers/<your-bundle-id>/Data/Library/Application Support/.
This is entirely local; nothing is synced to iCloud, uploaded, or sent to
any server.

## Roadmap for future upgrades

- Global keyboard shortcut to summon the panel from any app (CGEvent tap or
  a helper library), not just from clicking the menu bar icon.
- Launch at login using SMAppService (macOS 13+).
- Excluded-apps list: skip capture when NSWorkspace.shared.frontmostApplication
  matches a password manager's bundle identifier.
- Full-size Quick Look-style preview for image items.
- Support additional pasteboard types: file URLs, RTF/attributed strings.
- Keyboard-only navigation through the list (arrow keys + Enter to re-copy).

## Common issues and fixes

1. App still shows a Dock icon: double-check the LSUIElement key is on the
   target actually being run, then fully quit and relaunch (Cmd+Q then
   Cmd+R), a Dock refresh sometimes lags.
2. MenuBarExtra icon never appears: confirm the deployment target is macOS
   13 or later (14 recommended) and that ClipBoardMateApp.swift's body uses
   MenuBarExtra, not WindowGroup.
3. Build error about missing ClipboardItem/AppSettings: make sure both
   files under Models/ were added to the app target's "Target Membership"
   (select the file, check the box in the File Inspector on the right).
4. Clipboard items never appear: verify the Timer is actually running by
   temporarily adding a print statement inside checkForChanges(), and make
   sure you are not copying only whitespace (which is intentionally ignored).
5. Pasted images look blank: NSImage(pasteboard:) can return nil for some
   non-standard image formats; copying from Preview.app or Safari's "Copy
   Image" works reliably for testing.
