import SwiftUI

struct TuningSlider: View {
    let note: String
    let target: Double
    let detected: Double?
    let isCurrent: Bool
    let isTuned: Bool

    private var range: ClosedRange<Double> {
        let lower = max(0, target * 0.65)
        return lower...target
    }

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                if isCurrent {
                    Image(systemName: "arrowtriangle.right.fill")
                }
                Text("\(note) - target \(String(format: "%.2f Hz", target))")
                    .font(.caption)
                if isTuned {
                    Image(systemName: "checkmark")
                        .foregroundColor(.green)
                }
            }
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
    TuningSlider(note: "E1", target: 41.2, detected: 38.0, isCurrent: true, isTuned: false)
}
