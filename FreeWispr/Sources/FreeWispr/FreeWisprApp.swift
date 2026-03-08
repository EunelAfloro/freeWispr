import AppKit
import SwiftUI

struct MenuBarIcon: View {
    let isRecording: Bool
    let isTranscribing: Bool

    private var menuBarImage: NSImage? {
        guard let url = Bundle.appResources.url(forResource: "MenuBarIcon", withExtension: "png", subdirectory: "Resources"),
              let image = NSImage(contentsOf: url) else { return nil }
        image.size = NSSize(width: 18, height: 18)
        image.isTemplate = true
        return image
    }

    var body: some View {
        if let nsImage = menuBarImage {
            Image(nsImage: nsImage)
                .opacity(isRecording ? 0.5 : 1.0)
        } else {
            Image(systemName: isRecording ? "mic.fill" :
                    isTranscribing ? "text.bubble" : "mic")
        }
    }
}

public struct FreeWisprApp: App {
    @StateObject private var appState = AppState()

    public init() {
        // Prevent duplicate instances (only when running as .app with a bundle ID)
        guard let bundleID = Bundle.main.bundleIdentifier else { return }
        let runningApps = NSWorkspace.shared.runningApplications.filter {
            $0.bundleIdentifier == bundleID
        }
        if runningApps.count > 1 {
            runningApps.first { $0 != NSRunningApplication.current }?.activate()
            DispatchQueue.main.async {
                NSApp?.terminate(nil)
            }
        }
    }

    public var body: some Scene {
        MenuBarExtra {
            MenuBarView()
                .environmentObject(appState)
        } label: {
            MenuBarIcon(isRecording: appState.isRecording, isTranscribing: appState.isTranscribing)
                .task {
                    await appState.setup()
                }
        }
        .menuBarExtraStyle(.window)
    }
}

struct MenuBarView: View {
    @EnvironmentObject var appState: AppState
    @State private var hasAppeared = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Status
            HStack {
                Circle()
                    .fill(appState.isRecording ? Color.red :
                            appState.isTranscribing ? Color.orange : Color.green)
                    .frame(width: 8, height: 8)
                Text(appState.statusMessage)
                    .font(.headline)
            }

            Divider()

            // Hotkey display
            HStack {
                Text("Hotkey:")
                Spacer()
                Text("🌐 Globe or ⌃⌥")
                    .foregroundColor(.secondary)
            }

            // Model selector
            HStack {
                Text("Model:")
                Spacer()
                Picker("", selection: Binding(
                    get: { appState.selectedModel },
                    set: { newValue in
                        guard hasAppeared, !appState.isSwitchingModel else { return }
                        Task { await appState.switchModel(to: newValue) }
                    }
                )) {
                    ForEach(ModelSize.allCases) { size in
                        Text("\(size.displayName) (\(size.sizeDescription))").tag(size)
                    }
                }
                .frame(width: 160)
                .disabled(appState.isSwitchingModel)
            }

            if appState.modelManager.isDownloading {
                ProgressView(value: appState.modelManager.downloadProgress)
                    .progressViewStyle(.linear)
            }

            Divider()

            if appState.updateChecker.updateAvailable,
               let latest = appState.updateChecker.latestVersion,
               let url = appState.updateChecker.releaseURL {
                Button(action: { NSWorkspace.shared.open(url) }) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.down.circle.fill")
                            .foregroundColor(.green)
                        Text("Update available: v\(latest)")
                            .foregroundColor(.green)
                    }
                }
                .buttonStyle(.plain)

                Divider()
            }

            HStack {
                Text("v\(appState.updateChecker.currentVersion)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Button("Quit FreeWispr") {
                    NSApplication.shared.terminate(nil)
                }
                .keyboardShortcut("q", modifiers: .command)
            }
        }
        .padding(12)
        .frame(width: 280)
        .onAppear {
            hasAppeared = true
        }
    }
}
