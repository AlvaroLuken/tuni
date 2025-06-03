import SwiftUI
import AVFoundation

struct ContentView: View {
    @StateObject private var audioManager = AudioManager()
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        VStack(spacing: 20) {
            Button("Start Tuning") {
                audioManager.start()
            }
            .padding()

            Button("Stop") {
                audioManager.stop()
            }
            .padding()
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
