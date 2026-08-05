import Foundation

/// Settings the app and its widget both need.
///
/// The widget runs in its own process with its own `UserDefaults`, so a key
/// typed into the app's settings is invisible to it. An App Group gives the
/// two a container they can both read — without one the widget would have no
/// way to reach AirNow at all. (AirQMinder's widget needs no key, which is
/// why it doesn't have this.)
enum SharedDefaults {
    static let suiteName = "group.com.usairqminder.app"

    /// Falls back to `.standard` so a missing or misprovisioned App Group
    /// degrades to the app still working on its own, rather than crashing.
    static let store: UserDefaults = UserDefaults(suiteName: suiteName) ?? .standard

    static let apiKeyKey = "airNowAPIKey"

    static var apiKey: String {
        store.string(forKey: apiKeyKey)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }
}
