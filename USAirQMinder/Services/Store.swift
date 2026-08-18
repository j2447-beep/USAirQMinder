import Foundation
import StoreKit

/// The one-time unlock.
///
/// The app is free to use for a trial period, after which a single
/// non-consumable purchase unlocks it permanently. There is no subscription
/// and nothing recurring — buying once is the end of it.
///
/// The entitlement is mirrored into the shared App Group as it changes, so the
/// widget can honour it without linking StoreKit or running a purchase flow of
/// its own. StoreKit remains the source of truth; the mirror is a cache.
@MainActor
final class Store: ObservableObject {
    /// Must match the product ID configured in App Store Connect.
    static let unlockProductID = "com.usairqminder.app.unlock"

    @Published private(set) var product: Product?
    @Published private(set) var isUnlocked: Bool
    @Published private(set) var isWorking = false
    @Published var errorMessage: String?

    /// Listens for transactions that arrive outside a purchase we started —
    /// a purchase made on another device, a Family Sharing grant, or one the
    /// App Store finishes after the app was killed mid-flow.
    private var updateListener: Task<Void, Never>?

    init() {
        isUnlocked = SharedDefaults.isUnlocked
        updateListener = Task { [weak self] in
            for await result in Transaction.updates {
                await self?.apply(result)
            }
        }
        Task { await refreshEntitlement() }
    }

    deinit { updateListener?.cancel() }

    // MARK: - Loading

    func loadProduct() async {
        guard product == nil else { return }
        do {
            product = try await Product.products(for: [Self.unlockProductID]).first
        } catch {
            // Not surfaced: a failed load leaves the button disabled rather
            // than showing an error over a screen the user did not ask for.
            product = nil
        }
    }

    /// The displayed price comes from StoreKit, never a hard-coded string —
    /// it is already localised to the user's storefront and currency.
    var displayPrice: String? { product?.displayPrice }

    // MARK: - Buying

    func purchase() async {
        guard let product else { return }
        isWorking = true
        errorMessage = nil
        defer { isWorking = false }
        do {
            switch try await product.purchase() {
            case .success(let verification):
                await apply(verification)
            case .userCancelled:
                break                      // not an error; say nothing
            case .pending:
                errorMessage = "Your purchase is waiting on approval. It will unlock automatically once approved."
            @unknown default:
                break
            }
        } catch {
            errorMessage = "The purchase could not be completed. Please try again."
        }
    }

    /// Apple requires a way to restore purchases on a new device.
    func restore() async {
        isWorking = true
        errorMessage = nil
        defer { isWorking = false }
        do {
            try await AppStore.sync()
            await refreshEntitlement()
            if !isUnlocked {
                errorMessage = "No previous purchase was found for this Apple Account."
            }
        } catch {
            errorMessage = "Could not reach the App Store to restore. Please try again."
        }
    }

    // MARK: - Entitlement

    func refreshEntitlement() async {
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result,
                  transaction.productID == Self.unlockProductID,
                  transaction.revocationDate == nil else { continue }
            setUnlocked(true)
            return
        }
        setUnlocked(false)
    }

    private func apply(_ result: VerificationResult<Transaction>) async {
        // An unverified transaction is one StoreKit could not authenticate.
        // Treat it as no entitlement rather than trusting it.
        guard case .verified(let transaction) = result else { return }
        if transaction.productID == Self.unlockProductID, transaction.revocationDate == nil {
            setUnlocked(true)
        }
        await transaction.finish()
    }

    private func setUnlocked(_ value: Bool) {
        isUnlocked = value
        SharedDefaults.isUnlocked = value   // mirror for the widget
    }
}
