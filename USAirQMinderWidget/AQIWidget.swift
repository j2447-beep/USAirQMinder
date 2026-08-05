import WidgetKit
import SwiftUI
import CoreLocation

// The widget is self-contained: it fetches its own location and reading so it
// can refresh in the background without the app running. NSWidgetWantsLocation
// in Info.plist lets it reuse the location permission granted to the app, and
// the App Group lets it read the AirNow key the app stored.

@main
struct USAirQMinderWidgetBundle: WidgetBundle {
    var body: some Widget {
        AQIWidget()
    }
}

struct AQIWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "AQIWidget", provider: AQIProvider()) { entry in
            AQIWidgetView(entry: entry)
                .containerBackground(for: .widget) {
                    // Same gradient and air waves as the app icon
                    ZStack {
                        LinearGradient(
                            colors: [
                                Color(red: 0.04, green: 0.23, blue: 0.42),
                                Color(red: 0.05, green: 0.52, blue: 0.66),
                            ],
                            startPoint: .top, endPoint: .bottom
                        )
                        WaveLine(position: 0.80)
                            .stroke(.white.opacity(0.85), style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        WaveLine(position: 0.88)
                            .stroke(.white.opacity(0.45), style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        WaveLine(position: 0.96)
                            .stroke(.white.opacity(0.18), style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    }
                }
        }
        .configurationDisplayName("Air Quality")
        .description("The latest EPA Air Quality Index near you.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Timeline

struct AQIEntry: TimelineEntry {
    let date: Date
    let aqi: Int?
    let areaName: String
    let pollutant: String
    let observedAt: Date?
    /// Set when the reason for having no reading is a missing key, so the
    /// widget can say what to do rather than just showing a dash.
    let needsKey: Bool

    static let placeholder = AQIEntry(date: .now, aqi: 42, areaName: "Your area",
                                      pollutant: "PM2.5", observedAt: .now, needsKey: false)
    static let unavailable = AQIEntry(date: .now, aqi: nil, areaName: "",
                                      pollutant: "", observedAt: nil, needsKey: false)
    static let keyMissing = AQIEntry(date: .now, aqi: nil, areaName: "",
                                     pollutant: "", observedAt: nil, needsKey: true)
}

struct AQIProvider: TimelineProvider {
    func placeholder(in context: Context) -> AQIEntry { .placeholder }

    func getSnapshot(in context: Context, completion: @escaping (AQIEntry) -> Void) {
        if context.isPreview {
            completion(.placeholder)
            return
        }
        Task { completion(await fetchEntry()) }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<AQIEntry>) -> Void) {
        Task {
            let entry = await fetchEntry()
            // AirNow publishes hourly; ask iOS to refresh roughly twice an hour.
            let next = Date().addingTimeInterval(30 * 60)
            completion(Timeline(entries: [entry], policy: .after(next)))
        }
    }

    private func fetchEntry() async -> AQIEntry {
        guard !SharedDefaults.apiKey.isEmpty else { return .keyMissing }
        do {
            let location = try await withTimeout(seconds: 8) { try await WidgetLocation().current() }
            let entry = try await withTimeout(seconds: 10) { try await fetchNearestReading(location: location) }
            EntryCache.save(entry)
            return entry
        } catch {
            // Fall back to the last good reading (if reasonably fresh) so a
            // momentary location/network failure doesn't blank the widget.
            return EntryCache.load() ?? .unavailable
        }
    }

    private func fetchNearestReading(location: CLLocation) async throws -> AQIEntry {
        let key = SharedDefaults.apiKey
        var components = URLComponents(string: "https://www.airnowapi.org/aq/observation/latLong/current/")!
        components.queryItems = [
            URLQueryItem(name: "format", value: "application/json"),
            URLQueryItem(name: "latitude", value: String(location.coordinate.latitude)),
            URLQueryItem(name: "longitude", value: String(location.coordinate.longitude)),
            URLQueryItem(name: "distance", value: "75"),
            URLQueryItem(name: "API_KEY", value: key),
        ]

        let (data, _) = try await URLSession.shared.data(from: components.url!)
        let observations = (try? JSONDecoder().decode([AirNowObservation].self, from: data)) ?? []

        // Same rule as the app: the reported AQI is the worst pollutant's.
        guard let worst = observations.filter({ $0.aqi >= 0 }).max(by: { $0.aqi < $1.aqi }) else {
            return .unavailable
        }
        return AQIEntry(
            date: .now,
            aqi: worst.aqi,
            areaName: worst.reportingArea,
            pollutant: worst.parameterName,
            observedAt: worst.observedAt,
            needsKey: false
        )
    }
}

/// Runs an async operation with a hard timeout so the widget timeline can
/// never hang indefinitely (a stuck timeline leaves the widget showing its
/// placeholder skeleton forever).
private func withTimeout<T: Sendable>(seconds: Double, _ operation: @escaping @Sendable () async throws -> T) async throws -> T {
    try await withThrowingTaskGroup(of: T.self) { group in
        group.addTask { try await operation() }
        group.addTask {
            try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
            throw CancellationError()
        }
        let result = try await group.next()!
        group.cancelAll()
        return result
    }
}

/// Last successful reading, kept so the widget can show something useful
/// when a refresh fails.
enum EntryCache {
    private static let key = "lastEntry"
    private static let maxAge: TimeInterval = 6 * 60 * 60

    static func save(_ entry: AQIEntry) {
        guard let aqi = entry.aqi, let observedAt = entry.observedAt else { return }
        SharedDefaults.store.set(
            [
                "aqi": aqi,
                "area": entry.areaName,
                "pollutant": entry.pollutant,
                "observedAt": observedAt.timeIntervalSince1970,
            ] as [String: Any],
            forKey: key
        )
    }

    static func load() -> AQIEntry? {
        guard let dict = SharedDefaults.store.dictionary(forKey: key),
              let aqi = dict["aqi"] as? Int,
              let area = dict["area"] as? String,
              let observedTs = dict["observedAt"] as? Double else { return nil }
        let observedAt = Date(timeIntervalSince1970: observedTs)
        guard Date().timeIntervalSince(observedAt) < maxAge else { return nil }
        return AQIEntry(
            date: .now,
            aqi: aqi,
            areaName: area,
            pollutant: dict["pollutant"] as? String ?? "",
            observedAt: observedAt,
            needsKey: false
        )
    }
}

/// One-shot location fix for the widget process. CLLocationManager must be
/// created and used on a thread with a run loop, so this is main-actor bound —
/// off the main thread its delegate callbacks may never fire.
@MainActor
final class WidgetLocation: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private var continuation: CheckedContinuation<CLLocation, Error>?

    func current() async throws -> CLLocation {
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            manager.requestLocation()
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location = locations.last
        Task { @MainActor in
            self.continuation?.resume(returning: location ?? CLLocation())
            self.continuation = nil
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            self.continuation?.resume(throwing: error)
            self.continuation = nil
        }
    }
}

/// One flowing air-wave line, matching the app icon. `position` is the
/// vertical placement as a fraction of the widget height.
struct WaveLine: Shape {
    let position: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let y = rect.height * position
        path.move(to: CGPoint(x: rect.width * 0.08, y: y))
        path.addCurve(
            to: CGPoint(x: rect.width * 0.92, y: y),
            control1: CGPoint(x: rect.width * 0.36, y: y + rect.height * 0.035),
            control2: CGPoint(x: rect.width * 0.64, y: y - rect.height * 0.035)
        )
        return path
    }
}

// MARK: - View

struct AQIWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: AQIEntry

