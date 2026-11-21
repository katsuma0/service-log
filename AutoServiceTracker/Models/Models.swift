import Foundation
import SwiftData

@Model
final class Vehicle {
    var uuid: UUID = UUID()
    var name: String = ""
    var make: String = ""
    var modelName: String = ""
    var year: Int?
    var plate: String = ""
    var createdAt: Date = Date()

    @Relationship(deleteRule: .cascade, inverse: \ServiceRecord.vehicle)
    var records: [ServiceRecord]? = []

    init(name: String, make: String = "", modelName: String = "", year: Int? = nil, plate: String = "") {
        self.uuid = UUID()
        self.name = name
        self.make = make
        self.modelName = modelName
        self.year = year
        self.plate = plate
        self.createdAt = Date()
    }

    /// "2019 Honda Civic"
    var subtitle: String {
        [year.map(String.init), make, modelName]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }
}

@Model
final class ServiceRecord {
    var uuid: UUID = UUID()
    var typeRaw: String = ServiceType.other.rawValue
    var date: Date = Date()
    var odometerKm: Double?
    var cost: Double = 0
    var place: String = ""
    var workDone: String = ""
    var partsUsed: String = ""
    var notes: String = ""
    var vehicle: Vehicle?

    init(
        type: ServiceType,
        date: Date = Date(),
        odometerKm: Double? = nil,
        cost: Double = 0,
        place: String = "",
        workDone: String = "",
        partsUsed: String = "",
        notes: String = ""
    ) {
        self.uuid = UUID()
        self.typeRaw = type.rawValue
        self.date = date
        self.odometerKm = odometerKm
        self.cost = cost
        self.place = place
        self.workDone = workDone
        self.partsUsed = partsUsed
        self.notes = notes
    }

    var type: ServiceType {
        get { ServiceType(rawValue: typeRaw) ?? .other }
        set { typeRaw = newValue.rawValue }
    }
}

extension ServiceRecord: ServiceEntry {}
