import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage(DistanceUnit.storageKey) private var unit: DistanceUnit = .km
    @AppStorage(Currency.key) private var currency = Currency.defaultCode

    private var currencies: [String] {
        Currency.common.contains(currency) ? Currency.common : [currency] + Currency.common
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Distance", selection: $unit) {
                        ForEach(DistanceUnit.allCases) { Text($0.label).tag($0) }
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text("Distance")
                } footer: {
                    Text("Switch any time. Your readings are converted, nothing gets lost.")
                }

                Section("Currency") {
                    Picker("Currency", selection: $currency) {
                        ForEach(currencies, id: \.self) { code in
                            Text("\(Currency.name(for: code)) (\(code))").tag(code)
                        }
                    }
                }

                Section {
                    LabeledContent("Version", value: Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0")
                } footer: {
                    Text("Everything stays on your device.")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
