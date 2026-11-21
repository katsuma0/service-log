import SwiftUI
import SwiftData

@main
struct AutoServiceTrackerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [Vehicle.self, ServiceRecord.self])
    }
}
