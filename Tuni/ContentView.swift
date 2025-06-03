import SwiftUI
import AVFoundation

struct ContentView: View {
    @StateObject private var audioManager = AudioManager()
    @Environment(\.scenePhase) private var scenePhase
    // Start with no instrument selected so the user must choose
    @State private var instrument: Instrument?
    @State private var currentStringIndex = 0
    @State private var tunedStrings: Set<Int> = []
    /// When the frequency first entered the tolerance range.
    @State private var stableStart: Date?

    private let tolerance: Double = 2
    private let requiredStability: TimeInterval = 0.5

    var body: some View {
        VStack(spacing: 20) {
            if audioManager.isRunning {
                if let freq = audioManager.frequency {
                    Text(String(format: "Detected %.2f Hz", freq))
                        .font(.headline)
                } else {
                    Text("Detecting…")
                        .font(.headline)
                }
            } else {
                Text("Not running")
                    .font(.headline)
            }

            Picker("Instrument", selection: $instrument) {
                ForEach(Instrument.allCases) { ins in
                    Text(ins.rawValue.capitalized)
                        .tag(Optional(ins))
                }
            }
            .pickerStyle(.segmented)

            if audioManager.isRunning {
                Image(systemName: "mic.fill")
                    .foregroundColor(.red)

                Button("Stop Tuning") {
                    audioManager.stop()
                    audioManager.setTargetFrequency(nil)
                }
                .padding()

                if let instrument {
                    ForEach(instrument.strings.indices, id: \.self) { index in
                        let string = instrument.strings[index]
                        TuningSlider(
                            note: string.note,
                            target: string.target,
                            detected: index == currentStringIndex ? audioManager.frequency : nil,
                            isCurrent: index == currentStringIndex,
                            isTuned: tunedStrings.contains(index)
                        )
                    }
                }
            } else {
                if instrument != nil {
                    Button("Start Tuning") {
                        audioManager.start()
                        if let instrument {
                            audioManager.setTargetFrequency(instrument.strings[currentStringIndex].target)
                        }
                        currentStringIndex = 0
                        tunedStrings = []
                    }
                    .padding()
                }
            }
        }
        .onChange(of: scenePhase) { phase in
            if phase != .active {
                audioManager.stop()
            }
        }
        .onChange(of: instrument) { _ in
            currentStringIndex = 0
            tunedStrings = []
            if let instrument {
                audioManager.setTargetFrequency(instrument.strings[currentStringIndex].target)
            } else {
                audioManager.setTargetFrequency(nil)
            }
        }
        .onChange(of: audioManager.frequency) { freq in
            guard let instrument, let freq else {
                stableStart = nil
                return
            }

            let target = instrument.strings[currentStringIndex].target

            if abs(freq - target) <= tolerance {
                if stableStart == nil {
                    stableStart = Date()
                }

                if let start = stableStart,
                   Date().timeIntervalSince(start) >= requiredStability,
                   !tunedStrings.contains(currentStringIndex) {
                    tunedStrings.insert(currentStringIndex)
                    stableStart = nil

                    if currentStringIndex < instrument.strings.count - 1 {
                        currentStringIndex += 1
                        audioManager.setTargetFrequency(instrument.strings[currentStringIndex].target)
                    }
                }
            } else {
                stableStart = nil
            }
        }
    }
}

#Preview {
    ContentView()
}
