import Foundation
import AVFoundation
import Accelerate

class AudioManager: ObservableObject {
    private let engine = AVAudioEngine()
    @Published private(set) var isRunning = false
    @Published var frequency: Double?

    /// Expected frequency of the current string being tuned. Narrowing the
    /// search range around this value helps reduce noise induced errors.
    private var targetFrequency: Double?

    private let processingQueue = DispatchQueue(label: "AudioProcessingQueue")

    /// Update the expected frequency for pitch detection.
    func setTargetFrequency(_ freq: Double?) {
        processingQueue.async { [weak self] in
            self?.targetFrequency = freq
        }
    }

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
        processingQueue.async { [weak self] in
            guard let self else { return }
            guard let channelData = buffer.floatChannelData?[0] else { return }
            let frameLength = Int(buffer.frameLength)
            let sampleRate = buffer.format.sampleRate

            // Skip processing if the signal amplitude is too low.
            var rms: Float = 0
            vDSP_rmsqv(channelData, 1, &rms, vDSP_Length(frameLength))
            if rms < 0.02 { return }

            // Determine the lag search range. If a target frequency is set, only
            // search near that value to avoid spurious detections.
            var minLag = Int(sampleRate / 400)
            var maxLag = min(Int(sampleRate / 30), frameLength / 2)
            if let target = self.targetFrequency {
                let lowerFreq = max(1, target * 0.9)
                let upperFreq = target * 1.1
                minLag = Int(sampleRate / upperFreq)
                maxLag = min(Int(sampleRate / lowerFreq), frameLength / 2)
            }

            var bestLag = 0
            var maxCorr: Float = 0

            var energy: Float = 0
            vDSP_dotpr(channelData, 1, channelData, 1, &energy, vDSP_Length(frameLength))

            if frameLength > 0 {
                for lag in minLag..<maxLag {
                    var corr: Float = 0
                    for i in 0..<(frameLength - lag) {
                        corr += channelData[i] * channelData[i + lag]
                    }
                    let normalized = corr / (energy + 1e-9)
                    if normalized > maxCorr {
                        maxCorr = normalized
                        bestLag = lag
                    }
                }
            }

            guard bestLag > 0, maxCorr > 0.2 else { return }
            let freq = sampleRate / Double(bestLag)
            DispatchQueue.main.async { [weak self] in
                self?.frequency = freq
            }
        }
    }
}
