import Foundation
import CoreLocation
import SwiftUI

/// One air quality reading for a point on the map.
///
/// The US AQI is defined per pollutant (ozone, PM2.5, PM10 and the rest); the
/// figure people are shown as "the AQI" is the highest of them, and the
/// pollutant carrying it is the dominant one — that is what this holds.
///
/// Note what this deliberately does *not* have: a station, a reporting area,
/// or a distance to one. The numbers come from a model evaluated at the user's
/// coordinates (see `OpenMeteoClient`), so there is no monitor to be near and
/// nothing would be true about how far away it is.
struct AQIReading: Equatable {
    /// Best-effort place name from on-device reverse geocoding. May be empty:
    /// it is a label for the user's own coordinates, not part of the reading,
    /// so failing to get one is never worth surfacing as an error.
    let placeName: String
    /// The pollutant responsible for this AQI, e.g. "PM2.5" or "O3".
    let parameterName: String
    let aqi: Int
    /// The hour the model output applies to.
    let modelledAt: Date
    /// Every pollutant the model returned, highest AQI first.
    let allPollutants: [(name: String, aqi: Int)]

    static func == (lhs: AQIReading, rhs: AQIReading) -> Bool {
        lhs.placeName == rhs.placeName
            && lhs.aqi == rhs.aqi
            && lhs.parameterName == rhs.parameterName
            && lhs.modelledAt == rhs.modelledAt
    }

    var displayValue: String { String(aqi) }

    var location: String {
        placeName.isEmpty ? "Your location" : placeName
    }

    var category: AQICategory { AQICategory(aqi: aqi) }
}

/// The EPA's six AQI bands, with their official colors and health messages.
enum AQICategory {
    case good                 // 0–50
    case moderate             // 51–100
    case unhealthySensitive   // 101–150
    case unhealthy            // 151–200
    case veryUnhealthy        // 201–300
    case hazardous            // 301+

    init(aqi: Int) {
        switch aqi {
        case ..<51:  self = .good
        case ..<101: self = .moderate
        case ..<151: self = .unhealthySensitive
        case ..<201: self = .unhealthy
        case ..<301: self = .veryUnhealthy
        default:     self = .hazardous
        }
    }

    var label: String {
        switch self {
        case .good: return "Good"
        case .moderate: return "Moderate"
        case .unhealthySensitive: return "Unhealthy for Sensitive Groups"
        case .unhealthy: return "Unhealthy"
        case .veryUnhealthy: return "Very Unhealthy"
        case .hazardous: return "Hazardous"
        }
    }

    /// The EPA's guidance for each band.
    var advice: String {
        switch self {
        case .good:
            return "Air quality is satisfactory, and air pollution poses little or no risk."
        case .moderate:
            return "Air quality is acceptable. There may be a risk for people who are unusually sensitive to air pollution."
        case .unhealthySensitive:
            return "Members of sensitive groups may experience health effects. The general public is less likely to be affected."
        case .unhealthy:
            return "Some members of the general public may experience health effects; members of sensitive groups may experience more serious effects."
        case .veryUnhealthy:
            return "Health alert: the risk of health effects is increased for everyone."
        case .hazardous:
            return "Health warning of emergency conditions: everyone is more likely to be affected."
        }
    }

    /// The EPA's published AQI colors.
    var color: Color {
        switch self {
        case .good: return Color(red: 0.00, green: 0.90, blue: 0.25)
        case .moderate: return Color(red: 1.00, green: 1.00, blue: 0.00)
        case .unhealthySensitive: return Color(red: 1.00, green: 0.50, blue: 0.15)
        case .unhealthy: return Color(red: 1.00, green: 0.00, blue: 0.00)
        case .veryUnhealthy: return Color(red: 0.56, green: 0.24, blue: 0.66)
        case .hazardous: return Color(red: 0.50, green: 0.00, blue: 0.15)
        }
    }

    /// Yellow on white is unreadable, so text uses this instead of `color`.
    var textColor: Color {
        self == .moderate ? Color(red: 0.72, green: 0.60, blue: 0.00) : color
    }

