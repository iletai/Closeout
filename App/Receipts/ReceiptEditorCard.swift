import SwiftUI

/// Editable receipt fields with the OCR confidence chip and the "check before sending" note.
struct ReceiptEditorCard: View {
    @Binding var draft: ReceiptDraft

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Space.m) {
            HStack {
                Text("Scanned receipt").font(.coSecondary).foregroundStyle(.mutedInk)
                Spacer()
                if draft.ocrConfidence > 0 {
                    Text("\(Int((draft.ocrConfidence * 100).rounded()))% match")
                        .font(.coFigure(.caption))
                        .foregroundStyle(.steel)
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(Capsule().fill(Color.steel.opacity(0.12)))
                }
            }
            field("Merchant") {
                TextField("Merchant", text: $draft.merchantName)
                    .accessibilityIdentifier("receiptMerchantField")
            }
            field("Total") {
                TextField("0", value: $draft.total, format: .number)
                    .keyboardType(.decimalPad)
                    .font(.coFigure(.callout))
                    .accessibilityIdentifier("receiptTotalField")
            }
            DatePicker("Date", selection: $draft.purchasedAt, displayedComponents: .date)
                .font(.coBody)
            Toggle("Reimbursable", isOn: $draft.isReimbursable).font(.coBody).tint(.rust)
            if draft.ocrConfidence > 0 {
                Text("Check these fields before you send the report.")
                    .font(.coSecondary).foregroundStyle(.rust)
            }
        }
        .cardStyle()
        .overlay(alignment: .leading) {
            UnevenRoundedRectangle(topLeadingRadius: Theme.Radius.card, bottomLeadingRadius: Theme.Radius.card)
                .fill(.steel).frame(width: 3)
        }
    }

    private func field(_ title: LocalizedStringKey, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(.coMicro).foregroundStyle(.mutedInk)
            content()
        }
    }
}
