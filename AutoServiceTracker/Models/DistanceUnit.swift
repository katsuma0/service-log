import Foundation

/// Odometer readings are always stored in kilometers. This converts for display and input.
enum DistanceUnit: String, CaseIterable, Identifiable {
    case km
    case mi

    static let kmPerMile = 1.609344
    static let storageKey = "distanceUnit"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .km: "Kilometers"
        case .mi: "Miles"
        }
    }

    func fromKm(_ km: Double) -> Double {
        self == .km ? km : km / Self.kmPerMile
    }

    func toKm(_ value: Double) -> Double {
        self == .km ? value : value * Self.kmPerMile
    }

    /// "84,210 km"
    func format(km: Double) -> String {
        "\(Int(fromKm(km).rounded()).formatted()) \(rawValue)"
    }
}
