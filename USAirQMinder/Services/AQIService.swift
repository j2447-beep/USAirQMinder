import Foundation
import CoreLocation

enum AQIError: LocalizedError {
    case missingKey
    case unauthorized
    case badResponse
    case noStations

    var errorDescription: String? {
        switch self {
        case .missingKey:
            return "Add your AirNow API key in Settings to see local air quality. Keys are free from airnowapi.org."
        case .unauthorized:
            return "AirNow rejected the API key. Check it in Settings, or request a new one from airnowapi.org."
        case .badResponse:
            return "Could not reach the AirNow air quality service."
        case .noStations:
            return "No AirNow reporting area found near you. Readings are available for locations in the United States."
        }
    }
}

/// Fetches current AQI observations from the EPA's AirNow API.
///
/// AirNow is the EPA's real-time feed: hourly observations, queryable by
/// latitude and longitude, which is what a "what am I breathing right now"
/// app needs. Its sibling, the AQS API, holds the quality-assured regulatory
/// archive instead — it requires an explicit date range and its data lags by
/// months, so it answers a different question entirely.
struct AQIService {
    /// Where the user's AirNow key is kept. Not a secret worth protecting
    /// from the device's owner — it is their own key, rate-limited to them.
    static let apiKeyDefaultsKey = "airNowAPIKey"

    var apiKey: String {
        UserDefaults.standard.string(forKey: Self.apiKeyDefaultsKey)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    /// Returns the dominant pollutant's reading for the reporting area
    /// nearest `location`, searching outwards until something is found.
    func latestReading(near location: CLLocation) async throws -> AQIReading {
        let key = apiKey
        guard !key.isEmpty else { throw AQIError.missingKey }

        // AirNow matches a location to a reporting area within this radius.
        // Cities hit on the first try; somewhere remote needs a wider net,
        // so widen rather than tell someone there is no data.
        for distanceMiles in [25, 75, 150] {
            let observations = try await fetch(near: location, distanceMiles: distanceMiles, key: key)
            if let reading = Self.dominantReading(from: observations, near: location) {
                return reading
            }
        }
        throw AQIError.noStations
    }

    private func fetch(near location: CLLocation, distanceMiles: Int, key: String) async throws -> [AirNowObservation] {
        var components = URLComponents(string: "https://www.airnowapi.org/aq/observation/latLong/current/")!
        components.queryItems = [
            URLQueryItem(name: "format", value: "application/json"),
            URLQueryItem(name: "latitude", value: String(location.coordinate.latitude)),
            URLQueryItem(name: "longitude", value: String(location.coordinate.longitude)),
            URLQueryItem(name: "distance", value: String(distanceMiles)),
            URLQueryItem(name: "API_KEY", value: key),
        ]

        let (data, response) = try await URLSession.shared.data(from: components.url!)
        guard let http = response as? HTTPURLResponse else { throw AQIError.badResponse }
        switch http.statusCode {
        case 200: break
        case 401, 403: throw AQIError.unauthorized
        default: throw AQIError.badResponse
        }

        // An area with no data returns an empty array rather than an error.
        return (try? JSONDecoder().decode([AirNowObservation].self, from: data)) ?? []
    }

    /// The reported AQI is the worst pollutant's, which is the one the health
    /// advice is written about. The rest are kept to show alongside it.
    static func dominantReading(from observations: [AirNowObservation], near location: CLLocation) -> AQIReading? {
        let usable = observations.filter { $0.aqi >= 0 }
        guard let worst = usable.max(by: { $0.aqi < $1.aqi }) else { return nil }

        let stationLocation = CLLocation(latitude: worst.latitude, longitude: worst.longitude)
        let distance = location.distance(from: stationLocation)

        return AQIReading(
            reportingArea: worst.reportingArea,
            stateCode: worst.stateCode,
            parameterName: worst.parameterName,
            aqi: worst.aqi,
            observedAt: worst.observedAt,
            latitude: worst.latitude,
            longitude: worst.longitude,
            distanceKm: distance / 1000,
            allPollutants: usable
                .sorted { $0.aqi > $1.aqi }
                .map { (name: $0.parameterName, aqi: $0.aqi) }
        )
    }
}
