import Foundation
import SwiftUI

@MainActor
final class AppViewModel: ObservableObject {
    @Published var reading: AQIReading?
    @Published var errorMessage: String?
    @Published var isLoading = false
    @Published var lastChecked: Date?

    @AppStorage("refreshInterval") private var intervalRaw = RefreshInterval.thirtyMinutes.rawValue
    @AppStorage(AQIService.apiKeyDefaultsKey) var apiKey = ""

    private let aqiService = AQIService()
    private let locationService = LocationService()
    private var timer: Timer?

    var interval: RefreshInterval {
        get { RefreshInterval(rawValue: intervalRaw) ?? .thirtyMinutes }
        set {
            intervalRaw = newValue.rawValue
            objectWillChange.send()
            scheduleTimer()
        }
    }

    var hasAPIKey: Bool {
        !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var nextCheck: Date? {
        lastChecked.map { $0.addingTimeInterval(interval.seconds) }
    }

    func refresh() async {
        isLoading = true
        errorMessage = nil
        do {
            let location = try await locationService.currentLocation()
            reading = try await aqiService.latestReading(near: location)
            lastChecked = Date()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    /// (Re)start the periodic check using the user's chosen interval.
    /// Fires while the app is running; a fresh check also happens every
    /// time the app returns to the foreground.
    func scheduleTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: interval.seconds, repeats: true) { [weak self] _ in
            Task { await self?.refresh() }
        }
    }

    deinit {
        timer?.invalidate()
    }
}
