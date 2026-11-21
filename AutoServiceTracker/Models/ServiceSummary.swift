import Foundation

/// The bits of a service record the summary math needs. Kept separate so it's easy to test.
protocol ServiceEntry {
    var type: ServiceType { get }
    var date: Date { get }
    var odometerKm: Double? { get }
    var cost: Double { get }
}

enum ServiceSummary {
    /// The most recent entry of each service type, newest first.
    static func latestByType<T: ServiceEntry>(_ entries: [T]) -> [T] {
        var latest: [ServiceType: T] = [:]
        for entry in entries {
            if let existing = latest[entry.type], existing.date >= entry.date { continue }
            latest[entry.type] = entry
        }
        return latest.values.sorted { $0.date > $1.date }
    }

    /// Highest odometer reading you've logged.
    static func currentOdometerKm<T: ServiceEntry>(_ entries: [T]) -> Double? {
        entries.compactMap(\.odometerKm).max()
    }

    /// How far you've driven since this entry, if both readings are known.
    static func kmSince<T: ServiceEntry>(_ entry: T, currentKm: Double?) -> Double? {
        guard let then = entry.odometerKm, let now = currentKm, now >= then else { return nil }
        return now - then
    }

    /// Total spent in the calendar year containing `date`.
    static func totalCost<T: ServiceEntry>(_ entries: [T], inYearOf date: Date, calendar: Calendar = .current) -> Double {
        let year = calendar.component(.year, from: date)
        return entries
            .filter { calendar.component(.year, from: $0.date) == year }
            .reduce(0) { $0 + $1.cost }
    }

    /// Lenient number parsing for text fields: accepts "1,234.50", "1234,5" and "84 210".
    static func parseNumber(_ text: String) -> Double? {
        var cleaned = text.filter { $0.isNumber || $0 == "." || $0 == "," }
        guard !cleaned.isEmpty else { return nil }
        if let lastSep = cleaned.lastIndex(where: { $0 == "." || $0 == "," }) {
            let decimals = cleaned.distance(from: lastSep, to: cleaned.endIndex) - 1
            if decimals > 0 && decimals <= 2 {
                // Treat the last separator as the decimal point, the rest as grouping.
                let whole = cleaned[..<lastSep].filter(\.isNumber)
                let frac = cleaned[cleaned.index(after: lastSep)...]
                cleaned = "\(whole).\(frac)"
            } else {
                cleaned = cleaned.filter(\.isNumber)
            }
        }
        return Double(cleaned)
    }
}
