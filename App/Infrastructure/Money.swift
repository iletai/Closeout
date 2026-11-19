import SwiftUI

extension EnvironmentValues {
    /// Currency from `BusinessProfile`, injected by `RootView`.
    @Entry var currencyCode = "USD"
}

/// Money in tabular monospaced figures, formatted with the user's currency and locale.
struct MoneyText: View {
    let amount: Decimal
    var style: Font.TextStyle = .subheadline
    var weight: Font.Weight = .regular
    @Environment(\.currencyCode) private var currencyCode

    var body: some View {
        Text(amount, format: .currency(code: currencyCode))
            .font(.coFigure(style, weight: weight))
            .monospacedDigit()
    }
}
