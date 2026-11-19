import StoreKit
import SwiftUI

enum AppLinks {
    static let privacy = URL(string: "https://apps-site-six.vercel.app/apps/closeout/privacy") ?? URL.documentsDirectory
    static let terms = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/") ?? URL.documentsDirectory
}

/// Apple's paywall: yearly subscription (price, period, trial and renewal terms are rendered by StoreKit),
/// restore button, privacy/terms links, and the lifetime unlock underneath.
struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                storeView
                    .storeButton(.visible, for: .restorePurchases)
                    .storeButton(.visible, for: .policies)
                    .subscriptionStorePolicyDestination(url: AppLinks.terms, for: .termsOfService)
                    .subscriptionStorePolicyDestination(url: AppLinks.privacy, for: .privacyPolicy)
                ProductView(id: Store.lifetimeID)
                    .productViewStyle(.compact)
                    .padding()
            }
            .background(.paper)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } }
            }
            .onInAppPurchaseCompletion { _, result in
                if case .success(.success) = result { dismiss() }
            }
        }
    }

    @ViewBuilder private var storeView: some View {
        #if DEBUG
        // SKTestSession (store screenshots) cannot resolve a subscription group; product ids render the same layout.
        if DemoSeed.isRequested {
            SubscriptionStoreView(productIDs: ["\(AppConfiguration.bundleIdentifier).pro.yearly"]) { marketing }
        } else {
            SubscriptionStoreView(groupID: Store.groupID) { marketing }
        }
        #else
        SubscriptionStoreView(groupID: Store.groupID) { marketing }
        #endif
    }

    private var marketing: some View {
        VStack(alignment: .leading, spacing: Theme.Space.m) {
            Text("Closeout Pro").font(.coTitle).foregroundStyle(.ink)
            ProBenefits()
        }
        .padding(Theme.Space.gutter)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// The three Pro benefits shown on the paywall and in Settings.
struct ProBenefits: View {
    var color: Color = .ink

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Space.s) {
            row("Unlimited photos per job")
            row("Logo and business branding on every report")
            row("Custom mileage rate and CSV export")
        }
    }

    private func row(_ title: LocalizedStringKey) -> some View {
        Label {
            Text(title).font(.coBody).foregroundStyle(color)
        } icon: {
            Image(systemName: "checkmark").foregroundStyle(.amber)
        }
    }
}

#Preview {
    PaywallView()
}