    /// Brightened variants of the EPA colors, for contrast against the
    /// widget's dark gradient background. The published colors are chosen
    /// for white backgrounds and several go muddy on navy.
    private var color: Color {
        guard let aqi = entry.aqi else { return .white.opacity(0.7) }
        switch AQICategory(aqi: aqi) {
        case .good: return Color(red: 0.40, green: 0.95, blue: 0.55)
        case .moderate: return Color(red: 1.00, green: 0.93, blue: 0.35)
        case .unhealthySensitive: return Color(red: 1.00, green: 0.66, blue: 0.35)
        case .unhealthy: return Color(red: 1.00, green: 0.45, blue: 0.42)
        case .veryUnhealthy: return Color(red: 0.80, green: 0.55, blue: 0.95)
        case .hazardous: return Color(red: 1.00, green: 0.35, blue: 0.45)
        }
    }

    private var categoryLabel: String {
        guard let aqi = entry.aqi else { return "" }
        let category = AQICategory(aqi: aqi)
        // The full name doesn't fit a small widget.
        return category == .unhealthySensitive ? "Sensitive Groups" : category.label
    }

    private var displayValue: String {
        guard let aqi = entry.aqi else { return "–" }
        return String(aqi)
    }

    var body: some View {
        if entry.needsKey {
            VStack(spacing: 6) {
                Image(systemName: "key").font(.title2).foregroundStyle(.white.opacity(0.65))
                Text("Add your AirNow key in USAirQMinder")
                    .font(.caption2)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white.opacity(0.65))
            }
        } else if entry.aqi == nil {
            VStack(spacing: 6) {
                Image(systemName: "aqi.medium").font(.title2).foregroundStyle(.white.opacity(0.65))
                Text("Open USAirQMinder to update")
                    .font(.caption2)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white.opacity(0.65))
            }
        } else if family == .systemSmall {
            VStack(spacing: 2) {
                Text(displayValue)
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .foregroundStyle(color)
                Text("AQI")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.65))
                Text(categoryLabel)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(color)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Text(entry.areaName)
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.65))
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        } else {
            HStack(spacing: 16) {
                VStack(spacing: 0) {
                    Text(displayValue)
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundStyle(color)
                    Text("AQI")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.65))
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(categoryLabel)
                        .font(.headline)
                        .foregroundStyle(color)
                    Text(entry.areaName)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.65))
                    if !entry.pollutant.isEmpty {
                        Text("Driven by \(entry.pollutant)")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.65))
                    }
                    if let observed = entry.observedAt {
                        Text("Observed \(observed.formatted(date: .omitted, time: .shortened))")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.65))
                    }
                }
                Spacer()
            }
            .padding(.horizontal, 4)
            .frame(maxHeight: .infinity, alignment: .top)
        }
    }
}
