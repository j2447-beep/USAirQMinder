import Foundation
import CoreLocation
import SwiftUI

/// One air quality reading from an AirNow reporting area.
///
/// AirNow reports a separate AQI per pollutant (ozone, PM2.5, PM10). The
/// figure people are shown as "the AQI" is the highest of them, and the
/// pollutant carrying it is the dominant one — that is what this holds.
struct AQIReading: Equatable {
    let reportingArea: String
    let stateCode: String
    /// The pollutant responsible for this AQI, e.g. "PM2.5" or "O3".
    let parameterName: String
    let aqi: Int
    let observedAt: Date
    let latitude: Double
    let longitude: Double
    let distanceKm: Double
    /// Every pollutant reported for this area, highest AQI first.
    let allPollutants: [(name: String, aqi: Int)]

    static func == (lhs: AQIReading, rhs: AQIReading) -> Bool {
        lhs.reportingArea == rhs.reportingArea
            && lhs.aqi == rhs.aqi
            && lhs.parameterName == rhs.parameterName
            && lhs.observedAt == rhs.observedAt
    }

    var displayValue: String { String(aqi) }

    var location: String {
        stateCode.isEmpty ? reportingArea : "\(reportingArea), \(stateCode)"
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

// MARK: - AirNow decoding

/// One observation as AirNow returns it. The API sends a flat array with one
/// entry per pollutant for the nearest reporting area.
struct AirNowObservation: Decodable {
    let dateObserved: String
    let hourObserved: Int
    let localTimeZone: String
    let reportingArea: String
    let stateCode: String
    let latitude: Double
    let longitude: Double
    let parameterName: String
    let aqi: Int
    let category: CategoryInfo

    struct CategoryInfo: Decodable {
        let number: Int
        let name: String

        enum CodingKeys: String, CodingKey {
            case number = "Number"
            case name = "Name"
        }
    }

    enum CodingKeys: String, CodingKey {
        case dateObserved = "DateObserved"
        case hourObserved = "HourObserved"
        case localTimeZone = "LocalTimeZone"
        case reportingArea = "ReportingArea"
        case stateCode = "StateCode"
        case latitude = "Latitude"
        case longitude = "Longitude"
        case parameterName = "ParameterName"
        case aqi = "AQI"
        case category = "Category"
    }

    /// AirNow gives the date and hour separately, in the reporting area's own
    /// time zone, and pads the date with a trailing space.
    var observedAt: Date {
        var components = DateComponents()
        let parts = dateObserved.trimmingCharacters(in: .whitespaces).split(separator: "-")
        guard parts.count == 3,
              let year = Int(parts[0]), let month = Int(parts[1]), let day = Int(parts[2]) else {
            return Date()
        }
        components.year = year
        components.month = month
        components.day = day
        components.hour = hourObserved

        var calendar = Calendar(identifier: .gregorian)
        // The abbreviation is the only zone information given, and it doesn't
        // always resolve. Falling back to the device's zone keeps the reading
        // usable rather than throwing it away over a label.
        calendar.timeZone = TimeZone(abbreviation: localTimeZone) ?? .current
        return calendar.date(from: components) ?? Date()
    }
}
