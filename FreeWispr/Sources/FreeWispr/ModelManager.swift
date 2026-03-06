import Foundation

enum ModelSize: String, CaseIterable, Identifiable {
    case tiny, base, small, medium

    var id: String { rawValue }

    var displayName: String {
        rawValue.capitalized
    }

    var sizeDescription: String {
        switch self {
        case .tiny: return "~75 MB"
        case .base: return "~142 MB"
        case .small: return "~466 MB"
        case .medium: return "~1.5 GB"
        }
    }
}

@MainActor
class ModelManager: ObservableObject {
    @Published var downloadProgress: Double = 0
    @Published var isDownloading = false
    @Published var currentModel: ModelSize = .base

    private let baseURL = "https://huggingface.co/ggerganov/whisper.cpp/resolve/main"

    private var modelsDirectory: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return appSupport.appendingPathComponent("FreeWispr/models")
    }

    nonisolated func downloadURL(for model: ModelSize) -> URL {
        URL(string: "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-\(model.rawValue).bin")!
    }

    nonisolated func localModelPath(for model: ModelSize) -> URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return appSupport.appendingPathComponent("FreeWispr/models/ggml-\(model.rawValue).bin")
    }

    func isModelDownloaded(_ model: ModelSize) -> Bool {
        FileManager.default.fileExists(atPath: localModelPath(for: model).path)
    }

    func downloadModel(_ model: ModelSize) async throws {
        let destination = localModelPath(for: model)

        try FileManager.default.createDirectory(
            at: modelsDirectory,
            withIntermediateDirectories: true
        )

        if isModelDownloaded(model) { return }

        isDownloading = true
        downloadProgress = 0
        defer { isDownloading = false }

        let url = downloadURL(for: model)
        let (asyncBytes, response) = try await URLSession.shared.bytes(from: url)

        let totalBytes = response.expectedContentLength
        var data = Data()
        if totalBytes > 0 {
            data.reserveCapacity(Int(totalBytes))
        }

        var bytesReceived: Int64 = 0
        for try await byte in asyncBytes {
            data.append(byte)
            bytesReceived += 1
            if totalBytes > 0 && bytesReceived % 1_000_000 == 0 {
                downloadProgress = Double(bytesReceived) / Double(totalBytes)
            }
        }

        try data.write(to: destination)
        downloadProgress = 1.0
    }

    func deleteModel(_ model: ModelSize) throws {
        let path = localModelPath(for: model)
        if FileManager.default.fileExists(atPath: path.path) {
            try FileManager.default.removeItem(at: path)
        }
    }
}
