import SwiftUI
import SwiftData

struct RecordDetailView: View {
    let record: ServiceRecord

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @AppStorage(DistanceUnit.storageKey) private var unit: DistanceUnit = .km
    @AppStorage(Currency.key) private var currency = Currency.defaultCode
    @State private var editing = false
    @State private var repeating = false
    @State private var confirmDelete = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(spacing: 10) {
                    TypeIcon(type: record.type, size: 72)
                        .shadow(color: record.type.tint.opacity(0.35), radius: 14, y: 6)
                    Text(record.type.title)
                        .font(.title.bold())
                    Text(record.date.formatted(.dateTime.weekday(.wide).month(.wide).day().year().hour().minute()))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 8)

                HStack(spacing: 12) {
                    statCard("Odometer", record.odometerKm.map { unit.format(km: $0) } ?? "Not logged")
                    statCard("Price", record.cost > 0 ? Currency.format(record.cost, code: currency) : "Free")
                }

                VStack(spacing: 0) {
                    detail("Where", record.place, icon: "mappin.and.ellipse")
                    detail("What was done", record.workDone, icon: "wrench.adjustable")
                    detail("What you used", record.partsUsed, icon: "shippingbox")
                    detail("Notes", record.notes, icon: "note.text")
                }
                .card()

                VStack(spacing: 12) {
                    Button { repeating = true } label: {
                        Label("Log this again", systemImage: "arrow.clockwise")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                    }
                    .buttonStyle(.borderedProminent)
                    .buttonBorderShape(.capsule)
                    .controlSize(.large)

                    Text("Starts a new entry with the same shop and parts filled in.")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Button("Delete this entry", role: .destructive) { confirmDelete = true }
                        .font(.subheadline)
                        .padding(.top, 8)
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            Button("Edit") { editing = true }
        }
        .sheet(isPresented: $editing) {
            if let vehicle = record.vehicle {
                RecordFormView(vehicle: vehicle, record: record)
            }
        }
        .sheet(isPresented: $repeating) {
            if let vehicle = record.vehicle {
                RecordFormView(vehicle: vehicle, template: record)
            }
        }
        .confirmationDialog("Delete this \(record.type.title.lowercased())?", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("Delete", role: .destructive, action: delete)
        } message: {
            Text("You can't undo this.")
        }
    }

    private func statCard(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption.weight(.semibold))
                .textCase(.uppercase)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title3.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .card()
    }

    @ViewBuilder
    private func detail(_ label: String, _ value: String, icon: String) -> some View {
        if !value.isEmpty {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: icon)
                    .font(.body)
                    .foregroundStyle(record.type.tint)
                    .frame(width: 24)
                VStack(alignment: .leading, spacing: 4) {
                    Text(label)
                        .font(.caption.weight(.semibold))
                        .textCase(.uppercase)
                        .foregroundStyle(.secondary)
                    Text(value)
                        .font(.body)
                        .textSelection(.enabled)
                }
                Spacer(minLength: 0)
            }
            .padding(16)
        }
    }

    private func delete() {
        let target = record
        let ctx = context
        dismiss()
        // Delete after the pop animation so the view never reads a deleted object.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            ctx.delete(target)
            try? ctx.save()
        }
    }
}
