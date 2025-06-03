import Foundation

enum Instrument: String, CaseIterable, Identifiable {
    case guitar
    case bass

    var id: String { rawValue }

    var strings: [String: Double] {
        switch self {
        case .guitar:
            return [
                "E2": 82.41,
                "A2": 110.0,
                "D3": 146.83,
                "G3": 196.0,
                "B3": 246.94,
                "E4": 329.63
            ]
        case .bass:
            return [
                "E1": 41.20,
                "A1": 55.0,
                "D2": 73.42,
                "G2": 98.0
            ]
        }
    }
}
