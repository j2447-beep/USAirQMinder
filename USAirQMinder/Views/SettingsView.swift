import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var viewModel: AppViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
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
                    Text("USAirQMinder checks for a new reading on this schedule while the app is open, and every time you return to it. The figures step hourly, so checking more often than that will usually return the same number.")
                }

                Section {
                    LabeledContent("Data source", value: OpenMeteoClient.attribution)
                    Link("About Open-Meteo", destination: OpenMeteoClient.attributionURL)
                    Link("About the Air Quality Index",
                         destination: URL(string: "https://www.airnow.gov/aqi/aqi-basics/")!)
                } header: {
                    Text("About")
                } footer: {
                    Text("Figures come from the Copernicus Atmosphere Monitoring Service (CAMS) global forecast, served by Open-Meteo. They are modelled for your coordinates — not measured at a monitoring station near you — so treat them as a guide to conditions in your area rather than an instrument reading. The index and its six categories follow the US EPA's published scale, but USAirQMinder is not affiliated with the EPA and these are not EPA measurements.")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppViewModel())
}
