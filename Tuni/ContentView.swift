import SwiftUI
import AVFoundation

struct ContentView: View {
    @StateObject private var audioManager = AudioManager()
    @Environment(\.scenePhase) private var scenePhase
    @State private var instrument: Instrument = .guitar

    var body: some View {
        VStack(spacing: 20) {
            Picker("Instrument", selection: $instrument) {
                ForEach(Instrument.allCases) { ins in
                    Text(ins.rawValue.capitalized)
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

                ForEach(instrument.strings.sorted(by: { $0.key < $1.key }), id: \.key) { note, target in
                    TuningSlider(note: note, target: target, detected: audioManager.frequency)
                }
            } else {
                Button("Start Tuning") {
                    audioManager.start()
                }
                .padding()
            }
        }
        .onChange(of: scenePhase) { phase in
            if phase != .active {
                audioManager.stop()
            }
        }
    }
}

#Preview {
    ContentView()
}
