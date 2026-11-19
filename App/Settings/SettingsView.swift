import PhotosUI
import StoreKit
import SwiftData
import SwiftUI

/// Settings & Closeout Pro: business profile, defaults, Pro status, report options, about.
struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @Query private var profiles: [BusinessProfile]

    var body: some View {
        Group {
            if let profile = profiles.first {
                SettingsForm(profile: profile)
            } else {
                ProgressView().task { _ = try? BusinessProfile.seedIfNeeded(in: context) }
            }
        }
        .background(.paper)
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct SettingsForm: View {
    @Bindable var profile: BusinessProfile
    @Environment(\.isPro) private var isPro
    @Environment(\.modelContext) private var context
    @Query(sort: \Job.number) private var jobs: [Job]
    @State private var showingPaywall = false
    @State private var logoItem: PhotosPickerItem?
    @State private var restoreMessage: LocalizedStringKey?

    private static let currencies = ["USD", "CAD", "GBP", "AUD", "EUR", "VND"]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Space.xl) {
                businessProfile
                defaults
                proCard
                reports
                about
            }
            .padding(Theme.Space.gutter)
        }
        .sheet(isPresented: $showingPaywall) { PaywallView() }
        .onChange(of: logoItem) { _, item in loadLogo(item) }
        .onDisappear { try? context.save() }
    }

    // MARK: Sections

    private var businessProfile: some View {
        section("Business profile") {
            HStack(spacing: Theme.Space.m) {
                logoTile
                VStack(alignment: .leading, spacing: Theme.Space.xs) {
                    TextField("Business name", text: $profile.businessName).font(.coCardTitle)
                    if isPro {
                        PhotosPicker(selection: $logoItem, matching: .images) { Text("Change logo") }
                            .font(.coSecondary).foregroundStyle(.rust)
                    } else {
                        Button("Change logo") { showingPaywall = true }
                            .font(.coSecondary).foregroundStyle(.rust)
                    }
                }
            }
            row("Owner") { TextField("Name", text: $profile.ownerName) }
            row("Phone") { TextField("Phone", text: $profile.phone).keyboardType(.phonePad) }
            row("Email") {
                TextField("Email", text: $profile.email)
                    .keyboardType(.emailAddress).textInputAutocapitalization(.never)
            }
        }
    }

    private var logoTile: some View {
        RoundedRectangle(cornerRadius: 10).fill(.ink)
            .frame(width: 48, height: 48)
            .overlay {
                if let name = profile.logoFileName {
                    ThumbnailView(fileName: name, maxPixel: 200).clipShape(RoundedRectangle(cornerRadius: 10))
                } else {
                    Text(String(profile.businessName.prefix(1)).uppercased())
                        .font(.coCardTitle).foregroundStyle(.paper)
                }
            }
            .accessibilityHidden(true)
    }

    private var defaults: some View {
        section("Defaults") {
            row("Currency") {
                Picker("Currency", selection: $profile.currencyCode) {
                    ForEach(Self.currencies, id: \.self) { Text($0).tag($0) }
                }
                .labelsHidden()
            }
            row("Default rate") {
                TextField("0", value: $profile.defaultHourlyRate, format: .number)
                    .keyboardType(.decimalPad).font(.coFigure(.callout))
            }
            row("Mileage rate") {
                if isPro {
                    TextField("0", value: $profile.defaultMileageRate, format: .number)
                        .keyboardType(.decimalPad).font(.coFigure(.callout))
                } else {
                    Button { showingPaywall = true } label: {
                        Label { MoneyText(amount: profile.defaultMileageRate, style: .callout) }
                            icon: { Image(systemName: "lock.fill") }
                    }
                    .foregroundStyle(.mutedInk)
                }
            }
        }
    }

    @ViewBuilder private var proCard: some View {
        VStack(alignment: .leading, spacing: Theme.Space.m) {
            Text(isPro ? "PRO PLAN" : "FREE PLAN")
                .font(.coFigure(.caption2)).foregroundStyle(.rust)
                .padding(.horizontal, 10).padding(.vertical, 4)
                .overlay(Capsule().stroke(.rust, lineWidth: 1))
            Text("Unlimited photos and your own branding")
                .font(.system(.title3, weight: .semibold)).foregroundStyle(.paper)
            ProBenefits(color: .paper)
            if isPro {
                Button("Manage subscription") { Task { await manageSubscription() } }
                    .buttonStyle(.closeoutSecondary)
            } else {
                Button("See Pro plans") { showingPaywall = true }
                    .buttonStyle(.closeoutPrimary)
                    .accessibilityIdentifier("seeProPlansButton")
                Text("Yearly $14.99 with 7-day trial · Lifetime $29.99")
                    .font(.caption2).foregroundStyle(Color.paper.opacity(0.7))
            }
        }
        .padding(Theme.Space.xl)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 16).fill(.ink))
    }

    private var reports: some View {
        section("Reports") {
            row("Report footer note") {
                if isPro {
                    TextField("Thanks for your business", text: $profile.reportFooterNote)
                } else {
                    Button { showingPaywall = true } label: { Image(systemName: "lock.fill") }
                        .foregroundStyle(.mutedInk).accessibilityLabel("Pro feature")
                }
            }
            Toggle("Include signature line", isOn: $profile.includeSignatureLine).font(.coBody).tint(.rust)
        }
    }

    private var about: some View {
        VStack(alignment: .leading, spacing: Theme.Space.m) {
            section("About") {
                Button("Restore purchases") { Task { await restore() } }
                    .font(.coBody).foregroundStyle(.ink).accessibilityIdentifier("restorePurchasesButton")
                if let restoreMessage { Text(restoreMessage).font(.coSecondary).foregroundStyle(.mutedInk) }
                if isPro, let url = exportURL {
                    ShareLink(item: url) { Text("Export jobs as CSV") }.font(.coBody).foregroundStyle(.ink)
                }
                Link("Privacy policy", destination: AppLinks.privacy).font(.coBody).foregroundStyle(.ink)
                Link("Terms of use", destination: AppLinks.terms).font(.coBody).foregroundStyle(.ink)
            }
            Text("Version \(Bundle.main.versionText) · All data stays on this iPhone")
                .font(.caption2).foregroundStyle(.mutedInk)
        }
    }

    // MARK: Helpers

    private func section(_ title: LocalizedStringKey, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: Theme.Space.s) {
            Text(title).microLabel()
            VStack(alignment: .leading, spacing: Theme.Space.m, content: content).cardStyle()
        }
    }

    private func row(_ title: LocalizedStringKey, @ViewBuilder value: () -> some View) -> some View {
        HStack {
            Text(title).font(.coSecondary).foregroundStyle(.mutedInk)
            Spacer()
            value().multilineTextAlignment(.trailing).font(.coBody).foregroundStyle(.ink)
        }
        .frame(minHeight: 36)
    }

    private var exportURL: URL? {
        let url = FileManager.default.temporaryDirectory.appending(path: "Closeout-export.csv")
        do {
            try CSVExporter.csv(for: jobs).write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch {
            Log.app.error("CSV export failed: \(error.localizedDescription)")
            return nil
        }
    }

    private func loadLogo(_ item: PhotosPickerItem?) {
        guard let item else { return }
        Task {
            defer { logoItem = nil }
            guard let data = try? await item.loadTransferable(type: Data.self),
                  let fileName = try? EvidenceStore.shared.save(data) else { return }
            EvidenceStore.shared.delete(profile.logoFileName)
            profile.logoFileName = fileName
        }
    }

    private func restore() async {
        do {
            try await AppStore.sync()
            restoreMessage = "Purchases restored."
        } catch {
            Log.store.error("Restore failed: \(error.localizedDescription)")
            restoreMessage = "Could not restore purchases."
        }
    }

    private func manageSubscription() async {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
        try? await AppStore.showManageSubscriptions(in: scene)
    }
}

extension Bundle {
    /// "1.0.0 (1)"
    var versionText: String {
        let version = object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let build = object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "\(version) (\(build))"
    }
}
