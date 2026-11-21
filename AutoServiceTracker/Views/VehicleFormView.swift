import SwiftUI
import SwiftData

struct VehicleFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    let vehicle: Vehicle?
    var onSave: (Vehicle) -> Void

    @State private var name: String
    @State private var make: String
    @State private var modelName: String
    @State private var yearText: String
    @State private var plate: String
    @State private var confirmDelete = false

    init(vehicle: Vehicle?, onSave: @escaping (Vehicle) -> Void) {
        self.vehicle = vehicle
        self.onSave = onSave
        _name = State(initialValue: vehicle?.name ?? "")
        _make = State(initialValue: vehicle?.make ?? "")
        _modelName = State(initialValue: vehicle?.modelName ?? "")
        _yearText = State(initialValue: vehicle?.year.map(String.init) ?? "")
        _plate = State(initialValue: vehicle?.plate ?? "")
    }

    private var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Nickname, e.g. Daily driver", text: $name)
                } header: {
                    Text("Name")
                }

                Section("Details") {
                    TextField("Make, e.g. Toyota", text: $make)
                    TextField("Model, e.g. RAV4", text: $modelName)
                    TextField("Year", text: $yearText)
                        .keyboardType(.numberPad)
                    TextField("Plate (optional)", text: $plate)
                        .textInputAutocapitalization(.characters)
                }

                if vehicle != nil {
                    Section {
                        Button("Delete vehicle", role: .destructive) { confirmDelete = true }
                    } footer: {
                        Text("This also deletes every service you've logged for it.")
                    }
                }
            }
            .navigationTitle(vehicle == nil ? "Add vehicle" : "Edit vehicle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .bold()
                        .disabled(trimmedName.isEmpty)
                }
            }
            .confirmationDialog("Delete \(trimmedName)?", isPresented: $confirmDelete, titleVisibility: .visible) {
                Button("Delete vehicle and history", role: .destructive, action: delete)
            } message: {
                Text("You can't undo this.")
            }
        }
    }

    private func save() {
        let target = vehicle ?? {
            let v = Vehicle(name: trimmedName)
            context.insert(v)
            return v
        }()
        target.name = trimmedName
        target.make = make.trimmingCharacters(in: .whitespaces)
        target.modelName = modelName.trimmingCharacters(in: .whitespaces)
        target.year = Int(yearText.filter(\.isNumber))
        target.plate = plate.trimmingCharacters(in: .whitespaces)
        try? context.save()
        onSave(target)
        dismiss()
    }

    private func delete() {
        guard let vehicle else { return }
        let ctx = context
        dismiss()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            ctx.delete(vehicle)
            try? ctx.save()
        }
    }
}
