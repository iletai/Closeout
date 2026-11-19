import SwiftData
import SwiftUI

@main
struct CloseoutApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @State private var hasSubscription = false
    @State private var hasLifetime = false
    private let container = AppSchema.launchContainer()

    var body: some Scene {
        WindowGroup {
            if isUnitTesting {
                // Unit tests host the app; keep StoreKit idle so SKTestSession can attach before the first request.
                Color.clear
            } else {
                content
            }
        }
        .modelContainer(container)
        // Persist pending edits (e.g. notes) before the app can be killed in the background.
        .onChange(of: scenePhase) { _, phase in
            if phase == .background { try? container.mainContext.save() }
        }
    }

    private var isUnitTesting: Bool {
        ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
    }

    private var content: some View {
        RootView()
            .task { seedProfile() }
            .environment(\.isPro, hasSubscription || hasLifetime)
            .subscriptionStatusTask(for: Store.groupID) { state in
                guard case .success(let statuses) = state else { return }
                hasSubscription = statuses.contains { $0.state == .subscribed || $0.state == .inGracePeriod }
            }
            .currentEntitlementTask(for: Store.lifetimeID) { state in
                guard case .success(let result) = state else { return }
                if case .verified(let transaction)? = result {
                    hasLifetime = transaction.revocationDate == nil
                } else {
                    hasLifetime = false
                }
            }
    }

    private func seedProfile() {
        do {
            try BusinessProfile.seedIfNeeded(in: container.mainContext)
        } catch {
            Log.app.error("Profile seed failed: \(error.localizedDescription)")
        }
    }
}
