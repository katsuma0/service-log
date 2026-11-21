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

    /// Hint shown in the "What you used" field so you remember to log the useful details.
    var partsPrompt: String {
        switch self {
        case .oilChange: "Oil brand, grade and amount, filter. e.g. Castrol Edge 5W-30, 4.5 L, OEM filter"
        case .tireChange: "Tire brand, model, size, wheels. e.g. Michelin CrossClimate 2, 225/45R17"
        case .tireRotation: "Pattern, tire pressure. e.g. Front to back, 35 psi"
        case .alignment: "Type of alignment. e.g. 4-wheel alignment"
        case .brakes: "Pads, rotors, fluid. e.g. Akebono ceramic pads, front"
        case .airFilter, .cabinFilter: "Filter brand and part number"
        case .battery: "Brand, group size, CCA. e.g. Interstate H6, 760 CCA"
        case .wipers: "Brand and lengths. e.g. Bosch Icon 26\" + 18\""
        case .coolant: "Coolant type and amount"
        case .transmission: "Fluid type and amount"
        case .sparkPlugs: "Plug brand and part number"
        case .inspection, .carWash, .other: "Anything you used or replaced"
        }
    }
}