    /// The top of this band, for drawing the dial. Hazardous runs to 500.
    var upperBound: Double {
        switch self {
        case .good: return 50
        case .moderate: return 100
        case .unhealthySensitive: return 150
        case .unhealthy: return 200
        case .veryUnhealthy: return 300
        case .hazardous: return 500
        }
    }
}

/// How often the app checks for a new reading.
enum RefreshInterval: String, CaseIterable, Identifiable {
    case fiveMinutes
    case thirtyMinutes
    case twelveHours
    case daily

    var id: String { rawValue }

    var label: String {
        switch self {
        case .fiveMinutes: return "Every 5 minutes"
        case .thirtyMinutes: return "Every 30 minutes"
        case .twelveHours: return "Every 12 hours"
        case .daily: return "Once a day"
        }
    }

    var seconds: TimeInterval {
        switch self {
        case .fiveMinutes: return 5 * 60
        case .thirtyMinutes: return 30 * 60
        case .twelveHours: return 12 * 60 * 60
        case .daily: return 24 * 60 * 60
        }
    }
}

// MARK: - Errors

enum AQIError: LocalizedError {
    case rateLimited
    case badResponse
    case noData

    var errorDescription: String? {
        switch self {
        case .rateLimited:
            return "The air quality service is busy right now. It limits how often it can be asked — try again shortly."
        case .badResponse:
            return "Could not reach the air quality service."
        case .noData:
            return "No air quality figures are available for your location right now."
        }
    }
}

// MARK: - Open-Meteo

/// Fetches the US AQI from Open-Meteo's air quality API.
///
/// Shared by the app and the widget, which is why it lives here rather than in
/// `AQIService` — `AQI.swift` is a member of both targets and adding a new file
/// would mean hand-editing the project Xcode owns.
///
/// **What this data is.** Open-Meteo serves the Copernicus Atmosphere
/// Monitoring Service (CAMS) forecasts. Outside Europe that is the global
/// model, which the docs give as ~0.4°/44 km reissued twice daily (the served
/// grid snaps finer than that, so it is presumably interpolated — don't quote a
/// resolution figure at the user). Values step hourly. It is model output, not
/// a monitor reading — nothing here comes off an EPA instrument.
/// What *is* the EPA's is the scale: `us_aqi_*` applies the EPA's published AQI
/// breakpoints to the modelled concentrations, so the numbers and the six
/// categories mean what they mean on airnow.gov even though their provenance
/// differs. Copy in the UI needs to keep saying "modelled", never "observed".
///
/// No API key, by design — that is the whole reason for preferring it. Free for
/// non-commercial use, and the licence requires visible attribution to both
/// CAMS and Open-Meteo, which `Attribution.text` carries into the UI.
enum OpenMeteoClient {
    static let attributionURL = URL(string: "https://open-meteo.com/")!

    /// Required by Open-Meteo's terms — both names, wherever a reading shows.
    static let attribution = "CAMS via Open-Meteo"

    /// The per-pollutant US AQI variables, paired with the short names the UI
    /// shows. Ordering here is only the request order; display sorts by value.
    private static let pollutants: [(variable: String, name: String)] = [
        ("us_aqi_pm2_5", "PM2.5"),
        ("us_aqi_pm10", "PM10"),
        ("us_aqi_ozone", "O3"),
        ("us_aqi_nitrogen_dioxide", "NO2"),
        ("us_aqi_sulphur_dioxide", "SO2"),
        ("us_aqi_carbon_monoxide", "CO"),
    ]

