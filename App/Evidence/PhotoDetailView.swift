import SwiftData
import SwiftUI

/// Large view of one photo with caption, kind and delete.
struct PhotoDetailView: View {
    @Bindable var photo: EvidencePhoto
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Space.l) {
                    ThumbnailView(fileName: photo.fileName, maxPixel: 1600)
                        .aspectRatio(1, contentMode: .fit)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
                    TextField("Caption", text: $photo.caption, axis: .vertical).cardStyle()
                    SegmentedPills(
                        options: [(EvidenceKind.site, "site"), (EvidenceKind.before, "before"), (EvidenceKind.after, "after")],
                        selection: $photo.kind
                    )
                    Button("Delete photo", systemImage: "trash", role: .destructive, action: delete)
                        .frame(minHeight: Theme.minTouchTarget)
                }
                .padding(Theme.Space.gutter)
            }
            .background(.paper)
            .navigationTitle("Photo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
    }

    private func delete() {
        EvidenceStore.shared.delete(photo.fileName)
        context.delete(photo)
        try? context.save()
        dismiss()
    }
}
