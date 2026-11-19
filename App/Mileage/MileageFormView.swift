import SwiftData
import SwiftUI

/// Add or edit a mileage entry. Manual miles only: no location permission is requested.
struct MileageFormView: View {
    let job: Job
    var entry: MileageEntry?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Environment(\.isPro) private var isPro
    @Query private var profiles: [BusinessProfile]
    @State private var date = Date.now
    @State private var miles = 0.0
    @State private var startLabel = ""
    @State private var endLabel = ""
    @State private var rate = Decimal.zero
    @State private var loaded = false

    var body: some View {
        NavigationStack {
            Form {
                DatePicker("Date", selection: $date, displayedComponents: .date)
                TextField("From", text: $startLabel)
                TextField("To", text: $endLabel)
                LabeledContent("Miles") {
                    TextField("0", value: $miles, format: .number)
                        .keyboardType(.decimalPad).multilineTextAlignment(.trailing)
                        .font(.coFigure(.callout))
                        .accessibilityIdentifier("mileageMilesField")
                }
                LabeledContent("Rate per mile") {
                    if isPro {
                        TextField("0", value: $rate, format: .number)
                            .keyboardType(.decimalPad).multilineTextAlignment(.trailing)
                            .font(.coFigure(.callout))
                    } else {
                        Label { MoneyText(amount: rate) } icon: { Image(systemName: "lock.fill") }
                            .foregroundStyle(.mutedInk)
                    }
                }
                if entry != nil {
                    Button("Delete entry", role: .destructive, action: delete)
                }
            }
            .scrollContentBackground(.hidden)
            .background(.paper)
            .navigationTitle(entry == nil ? "Add mileage" : "Mileage")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save).disabled(miles <= 0).accessibilityIdentifier("saveMileageButton")
                }
            }
        }
        .onAppear(perform: load)
    }

    private func load() {
        guard !loaded else { return }
        loaded = true
        if let entry {
            date = entry.date; miles = entry.miles; startLabel = entry.startLabel
            endLabel = entry.endLabel; rate = entry.ratePerMile
        } else {
            rate = profiles.first?.defaultMileageRate ?? 0
        }
    }

    private func save() {
        if let entry {
            entry.date = date; entry.miles = miles; entry.startLabel = startLabel
            entry.endLabel = endLabel; entry.ratePerMile = rate
        } else {
            job.mileage.append(MileageEntry(date: date, miles: miles, startLabel: startLabel, endLabel: endLabel, ratePerMile: rate))
        }
        job.updatedAt = .now
        try? context.save()
        dismiss()
    }

    private func delete() {
        if let entry { context.delete(entry) }
        try? context.save()
        dismiss()
    }
}
