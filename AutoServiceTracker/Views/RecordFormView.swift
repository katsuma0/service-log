import SwiftUI
import SwiftData

/// Add a new service, edit an existing one, or start from a past one ("Log this again").
struct RecordFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @AppStorage(DistanceUnit.storageKey) private var unit: DistanceUnit = .km
    @AppStorage(Currency.key) private var currency = Currency.defaultCode

    let vehicle: Vehicle
    let record: ServiceRecord?
    private let lastCost: Double?
    private let initialOdometerText: String

    @State private var type: ServiceType
    @State private var date: Date
    @State private var odometerText: String
    @State private var costText: String
    @State private var place: String
    @State private var notes: String

    init(vehicle: Vehicle, record: ServiceRecord? = nil, template: ServiceRecord? = nil) {
        self.vehicle = vehicle
        self.record = record
        let source = record ?? template
        let unit = DistanceUnit(rawValue: UserDefaults.standard.string(forKey: DistanceUnit.storageKey) ?? "") ?? .km
        let odometer = record?.odometerKm.map { String(Int(unit.fromKm($0).rounded())) } ?? ""

        self.lastCost = template?.cost
        self.initialOdometerText = odometer
        _type = State(initialValue: source?.type ?? .oilChange)
        _date = State(initialValue: record?.date ?? Calendar.current.startOfDay(for: Date()))
        _odometerText = State(initialValue: odometer)
        _costText = State(initialValue: record.map { $0.cost > 0 ? Self.plain($0.cost) : "" } ?? "")
        _place = State(initialValue: source?.place ?? "")
        _notes = State(initialValue: source?.allNotes ?? "")
    }

    private static func plain(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(0...2)).grouping(.never))
    }

    private var lastReadingKm: Double? {
        ServiceSummary.currentOdometerKm((vehicle.records ?? []).filter { $0.uuid != record?.uuid })
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("What did you get done?") {
                    Picker(selection: $type) {
                        ForEach(ServiceType.allCases) { t in
                            Label {
                                Text(t.title)
                            } icon: {
                                TypeIcon(type: t, size: 30)
                            }
                            .tag(t)
                        }
                    } label: {
                        Text("Service")
                    }
                    .pickerStyle(.navigationLink)
                }

                Section {
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                    HStack {
                        Text("Serviced odo")
                        TextField("0", text: $odometerText)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                        Text(unit.rawValue).foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("Price")
                        TextField(lastCost.map { "Last: \(Self.plain($0))" } ?? "0.00", text: $costText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                        Text(currency).foregroundStyle(.secondary)
                    }
                    TextField("Where (shop, dealer, your driveway)", text: $place)
                } footer: {
                    if let km = lastReadingKm {
                        Text("Your last serviced odo was \(unit.format(km: km)).")
                    }
                }

                Section {
                    TextField(type.notesPrompt, text: $notes, axis: .vertical)
                        .lineLimit(3...8)
                } header: {
                    Text("Notes")
                } footer: {
                    Text("What was done, what you used, anything you'll want to know next time.")
                }
            }
            .navigationTitle(record == nil ? "Log service" : "Edit service")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save).bold()
                }
            }
        }
    }

    private func save() {
        let target: ServiceRecord
        if let record {
            target = record
        } else {
            target = ServiceRecord(type: type)
            context.insert(target)
            target.vehicle = vehicle
        }

        target.type = type
        target.date = date
        if record == nil || odometerText != initialOdometerText {
            target.odometerKm = ServiceSummary.parseNumber(odometerText).map { unit.toKm($0) }
        }
        target.cost = ServiceSummary.parseNumber(costText) ?? 0
        target.place = place.trimmingCharacters(in: .whitespacesAndNewlines)
        target.workDone = ""
        target.partsUsed = ""
        target.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        try? context.save()
        dismiss()
    }
}
