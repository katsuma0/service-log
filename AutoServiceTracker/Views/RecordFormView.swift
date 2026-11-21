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
    @State private var workDone: String
    @State private var partsUsed: String
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
        _date = State(initialValue: record?.date ?? Date())
        _odometerText = State(initialValue: odometer)
        _costText = State(initialValue: record.map { $0.cost > 0 ? Self.plain($0.cost) : "" } ?? "")
        _place = State(initialValue: source?.place ?? "")
        _workDone = State(initialValue: source?.workDone ?? "")
        _partsUsed = State(initialValue: source?.partsUsed ?? "")
        _notes = State(initialValue: record?.notes ?? "")
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
                    typePicker
                        .listRowInsets(EdgeInsets(top: 12, leading: 0, bottom: 12, trailing: 0))
                }

                Section {
                    DatePicker("When", selection: $date)
                    HStack {
                        Text("Odometer")
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
                        Text("Your last logged reading was \(unit.format(km: km)).")
                    }
                }

                Section("What was done") {
                    TextField("e.g. Synthetic oil change, topped up washer fluid", text: $workDone, axis: .vertical)
                        .lineLimit(2...6)
                }

                Section {
                    TextField(type.partsPrompt, text: $partsUsed, axis: .vertical)
                        .lineLimit(2...6)
                } header: {
                    Text("What you used")
                } footer: {
                    Text("This is the part you'll want next time, so be specific.")
                }

                Section("Notes") {
                    TextField("Warranty, next due, anything else", text: $notes, axis: .vertical)
                        .lineLimit(1...6)
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

    private var typePicker: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    ForEach(ServiceType.allCases) { t in
                        Button {
                            withAnimation(.snappy) { type = t }
                        } label: {
                            VStack(spacing: 6) {
                                TypeIcon(type: t, size: 48, muted: type != t)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 48 * 0.3 + 3, style: .continuous)
                                            .strokeBorder(t.tint, lineWidth: type == t ? 2 : 0)
                                            .padding(-3)
                                    )
                                Text(t.title)
                                    .font(.caption)
                                    .fontWeight(type == t ? .semibold : .regular)
                                    .foregroundStyle(type == t ? Color.primary : Color.secondary)
                                    .lineLimit(1)
                            }
                            .frame(width: 80)
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(.plain)
                        .id(t)
                    }
                }
                .padding(.horizontal, 12)
            }
            .onAppear { proxy.scrollTo(type, anchor: .center) }
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
        target.workDone = workDone.trimmingCharacters(in: .whitespacesAndNewlines)
        target.partsUsed = partsUsed.trimmingCharacters(in: .whitespacesAndNewlines)
        target.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        try? context.save()
        dismiss()
    }
}
