import SwiftUI

struct TuningSlider: View {
    let note: String
    let target: Double
    let detected: Double?

    private var range: ClosedRange<Double> {
        let lower = max(0, target * 0.65)
        return lower...target
    }

    var body: some View {
        VStack(alignment: .leading) {
            Text("\(note) - target \(String(format: "%.2f Hz", target))")
                .font(.caption)
            Slider(value: .constant(detected ?? target), in: range)
                .disabled(true)
            if let detected {
                Text(String(format: "Detected %.2f Hz", detected))
                    .font(.caption2)
            }
        }
    }
}

#Preview {
    TuningSlider(note: "E1", target: 41.2, detected: 38.0)
}
