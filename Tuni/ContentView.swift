import SwiftUI
import AVFoundation

struct ContentView: View {
    @StateObject private var audioManager = AudioManager()
    @Environment(\.scenePhase) private var scenePhase
    // Start with no instrument selected so the user must choose
    @State private var instrument: Instrument?
    @State private var currentStringIndex = 0
    @State private var tunedStrings: Set<Int> = []

    var body: some View {
        VStack(spacing: 20) {
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
                }
                .padding()

                if let freq = audioManager.frequency {
                    Text(String(format: "Detected %.2f Hz", freq))
                } else {
                    Text("Detecting…")
                }

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
        }
        .onChange(of: audioManager.frequency) { freq in
            guard let instrument, let freq else { return }
            let target = instrument.strings[currentStringIndex].target
            if abs(freq - target) <= 2 && !tunedStrings.contains(currentStringIndex) {
                tunedStrings.insert(currentStringIndex)
                if currentStringIndex < instrument.strings.count - 1 {
                    currentStringIndex += 1
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
