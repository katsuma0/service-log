import SwiftUI
import SwiftData

private enum GarageSheet: Identifiable {
    case newRecord
    case addVehicle
    case editVehicle
    case settings

    var id: Int { hashValue }
}

struct GarageView: View {
    let vehicle: Vehicle
    let vehicles: [Vehicle]
    @Binding var selectedID: String

    @Query(sort: \ServiceRecord.date, order: .reverse) private var allRecords: [ServiceRecord]
    @AppStorage(DistanceUnit.storageKey) private var unit: DistanceUnit = .km
    @AppStorage(Currency.key) private var currency = Currency.defaultCode
    @State private var filter: ServiceType?
    @State private var sheet: GarageSheet?

    private var records: [ServiceRecord] {
        allRecords.filter { $0.vehicle?.uuid == vehicle.uuid }
    }

    private var filteredRecords: [ServiceRecord] {
        guard let filter else { return records }
        return records.filter { $0.type == filter }
    }

    private var currentKm: Double? { ServiceSummary.currentOdometerKm(records) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                header
                if records.isEmpty {
                    emptyState
                } else {
                    lastDoneSection
                    historySection
                }
            }
            .padding(.horizontal)
            .padding(.top, 4)
            .padding(.bottom, 96)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(vehicle.name)
        .navigationDestination(for: ServiceRecord.self) { RecordDetailView(record: $0) }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) { vehicleMenu }
            ToolbarItem(placement: .topBarTrailing) {
                Button { sheet = .settings } label: { Image(systemName: "gearshape") }
                    .accessibilityLabel("Settings")
            }
        }
        .safeAreaInset(edge: .bottom) { logButton }
        .sheet(item: $sheet) { sheet in
            switch sheet {
            case .newRecord:
                RecordFormView(vehicle: vehicle)
            case .addVehicle:
                VehicleFormView(vehicle: nil) { selectedID = $0.uuid.uuidString }
            case .editVehicle:
                VehicleFormView(vehicle: vehicle) { _ in }
            case .settings:
                SettingsView()
            }
        }
        .onChange(of: vehicle.uuid) { filter = nil }
    }

    // MARK: Sections

    private var header: some View {
        VStack(alignment: .leading, spacing: 16) {
            if !vehicle.subtitle.isEmpty || !vehicle.plate.isEmpty {
                HStack {
                    Text(vehicle.subtitle)
                    Spacer()
                    if !vehicle.plate.isEmpty {
                        Text(vehicle.plate.uppercased())
                            .font(.caption.monospaced().weight(.semibold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.white.opacity(0.2), in: Capsule())
                    }
                }
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white.opacity(0.9))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Odometer")
                    .font(.caption.weight(.semibold))
                    .textCase(.uppercase)
                    .foregroundStyle(.white.opacity(0.75))
                Text(currentKm.map { unit.format(km: $0) } ?? "No reading yet")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())
            }

            HStack(spacing: 0) {
                stat("This year", Currency.format(ServiceSummary.totalCost(records, inYearOf: .now), code: currency))
                stat("All time", Currency.format(records.reduce(0) { $0 + $1.cost }, code: currency))
                stat("Services", "\(records.count)")
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [Color.accentColor, Color.accentColor.opacity(0.75)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 24, style: .continuous)
        )
        .shadow(color: Color.accentColor.opacity(0.25), radius: 16, y: 8)
    }

    private func stat(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.75))
            Text(value)
                .font(.headline)
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "wrench.and.screwdriver")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
            Text("Nothing logged yet")
                .font(.headline)
            Text("After your next oil change or tire swap, tap Log service. You'll never have to dig for the receipt again.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(28)
        .frame(maxWidth: .infinity)
        .card()
    }

    private var lastDoneSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(text: "Last time you did it")
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                ForEach(ServiceSummary.latestByType(records)) { record in
                    NavigationLink(value: record) {
                        LastDoneCard(record: record, currentKm: currentKm, unit: unit, currency: currency)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var historySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(text: "History")
            filterChips
            VStack(spacing: 0) {
                ForEach(Array(filteredRecords.enumerated()), id: \.element.id) { index, record in
                    NavigationLink(value: record) {
                        RecordRow(record: record, unit: unit, currency: currency)
                    }
                    .buttonStyle(.plain)
                    if index < filteredRecords.count - 1 {
                        Divider().padding(.leading, 68)
                    }
                }
            }
            .card()
        }
    }

    private var filterChips: some View {
        let types = ServiceType.allCases.filter { t in records.contains { $0.type == t } }
        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                chip("All", selected: filter == nil) { filter = nil }
                ForEach(types) { t in
                    chip(t.title, selected: filter == t) { filter = (filter == t) ? nil : t }
                }
            }
            .padding(.horizontal, 2)
        }
    }

    private func chip(_ title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: { withAnimation(.snappy) { action() } }) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .foregroundStyle(selected ? Color.white : Color.primary)
                .background(selected ? AnyShapeStyle(Color.accentColor) : AnyShapeStyle(Color(.secondarySystemGroupedBackground)), in: Capsule())
        }
        .buttonStyle(.plain)
    }

    private var vehicleMenu: some View {
        Menu {
            if vehicles.count > 1 {
                Picker("Vehicle", selection: $selectedID) {
                    ForEach(vehicles) { v in
                        Text(v.name).tag(v.uuid.uuidString)
                    }
                }
            }
            Button { sheet = .editVehicle } label: { Label("Edit \(vehicle.name)", systemImage: "pencil") }
            Button { sheet = .addVehicle } label: { Label("Add a vehicle", systemImage: "plus") }
        } label: {
            Image(systemName: "car.2.fill")
        }
        .accessibilityLabel("Vehicles")
    }

    private var logButton: some View {
        Button { sheet = .newRecord } label: {
            Label("Log service", systemImage: "plus")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .buttonBorderShape(.capsule)
        .shadow(color: Color.accentColor.opacity(0.3), radius: 12, y: 6)
        .padding(.horizontal, 24)
        .padding(.bottom, 8)
    }
}

private struct LastDoneCard: View {
    let record: ServiceRecord
    let currentKm: Double?
    let unit: DistanceUnit
    let currency: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                TypeIcon(type: record.type, size: 38)
                Spacer()
                if record.cost > 0 {
                    Text(Currency.format(record.cost, code: currency))
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(record.type.title)
                    .font(.headline)
                    .lineLimit(1)
                Text(record.date.formatted(.relative(presentation: .named)))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                if let since = ServiceSummary.kmSince(record, currentKm: currentKm), since > 0 {
                    Text("\(unit.format(km: since)) ago")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else if let km = record.odometerKm {
                    Text("at \(unit.format(km: km))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .card()
        .contentShape(Rectangle())
    }
}

struct RecordRow: View {
    let record: ServiceRecord
    let unit: DistanceUnit
    let currency: String

    private var detail: String {
        let date = record.date.formatted(date: .abbreviated, time: .omitted)
        return record.place.isEmpty ? date : "\(date) · \(record.place)"
    }

    var body: some View {
        HStack(spacing: 12) {
            TypeIcon(type: record.type, size: 40)
            VStack(alignment: .leading, spacing: 2) {
                Text(record.type.title)
                    .font(.body.weight(.semibold))
                Text(detail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 8)
            VStack(alignment: .trailing, spacing: 2) {
                Text(record.cost > 0 ? Currency.format(record.cost, code: currency) : "Free")
                    .font(.body.weight(.semibold))
                if let km = record.odometerKm {
                    Text(unit.format(km: km))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }
}
