import SwiftUI

enum ServiceType: String, CaseIterable, Identifiable, Codable {
    case oilChange
    case tireChange
    case tireRotation
    case alignment
    case brakes
    case airFilter
    case cabinFilter
    case battery
    case wipers
    case coolant
    case transmission
    case sparkPlugs
    case inspection
    case carWash
    case other

    var id: String { rawValue }

    var title: String {
        switch self {
        case .oilChange: "Oil change"
        case .tireChange: "Tires"
        case .tireRotation: "Tire rotation"
        case .alignment: "Alignment"
        case .brakes: "Brakes"
        case .airFilter: "Air filter"
        case .cabinFilter: "Cabin filter"
        case .battery: "Battery"
        case .wipers: "Wipers"
        case .coolant: "Coolant"
        case .transmission: "Transmission"
        case .sparkPlugs: "Spark plugs"
        case .inspection: "Inspection"
        case .carWash: "Wash & detail"
        case .other: "Other"
        }
    }

    var symbol: String {
        switch self {
        case .oilChange: "drop.fill"
        case .tireChange: "circle.circle.fill"
        case .tireRotation: "arrow.triangle.2.circlepath"
        case .alignment: "steeringwheel"
        case .brakes: "exclamationmark.brakesignal"
        case .airFilter: "wind"
        case .cabinFilter: "air.purifier.fill"
        case .battery: "bolt.car.fill"
        case .wipers: "windshield.front.and.wiper"
        case .coolant: "thermometer.snowflake"
        case .transmission: "gearshape.2.fill"
        case .sparkPlugs: "bolt.fill"
        case .inspection: "checkmark.seal.fill"
        case .carWash: "sparkles"
        case .other: "wrench.and.screwdriver.fill"
        }
    }

    var tint: Color {
        switch self {
        case .oilChange: .orange
        case .tireChange, .tireRotation: .indigo
        case .alignment: .purple
        case .brakes: .red
        case .airFilter, .cabinFilter: .teal
        case .battery, .sparkPlugs: .yellow
        case .wipers, .carWash: .cyan
        case .coolant: .blue
        case .transmission: .brown
        case .inspection: .green
        case .other: .gray
        }
    }

    /// Example shown in the Notes box so you remember the useful details.
    var notesPrompt: String {
        switch self {
        case .oilChange: "e.g. Synthetic 5W-30, 4.5 L, new filter"
        case .tireChange: "e.g. Michelin CrossClimate 2, 225/45R17"
        case .tireRotation: "e.g. Front to back, set to 35 psi"
        case .alignment: "e.g. 4-wheel alignment"
        case .brakes: "e.g. New front pads and rotors"
        case .airFilter, .cabinFilter: "e.g. Fram filter, part CA10171"
        case .battery: "e.g. Interstate H6, 760 CCA"
        case .wipers: "e.g. Bosch Icon 26 and 18 inch"
        case .coolant: "e.g. Flushed, 6 L Dexcool"
        case .transmission: "e.g. Fluid change, ATF+4"
        case .sparkPlugs: "e.g. NGK Iridium, set of 4"
        case .inspection, .carWash, .other: "e.g. What was done and what you used"
        }
    }
}
