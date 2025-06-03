import Foundation
import AVFoundation
import Accelerate

class AudioManager: ObservableObject {
    private let engine = AVAudioEngine()
    @Published private(set) var isRunning = false
    @Published var frequency: Double?

    private let processingQueue = DispatchQueue(label: "AudioProcessingQueue")

    func start() {
        guard !isRunning else { return }
        let inputNode = engine.inputNode
        let format = inputNode.outputFormat(forBus: 0)
        // Larger buffer improves detection of lower frequencies like bass notes
        inputNode.installTap(onBus: 0, bufferSize: 4096, format: format) { [weak self] buffer, _ in
            self?.process(buffer: buffer)
        }

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, options: [.defaultToSpeaker, .mixWithOthers])
            try session.setActive(true)
            try engine.start()
            isRunning = true
        } catch {
            print("Failed to start audio engine: \(error)")
        }
    }

    func stop() {
        guard isRunning else { return }
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            print("Failed to deactivate audio session: \(error)")
        }
        isRunning = false
        frequency = nil
    }

    private func process(buffer: AVAudioPCMBuffer) {
        processingQueue.async {
            guard let channelData = buffer.floatChannelData?[0] else { return }
            let frameLength = Int(buffer.frameLength)
            let sampleRate = buffer.format.sampleRate

            let minLag = Int(sampleRate / 400) // search up to ~400 Hz
            let maxLag = min(Int(sampleRate / 30), frameLength / 2)

            var bestLag = 0
            var maxCorr: Float = 0

            if frameLength > 0 {
                for lag in minLag..<maxLag {
                    var corr: Float = 0
                    for i in 0..<(frameLength - lag) {
                        corr += channelData[i] * channelData[i + lag]
                    }
                    if corr > maxCorr {
                        maxCorr = corr
                        bestLag = lag
                    }
                }
            }

            guard bestLag > 0 else { return }
            let freq = sampleRate / Double(bestLag)
            DispatchQueue.main.async { [weak self] in
                self?.frequency = freq
            }
        }
    }
}
