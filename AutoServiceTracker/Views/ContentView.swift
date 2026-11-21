import SwiftUI
import SwiftData

struct ContentView: View {
    @Query(sort: \Vehicle.createdAt) private var vehicles: [Vehicle]
    @AppStorage("selectedVehicleID") private var selectedID = ""
    @State private var showingAddVehicle = false

    private var selected: Vehicle? {
        vehicles.first { $0.uuid.uuidString == selectedID } ?? vehicles.first
    }

    var body: some View {
        NavigationStack {
            if let vehicle = selected {
                GarageView(vehicle: vehicle, vehicles: vehicles, selectedID: $selectedID)
            } else {
                WelcomeView { showingAddVehicle = true }
            }
        }
        .sheet(isPresented: $showingAddVehicle) {
            VehicleFormView(vehicle: nil) { selectedID = $0.uuid.uuidString }
        }
    }
}

private struct WelcomeView: View {
    var onAdd: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "car.fill")
                .font(.system(size: 56, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 120, height: 120)
                .background(Color.accentColor.gradient, in: RoundedRectangle(cornerRadius: 32, style: .continuous))
                .shadow(color: .accentColor.opacity(0.35), radius: 20, y: 10)
            VStack(spacing: 8) {
                Text("Your car's memory")
                    .font(.largeTitle.bold())
                Text("Log every oil change, tire swap and repair. Next time you're at the shop, you'll know exactly what you used and what you paid.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            Spacer()
            Button(action: onAdd) {
                Text("Add your car")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Vehicle.self, ServiceRecord.self], inMemory: true)
}