    static func reading(at coordinate: CLLocationCoordinate2D, placeName: String = "") async throws -> AQIReading {
        var components = URLComponents(string: "https://air-quality-api.open-meteo.com/v1/air-quality")!
        components.queryItems = [
            URLQueryItem(name: "latitude", value: String(coordinate.latitude)),
            URLQueryItem(name: "longitude", value: String(coordinate.longitude)),
            URLQueryItem(name: "current", value: (["us_aqi"] + pollutants.map(\.variable)).joined(separator: ",")),
            // Epoch seconds rather than the default ISO strings, which come
            // back without a zone offset and have to be guessed at.
            URLQueryItem(name: "timeformat", value: "unixtime"),
        ]

        let (data, response) = try await URLSession.shared.data(from: components.url!)
        guard let http = response as? HTTPURLResponse else { throw AQIError.badResponse }
        switch http.statusCode {
        case 200: break
        // Open-Meteo's free tier is fair-use limited rather than keyed. Saying
        // so beats "could not reach the service", which sends people looking at
        // their network when the service answered and said "not so fast".
        case 429: throw AQIError.rateLimited
        default: throw AQIError.badResponse
        }

        guard let decoded = try? JSONDecoder().decode(Response.self, from: data) else {
            throw AQIError.badResponse
        }
        guard let reading = decoded.reading(placeName: placeName) else { throw AQIError.noData }
        return reading
    }

    /// The response, decoded loosely: every AQI value is optional because the
    /// model reports nothing for a pollutant it has no figure for, and a `null`
    /// in one field should not throw away the others.
    private struct Response: Decodable {
        let current: Current

        struct Current: Decodable {
            let time: Int
            /// Only the pollutants that came back with a figure. A `null` fails
            /// to decode as a number and is simply left out, which is exactly
            /// the wanted behaviour — absent and unreported are the same thing.
            let values: [String: Double]

            private struct Key: CodingKey {
                let stringValue: String
                var intValue: Int? { nil }
                init?(stringValue: String) { self.stringValue = stringValue }
                init?(intValue: Int) { return nil }
            }

            init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: Key.self)
                time = try container.decode(Int.self, forKey: Key(stringValue: "time")!)

                var values: [String: Double] = [:]
                for key in container.allKeys where key.stringValue.hasPrefix("us_aqi") {
                    if let value = try? container.decode(Double.self, forKey: key) {
                        values[key.stringValue] = value
                    }
                }
                self.values = values
            }
        }

        func reading(placeName: String) -> AQIReading? {
            let measured: [(name: String, aqi: Int)] = OpenMeteoClient.pollutants.compactMap { pollutant in
                guard let value = current.values[pollutant.variable] else { return nil }
                return (name: pollutant.name, aqi: Int(value.rounded()))
            }
            .sorted { $0.aqi > $1.aqi }

            let modelledAt = Date(timeIntervalSince1970: TimeInterval(current.time))

            // The headline is the worst sub-index, which is how the EPA defines
            // the AQI and guarantees the big number agrees with the pollutant
            // named under it. `us_aqi` is the same figure computed upstream and
            // stands in only if no sub-index came back at all.
            if let worst = measured.first {
                return AQIReading(
                    placeName: placeName,
                    parameterName: worst.name,
                    aqi: worst.aqi,
                    modelledAt: modelledAt,
                    allPollutants: measured
                )
            }
            guard let overall = current.values["us_aqi"] else { return nil }
            return AQIReading(
                placeName: placeName,
                parameterName: "",
                aqi: Int(overall.rounded()),
                modelledAt: modelledAt,
                allPollutants: []
            )
        }
    }
}

// MARK: - Place names

/// Turns coordinates into something like "Denver, CO" using Apple's on-device
/// geocoder, so the reading can say where it is for without a reporting area to
/// borrow a name from.
///
/// Always best-effort: a failure means the reading shows "Your location", never
/// an error. Nothing about the user's position goes anywhere new — this is the
/// same first-party API Maps uses.
enum PlaceNamer {
    static func name(for location: CLLocation) async -> String {
        guard let placemark = try? await CLGeocoder().reverseGeocodeLocation(location).first else {
            return ""
        }
        let locality = placemark.locality ?? placemark.subAdministrativeArea ?? ""
        guard let area = placemark.administrativeArea, !locality.isEmpty else { return locality }
        return "\(locality), \(area)"
    }
}
