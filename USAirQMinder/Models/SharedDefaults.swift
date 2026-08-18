import Foundation

/// The container the app and its widget both write to.
///
/// The widget runs in its own process with its own `UserDefaults`, so anything
/// the app stores is invisible to it without an App Group. It no longer holds
/// an API key — Open-Meteo needs none — but the widget still caches its last
/// good reading here so a failed refresh can fall back on it.
///
/// It also carries the access state: when the trial started, and whether the
/// unlock has been bought. The widget cannot run a purchase flow, so it reads
/// the decision rather than making one.
enum SharedDefaults {
    static let suiteName = "group.com.usairqminder.app"

    /// Falls back to `.standard` so a missing or misprovisioned App Group
    /// degrades to the widget keeping its own cache, rather than crashing.
    static let store: UserDefaults = UserDefaults(suiteName: suiteName) ?? .standard

    // MARK: - Access

    /// How long the app works before the unlock is required.
    static let trialDays = 14

    private static let trialStartKey = "trialStart"
    private static let unlockedKey = "isUnlocked"

    /// Set once, the first time the app runs, and never moved afterwards.
    /// Deliberately not reset on update — reinstalling is the only way to
    /// start over, which is the same bargain every trial makes.
    static var trialStart: Date {
        if let stored = store.object(forKey: trialStartKey) as? Date { return stored }
        let now = Date()
        store.set(now, forKey: trialStartKey)
        return now
    }

    /// Mirrored from StoreKit by `Store`. StoreKit remains authoritative; this
    /// exists so the widget can honour the entitlement without linking it.
    static var isUnlocked: Bool {
        get { store.bool(forKey: unlockedKey) }
        set { store.set(newValue, forKey: unlockedKey) }
    }

    static var trialDaysRemaining: Int {
        let elapsed = Calendar.current.dateComponents([.day], from: trialStart, to: Date()).day ?? 0
        return max(0, trialDays - elapsed)
    }

    static var isTrialActive: Bool { trialDaysRemaining > 0 }

    /// The single question the rest of the app asks.
    static var hasAccess: Bool { isUnlocked || isTrialActive }
}
