import Foundation

/// The container the app and its widget both write to.
///
/// The widget runs in its own process with its own `UserDefaults`, so anything
/// the app stores is invisible to it without an App Group. It no longer holds
/// an API key — Open-Meteo needs none — but the widget still caches its last
/// good reading here so a failed refresh can fall back on it.
enum SharedDefaults {
    static let suiteName = "group.com.usairqminder.app"

    /// Falls back to `.standard` so a missing or misprovisioned App Group
    /// degrades to the widget keeping its own cache, rather than crashing.
    static let store: UserDefaults = UserDefaults(suiteName: suiteName) ?? .standard
}
