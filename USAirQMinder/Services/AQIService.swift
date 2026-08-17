import Foundation
import CoreLocation

/// The app's entry point to an air quality reading.
///
/// The work is in `OpenMeteoClient`, which the widget shares. What lives here
/// is the app-side ordering: name the place first so the reading arrives with
/// somewhere to belong to, rather than appearing and then relabelling itself a
/// moment later.
struct AQIService {
    func latestReading(near location: CLLocation) async throws -> AQIReading {
        let placeName = await PlaceNamer.name(for: location)
        return try await OpenMeteoClient.reading(at: location.coordinate, placeName: placeName)
    }
}
