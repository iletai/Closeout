import SwiftData
import SwiftUI

/// Edit or delete a saved receipt.
struct ReceiptEditView: View {
    let receipt: Receipt
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @State private var draft = ReceiptDraft()
    @State private var loaded = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.Space.l) {
                    ReceiptEditorCard(draft: $draft)
                    Button("Delete receipt", systemImage: "trash", role: .destructive, action: delete)
                        .frame(minHeight: Theme.minTouchTarget)
                }
                .padding(Theme.Space.gutter)
            }
            .background(.paper)
            .navigationTitle("Receipt")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Save", action: save) }
            }
        }
        .onAppear {
            guard !loaded else { return }
            loaded = true
            draft = ReceiptDraft(receipt: receipt)
        }
    }

    private func save() {
        draft.apply(to: receipt)
        try? context.save()
        dismiss()
    }

    private func delete() {
        EvidenceStore.shared.delete(receipt.fileName)
        context.delete(receipt)
        try? context.save()
        dismiss()
    }
}
