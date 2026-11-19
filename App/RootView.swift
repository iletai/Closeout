import SwiftData
import SwiftUI

/// Top of the view tree.
struct RootView: View {
    @Query private var profiles: [BusinessProfile]

    var body: some View {
        JobsView()
            .environment(\.currencyCode, profiles.first?.currencyCode ?? Locale.current.currency?.identifier ?? "USD")
    }
}
