import AppKit
import Foundation

@MainActor
class UpdateChecker: ObservableObject {
    @Published var latestVersion: String? = nil
    @Published var releaseURL: URL? = nil
    @Published var isUpdating = false

    var updateAvailable: Bool {
        guard let latest = latestVersion else { return false }
        return isNewer(latest, than: currentVersion)
    }

    let currentVersion: String = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"

    private let apiURL = URL(string: "https://api.github.com/repos/ygivenx/freeWispr/releases/latest")!
    private var dmgAssetURL: URL?

    func checkForUpdate() async {
        var request = URLRequest(url: apiURL)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")

        guard let (data, _) = try? await URLSession.shared.data(for: request),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let tag = json["tag_name"] as? String,
              let htmlURL = json["html_url"] as? String,
              let url = URL(string: htmlURL)
        else { return }

        let version = tag.hasPrefix("v") ? String(tag.dropFirst()) : tag
        latestVersion = version
        releaseURL = url

        // Find .dmg asset URL (reset first to avoid stale values)
        dmgAssetURL = nil
        if let assets = json["assets"] as? [[String: Any]] {
            dmgAssetURL = assets
                .first { ($0["name"] as? String)?.hasSuffix(".dmg") == true }
                .flatMap { $0["browser_download_url"] as? String }
                .flatMap { URL(string: $0) }
        }
    }

    func downloadAndInstall() async {
        guard let dmgURL = dmgAssetURL else {
            // Fallback: open release page
            if let url = releaseURL { NSWorkspace.shared.open(url) }
            return
        }

        isUpdating = true

        do {
            let (tempURL, _) = try await URLSession.shared.download(from: dmgURL, delegate: nil)
            let dest = FileManager.default.temporaryDirectory.appendingPathComponent("FreeWispr-update.dmg")
            try? FileManager.default.removeItem(at: dest)
            try FileManager.default.moveItem(at: tempURL, to: dest)

            // Open the DMG — macOS mounts it, user sees the drag-to-install window
            NSWorkspace.shared.open(dest)
            isUpdating = false
        } catch {
            isUpdating = false
            // Fallback: open release page
            if let url = releaseURL { NSWorkspace.shared.open(url) }
        }
    }

    // Simple semver comparison: "1.2.3" > "1.1.0"
    private func isNewer(_ candidate: String, than current: String) -> Bool {
        let a = candidate.split(separator: ".").compactMap { Int($0) }
        let b = current.split(separator: ".").compactMap { Int($0) }
        let count = max(a.count, b.count)
        for i in 0..<count {
            let av = i < a.count ? a[i] : 0
            let bv = i < b.count ? b[i] : 0
            if av != bv { return av > bv }
        }
        return false
    }
}
