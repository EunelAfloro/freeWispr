import AVFoundation
import Foundation

class AudioRecorder: ObservableObject {
    @Published var isRecording = false
    @Published var audioLevel: Float = 0

    private let audioEngine = AVAudioEngine()
    private var audioBuffer: [Float] = []

    var silenceThreshold: Float = 0.03
    var silenceTimeout: TimeInterval = 1.5
    var maxRecordingDuration: TimeInterval = 30
    private var lastSpeechTime = Date()
    private var recordingStartTime = Date()

    var onRecordingComplete: (([Float]) -> Void)?

    private lazy var whisperFormat: AVAudioFormat = {
        AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: 16000,
            channels: 1,
            interleaved: false
        )!
    }()

    func startRecording() throws {
        audioBuffer.removeAll()
        isRecording = true
        lastSpeechTime = Date()
        recordingStartTime = Date()

        let inputNode = audioEngine.inputNode
        let hardwareFormat = inputNode.outputFormat(forBus: 0)

        guard let converter = AVAudioConverter(from: hardwareFormat, to: whisperFormat) else {
            throw NSError(domain: "AudioRecorder", code: 1,
                         userInfo: [NSLocalizedDescriptionKey: "Cannot create audio format converter"])
        }

        inputNode.installTap(onBus: 0, bufferSize: 4096, format: hardwareFormat) {
            [weak self] buffer, _ in
            guard let self = self, self.isRecording else { return }

            let frameCount = AVAudioFrameCount(
                Double(buffer.frameLength) * (16000.0 / hardwareFormat.sampleRate)
            )
            guard let converted = AVAudioPCMBuffer(pcmFormat: self.whisperFormat, frameCapacity: frameCount) else { return }

            var error: NSError?
            converter.convert(to: converted, error: &error) { _, outStatus in
                outStatus.pointee = .haveData
                return buffer
            }

            guard error == nil, let channelData = converted.floatChannelData else { return }

            let samples = Array(UnsafeBufferPointer(start: channelData[0], count: Int(converted.frameLength)))
            let rms = Self.calculateRMS(samples)

            DispatchQueue.main.async {
                self.audioBuffer.append(contentsOf: samples)
                self.audioLevel = rms

                let now = Date()
                if rms > self.silenceThreshold {
                    self.lastSpeechTime = now
                }

                let silenceExceeded = now.timeIntervalSince(self.lastSpeechTime) > self.silenceTimeout
                let maxDurationExceeded = now.timeIntervalSince(self.recordingStartTime) > self.maxRecordingDuration

                if silenceExceeded || maxDurationExceeded {
                    self.stopRecording()
                }
            }
        }

        audioEngine.prepare()
        try audioEngine.start()
    }

    func stopRecording() {
        guard isRecording else { return }
        isRecording = false

        audioEngine.inputNode.removeTap(onBus: 0)
        audioEngine.stop()

        let finalBuffer = audioBuffer
        audioBuffer.removeAll()
        onRecordingComplete?(finalBuffer)
    }

    static func calculateRMS(_ samples: [Float]) -> Float {
        guard !samples.isEmpty else { return 0 }
        let sumOfSquares = samples.reduce(0) { $0 + $1 * $1 }
        return sqrt(sumOfSquares / Float(samples.count))
    }
}
