import SwiftData
import SwiftUI

/// New / edit job sheet. `job == nil` creates; `onSaved` receives the saved job (used to push Job Detail).
struct JobFormView: View {
    let job: Job?
    var onSaved: (Job) -> Void = { _ in }

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Environment(\.currencyCode) private var currencyCode
    @Query private var profiles: [BusinessProfile]
    @State private var draft = JobDraft()
    @State private var loaded = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Client") {
                    TextField("Job title", text: $draft.title)
                    TextField("Client name", text: $draft.clientName)
                        .textContentType(.name)
                        .accessibilityIdentifier("clientNameField")
                    TextField("Phone or email", text: $draft.clientContact)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                }
                Section("Site") {
                    TextField("Address", text: $draft.siteAddress)
                        .textContentType(.fullStreetAddress)
                }
                Section("Schedule") {
                    DatePicker("Start", selection: $draft.startedAt, displayedComponents: .date)
                }
                Section("Pricing") {
                    SegmentedPills(
                        options: [(PricingMode.hourly, "Hourly"), (PricingMode.fixed, "Fixed")], selection: $draft.pricing
                    )
                    .listRowInsets(.init()).listRowBackground(Color.clear)
                    if draft.pricing == .hourly {
                        LabeledContent("Rate") {
                            TextField("0", value: $draft.hourlyRate, format: .number)
                                .keyboardType(.decimalPad).multilineTextAlignment(.trailing)
                                .font(.coFigure(.callout))
                        }
                        LabeledContent("Hours") {
                            HStack {
                                TextField("0", value: $draft.laborHours, format: .number)
                                    .keyboardType(.decimalPad).multilineTextAlignment(.trailing)
                                    .font(.coFigure(.callout))
                                Stepper("Hours", value: $draft.laborHours, in: 0...1000, step: 0.5)
                                    .labelsHidden()
                            }
                        }
                    } else {
                        LabeledContent("Price") {
                            TextField("0", value: $draft.fixedPrice, format: .number)
                                .keyboardType(.decimalPad).multilineTextAlignment(.trailing)
                                .font(.coFigure(.callout))
                        }
                    }
                    LabeledContent("Materials") {
                        TextField("0", value: $draft.materialsTotal, format: .number)
                            .keyboardType(.decimalPad).multilineTextAlignment(.trailing)
                            .font(.coFigure(.callout))
                    }
                }
                Section {
                    estimatedTotal
                }
                .listRowInsets(.init()).listRowBackground(Color.clear)
            }
            .scrollContentBackground(.hidden)
            .background(.paper)
            .navigationTitle(job == nil ? "New job" : "Edit job")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .disabled(!draft.isValid)
                        .accessibilityIdentifier("saveJobToolbarButton")
                }
            }
            .bottomBar {
                Button("Save job", action: save)
                    .buttonStyle(.closeoutPrimary)
                    .disabled(!draft.isValid)
                    .accessibilityIdentifier("saveJobButton")
            }
        }
        .onAppear(perform: load)
    }

    private var estimatedTotal: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: Theme.Space.xs) {
                Text("Estimated total").font(.coSecondary).foregroundStyle(Color.paper.opacity(0.7))
                MoneyText(amount: draft.estimatedTotal, style: .title, weight: .bold)
                    .foregroundStyle(.paper)
            }
            Spacer()
            Text("excl. receipts & mileage").font(.caption2).foregroundStyle(Color.paper.opacity(0.6))
        }
        .padding(Theme.Space.l)
        .background(RoundedRectangle(cornerRadius: Theme.Radius.card).fill(.ink))
        .accessibilityElement(children: .combine)
    }

    private func load() {
        guard !loaded else { return }
        loaded = true
        draft = job.map(JobDraft.init(job:)) ?? JobDraft(defaultHourlyRate: profiles.first?.defaultHourlyRate ?? 0)
    }

    private func save() {
        guard draft.isValid else { return }
        do {
            if let job {
                draft.apply(to: job)
                try context.save()
                dismiss()
            } else {
                let created = try JobService.create(from: draft, in: context)
                dismiss()
                onSaved(created)
            }
        } catch {
            Log.app.error("Save job failed: \(error.localizedDescription)")
        }
    }
}
