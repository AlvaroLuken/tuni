import Foundation
import AVFoundation

class AudioManager: ObservableObject {
    private let engine = AVAudioEngine()
    private var isRunning = false

    func start() {
        guard !isRunning else { return }
        let inputNode = engine.inputNode
        let format = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { _, _ in }

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
    }
}
