import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var viewModel: AppViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var keyDraft = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    SecureField("AirNow API key", text: $keyDraft)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    Link("Get a free key from airnowapi.org",
                         destination: URL(string: "https://docs.airnowapi.org/account/request/")!)
                } header: {
                    Text("AirNow Account")
                } footer: {
                    Text("AirNow issues each user their own key, and the rate limit belongs to that key. The key is stored on this device only and is sent to airnowapi.org and nowhere else.")
                }

                Section {
                    Picker("Check for updates", selection: Binding(
                        get: { viewModel.interval },
                        set: { viewModel.interval = $0 }
                    )) {
                        ForEach(RefreshInterval.allCases) { interval in
                            Text(interval.label).tag(interval)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                } header: {
                    Text("Update Schedule")
                } footer: {
                    Text("USAirQMinder checks for a new reading on this schedule while the app is open, and every time you return to it. AirNow publishes new observations once an hour.")
                }

                Section("About") {
                    LabeledContent("Data source", value: "EPA AirNow")
                    Link("About the Air Quality Index",
                         destination: URL(string: "https://www.airnow.gov/aqi/aqi-basics/")!)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        let trimmed = keyDraft.trimmingCharacters(in: .whitespacesAndNewlines)
                        let changed = trimmed != viewModel.apiKey
                        viewModel.apiKey = trimmed
                        dismiss()
                        // A newly entered key is the thing standing between the
                        // user and a reading, so use it straight away.
                        if changed && !trimmed.isEmpty {
                            Task { await viewModel.refresh() }
                        }
                    }
                }
            }
            .onAppear { keyDraft = viewModel.apiKey }
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppViewModel())
}
