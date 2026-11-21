import XCTest
import SwiftData
@testable import AutoServiceTracker

private struct Entry: ServiceEntry {
    var type: ServiceType
    var date: Date
    var odometerKm: Double?
    var cost: Double
}

private func day(_ y: Int, _ m: Int, _ d: Int) -> Date {
    Calendar.current.date(from: DateComponents(year: y, month: m, day: d))!
}

final class DistanceUnitTests: XCTestCase {
    func testKmIsIdentity() {
        XCTAssertEqual(DistanceUnit.km.fromKm(1000), 1000)
        XCTAssertEqual(DistanceUnit.km.toKm(1000), 1000)
    }

    func testMilesRoundTrip() {
        let km = DistanceUnit.mi.toKm(100)
        XCTAssertEqual(km, 160.9344, accuracy: 0.0001)
        XCTAssertEqual(DistanceUnit.mi.fromKm(km), 100, accuracy: 0.0001)
    }

    func testFormatRoundsAndAddsUnit() {
        XCTAssertTrue(DistanceUnit.km.format(km: 84210.4).hasSuffix(" km"))
        XCTAssertTrue(DistanceUnit.mi.format(km: 160.9344).hasPrefix("100"))
    }
}

final class ServiceSummaryTests: XCTestCase {
    private let entries = [
        Entry(type: .oilChange, date: day(2025, 1, 10), odometerKm: 70_000, cost: 80),
        Entry(type: .oilChange, date: day(2025, 7, 2), odometerKm: 78_000, cost: 95),
        Entry(type: .tireChange, date: day(2025, 4, 15), odometerKm: 74_000, cost: 900),
        Entry(type: .alignment, date: day(2024, 11, 3), odometerKm: nil, cost: 120),
    ]

    func testLatestByTypeKeepsNewestPerType() {
        let latest = ServiceSummary.latestByType(entries)
        XCTAssertEqual(latest.count, 3)
        XCTAssertEqual(latest.first?.type, .oilChange)
        XCTAssertEqual(latest.first?.cost, 95)
        XCTAssertEqual(latest.map(\.type), [.oilChange, .tireChange, .alignment])
    }

    func testCurrentOdometerIsHighestReading() {
        XCTAssertEqual(ServiceSummary.currentOdometerKm(entries), 78_000)
        XCTAssertNil(ServiceSummary.currentOdometerKm([Entry]()))
    }

    func testKmSince() {
        XCTAssertEqual(ServiceSummary.kmSince(entries[2], currentKm: 78_000), 4_000)
        XCTAssertNil(ServiceSummary.kmSince(entries[3], currentKm: 78_000))
    }

    func testTotalCostForYear() {
        XCTAssertEqual(ServiceSummary.totalCost(entries, inYearOf: day(2025, 6, 1)), 1_075)
        XCTAssertEqual(ServiceSummary.totalCost(entries, inYearOf: day(2024, 6, 1)), 120)
    }

    func testParseNumber() {
        XCTAssertEqual(ServiceSummary.parseNumber("84210"), 84_210)
        XCTAssertEqual(ServiceSummary.parseNumber("84,210"), 84_210)
        XCTAssertEqual(ServiceSummary.parseNumber("84 210 km"), 84_210)
        XCTAssertEqual(ServiceSummary.parseNumber("89.99"), 89.99)
        XCTAssertEqual(ServiceSummary.parseNumber("89,99"), 89.99)
        XCTAssertEqual(ServiceSummary.parseNumber("$1,234.50"), 1_234.5)
        XCTAssertNil(ServiceSummary.parseNumber(""))
        XCTAssertNil(ServiceSummary.parseNumber("abc"))
    }

    func testServiceTypeRoundTrip() {
        for t in ServiceType.allCases {
            XCTAssertEqual(ServiceType(rawValue: t.rawValue), t)
            XCTAssertFalse(t.title.isEmpty)
        }
    }
}

@MainActor
final class PersistenceTests: XCTestCase {
    func testRecordsBelongToVehicleAndCascadeDelete() throws {
        let container = try ModelContainer(
            for: Vehicle.self, ServiceRecord.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext

        let car = Vehicle(name: "Daily", make: "Honda", modelName: "Civic", year: 2019)
        context.insert(car)
        let oil = ServiceRecord(type: .oilChange, odometerKm: 80_000, cost: 89.99, partsUsed: "Castrol Edge 5W-30")
        context.insert(oil)
        oil.vehicle = car
        try context.save()

        XCTAssertEqual(car.records?.count, 1)
        XCTAssertEqual(car.subtitle, "2019 Honda Civic")
        XCTAssertEqual(oil.type, .oilChange)

        context.delete(car)
        try context.save()
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<ServiceRecord>()), 0)
    }
}
