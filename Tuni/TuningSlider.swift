import SwiftUI

struct TuningSlider: View {
    let note: String
    let target: Double
    let detected: Double?
    let isCurrent: Bool
    let isTuned: Bool

    private var range: ClosedRange<Double> {
        let span = target * 0.3
        let lower = max(1, target - span)
        let upper = target + span
        return lower...upper
    }

    private var tint: Color {
        guard let detected else { return .gray }
        let diff = abs(detected - target)
        if diff < 1 { return .green }
        if diff < 5 { return .yellow }
        return .red
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
                .tint(tint)
                .overlay(
                    GeometryReader { geo in
                        let width = geo.size.width
                        Rectangle()
                            .fill(Color.green.opacity(0.3))
                            .frame(width: 4)
                            .position(x: width / 2, y: geo.size.height / 2)
                    }
                )
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
