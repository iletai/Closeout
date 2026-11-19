import SwiftUI

/// Design tokens from DESIGN.md. Colors live in Assets.xcassets/Theme with dark variants,
/// so views never branch on color scheme.
/// shortcut: system fonts stand in for Space Grotesk / Inter / Space Mono (no font files bundled);
/// swap only the `Font.co*` definitions below when the font files are added.
extension ShapeStyle where Self == Color {
    static var ink: Color { Color("ink") }
    static var paper: Color { Color("paper") }
    static var surface: Color { Color("surface") }
    static var rust: Color { Color("rust") }
    static var amber: Color { Color("amber") }
    static var steel: Color { Color("steel") }
    static var line: Color { Color("line") }
    static var mutedInk: Color { Color("mutedInk") }
}

enum Theme {
    enum Space {
        static let xs: CGFloat = 4
        static let s: CGFloat = 8
        static let m: CGFloat = 12
        static let l: CGFloat = 16
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32
        static let gutter: CGFloat = 20
    }

    enum Radius {
        static let card: CGFloat = 12
        static let chip: CGFloat = 8
        static let page: CGFloat = 4
    }

    static let minTouchTarget: CGFloat = 48
    static let primaryButtonHeight: CGFloat = 52
}

extension Font {
    /// Screen title (Space Grotesk 28-32 semibold).
    static let coTitle = Font.system(.largeTitle, weight: .semibold)
    /// Card / section title (Space Grotesk 17 semibold).
    static let coCardTitle = Font.system(.headline, weight: .semibold)
    static let coBody = Font.system(.subheadline)
    static let coSecondary = Font.system(.footnote)
    static let coMicro = Font.system(.caption2, weight: .semibold)

    /// Money, mileage, dates, job number (Space Mono, tabular).
    static func coFigure(_ style: Font.TextStyle = .subheadline, weight: Font.Weight = .regular) -> Font {
        .system(style, design: .monospaced, weight: weight)
    }
}

extension View {
    /// Micro label: uppercase, tracked, muted (section labels).
    func microLabel() -> some View {
        font(.coMicro)
            .textCase(.uppercase)
            .tracking(0.7)
            .foregroundStyle(.mutedInk)
    }

    /// White/dark surface card with a 1pt border instead of a shadow.
    func cardStyle(padding: CGFloat = Theme.Space.l) -> some View {
        self
            .padding(padding)
            .background(.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.card))
            .overlay(RoundedRectangle(cornerRadius: Theme.Radius.card).stroke(.line, lineWidth: 1))
    }

    /// Sticky bottom action bar: paper background with a 1pt top border.
    func bottomBar<Bar: View>(@ViewBuilder _ bar: () -> Bar) -> some View {
        let content = bar()
        return safeAreaInset(edge: .bottom, spacing: 0) {
            content
                .padding(Theme.Space.l)
                .frame(maxWidth: .infinity)
                .background(.paper)
                .overlay(alignment: .top) { Rectangle().fill(.line).frame(height: 1) }
        }
    }
}

struct CloseoutPrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.callout, weight: .semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, Theme.Space.xl)
            .frame(maxWidth: .infinity, minHeight: Theme.primaryButtonHeight)
            .background(Capsule().fill(.rust))
            .opacity(isEnabled ? (configuration.isPressed ? 0.85 : 1) : 0.4)
    }
}

struct CloseoutSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.callout, weight: .semibold))
            .foregroundStyle(.rust)
            .frame(maxWidth: .infinity, minHeight: Theme.primaryButtonHeight)
            .background(Capsule().fill(.surface))
            .overlay(Capsule().stroke(.rust, lineWidth: 1))
            .opacity(configuration.isPressed ? 0.85 : 1)
    }
}

extension ButtonStyle where Self == CloseoutPrimaryButtonStyle {
    static var closeoutPrimary: CloseoutPrimaryButtonStyle { .init() }
}

extension ButtonStyle where Self == CloseoutSecondaryButtonStyle {
    static var closeoutSecondary: CloseoutSecondaryButtonStyle { .init() }
}

/// Pill-style segmented control (Open / Closed, Photo / Receipt / Library, Hourly / Fixed).
struct SegmentedPills<Value: Hashable>: View {
    let options: [(value: Value, title: LocalizedStringKey)]
    @Binding var selection: Value

    var body: some View {
        HStack(spacing: Theme.Space.xs) {
            ForEach(options, id: \.value) { option in
                let isSelected = option.value == selection
                Button {
                    selection = option.value
                } label: {
                    Text(option.title)
                        .font(.system(.footnote, weight: .semibold))
                        .foregroundStyle(isSelected ? .rust : .mutedInk)
                        .frame(maxWidth: .infinity, minHeight: 36)
                        .background(Capsule().fill(isSelected ? .surface : .clear))
                        .overlay(Capsule().stroke(isSelected ? .line : .clear, lineWidth: 1))
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
        .padding(Theme.Space.xs)
        .background(Capsule().fill(.paper))
        .overlay(Capsule().stroke(.line, lineWidth: 1))
    }
}

/// Section header: title on the left, optional rust text action on the right.
struct SectionHeader: View {
    let title: LocalizedStringKey
    var actionTitle: LocalizedStringKey?
    var action: (() -> Void)?

    var body: some View {
        HStack {
            Text(title).font(.coCardTitle).foregroundStyle(.ink)
            Spacer()
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .font(.system(.subheadline, weight: .semibold))
                    .foregroundStyle(.rust)
                    .frame(minHeight: Theme.minTouchTarget)
            }
        }
    }
}
