import Foundation
import CoreLocation

enum LocationError: LocalizedError {
    case denied
    case unavailable

    var errorDescription: String? {
        switch self {
        case .denied:
            return "Location access is off. Allow location for USAirQMinder in Settings to see your local air quality."
        case .unavailable:
            return "Could not determine your location. Please try again."
        }
    }
}

/// Small async wrapper around CLLocationManager: one call, one fix.
///
/// Five things can trigger a refresh — first appearance, returning to the
/// foreground, the timer, pull-to-refresh and the toolbar button — so calls
/// here genuinely do overlap, and a single stored continuation is not enough.
/// Callers are queued instead: whoever arrives first starts the request, the
/// rest wait on the same fix, and everyone is resumed exactly once.
///
/// `@MainActor` because CLLocationManager delivers its delegate callbacks on
/// the queue it was created on, and that is the main queue here. Isolating the
/// whole class makes the continuation bookkeeping single-threaded rather than
/// merely appearing to be.
@MainActor
final class LocationService: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()

    /// Everyone currently waiting on a fix. Resumed together, then emptied —
    /// so no continuation can be dropped by a later caller overwriting it.
    private var waiting: [CheckedContinuation<CLLocation, Error>] = []
    private var authWaiting: [CheckedContinuation<Void, Never>] = []
    private var timeoutTask: Task<Void, Never>?

    /// CoreLocation can accept requestLocation() and then never call back —
    /// notably with a simulated location that has not been set yet. Without a
    /// deadline the caller waits forever and the UI sits on its spinner.

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    func currentLocation() async throws -> CLLocation {
        if manager.authorizationStatus == .notDetermined {
            await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
                authWaiting.append(continuation)
                if authWaiting.count == 1 { manager.requestWhenInUseAuthorization() }
            }
        }

        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            break
        default:
            throw LocationError.denied
        }

        return try await withCheckedThrowingContinuation { continuation in
            waiting.append(continuation)
            guard waiting.count == 1 else { return }   // a request is already in flight
            startTimeout()
            manager.requestLocation()
        }
    }

    // MARK: - Resuming

    private func startTimeout() {
        timeoutTask?.cancel()
        timeoutTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(10))
            guard !Task.isCancelled else { return }
            self?.finish(.failure(LocationError.unavailable))
        }
    }

    /// The single exit point: resumes every waiter exactly once and clears the
    /// queue, so a late or duplicate delegate callback is a no-op.
    private func finish(_ result: Result<CLLocation, Error>) {
        timeoutTask?.cancel()
        timeoutTask = nil
        let waiters = waiting
        waiting = []
        for continuation in waiters {
            continuation.resume(with: result)
        }
    }

    // MARK: - CLLocationManagerDelegate

    // The delegate methods are `nonisolated` so the conformance does not cross
    // an actor boundary — that is a warning today and an error in Swift 6.
    // CLLocationManager delivers on the queue it was created on, which is the
    // main queue here, so asserting that isolation is accurate rather than a
    // convenient fiction.

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        MainActor.assumeIsolated {
            guard manager.authorizationStatus != .notDetermined else { return }
            let waiters = authWaiting
            authWaiting = []
            for continuation in waiters { continuation.resume() }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        MainActor.assumeIsolated {
            // An empty array would previously fall through and strand the caller.
            guard let location = locations.last else {
                finish(.failure(LocationError.unavailable))
                return
            }
            finish(.success(location))
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        MainActor.assumeIsolated {
            finish(.failure(LocationError.unavailable))
        }
    }
}
