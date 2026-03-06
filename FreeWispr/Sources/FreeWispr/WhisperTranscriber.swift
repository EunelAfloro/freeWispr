import Foundation
import SwiftWhisper

enum TranscriberError: Error {
    case modelNotLoaded
    case transcriptionFailed(String)
}

class WhisperTranscriber: ObservableObject {
    @Published var isModelLoaded = false
    @Published var isTranscribing = false

    private var whisper: Whisper?

    func loadModel(at path: URL) throws {
        whisper = Whisper(fromFileURL: path)
        isModelLoaded = true
    }

    func unloadModel() {
        whisper = nil
        isModelLoaded = false
    }

    func transcribe(audioSamples: [Float], language: String? = nil) async throws -> String {
        guard let whisper = whisper else {
            throw TranscriberError.modelNotLoaded
        }

        isTranscribing = true
        defer { isTranscribing = false }

        let segments = try await whisper.transcribe(audioFrames: audioSamples)
        let text = segments.map(\.text).joined().trimmingCharacters(in: .whitespacesAndNewlines)
        return text
    }
}
