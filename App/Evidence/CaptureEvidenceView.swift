import PhotosUI
import SwiftData
import SwiftUI

/// Add photos to a job from the camera or the photo library.
struct CaptureEvidenceView: View {
    enum Mode: Hashable { case photo, library }

    let job: Job

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Environment(\.isPro) private var isPro
    @State private var mode = Mode.photo
    @State private var pending: [Data] = []
    @State private var caption = ""
    @State private var kind = EvidenceKind.site
    @State private var pickerItems: [PhotosPickerItem] = []
    @State private var showingCamera = false
    @State private var showingPaywall = false
    @State private var errorMessage: LocalizedStringKey?

    private var remaining: Int { PhotoQuota.remaining(existing: job.photos.count, isPro: isPro) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Space.l) {
                    SegmentedPills(options: [(Mode.photo, "Photo"), (Mode.library, "Library")], selection: $mode)
                    source
                    if !pending.isEmpty { pendingRow }
                    TextField("What did you finish here?", text: $caption, axis: .vertical)
                        .lineLimit(1...3)
                        .cardStyle()
                    kindPicker
                    if let errorMessage {
                        Text(errorMessage).font(.coSecondary).foregroundStyle(.rust)
                    }
                }
                .padding(Theme.Space.gutter)
            }
            .background(.paper)
            .navigationTitle("Add evidence")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } }
                if !isPro {
                    ToolbarItem(placement: .primaryAction) {
                        Text("\(job.photos.count + pending.count)/\(PhotoQuota.freeLimit)")
                            .font(.coFigure(.footnote))
                            .foregroundStyle(.mutedInk)
                    }
                }
            }
            .bottomBar {
                Button("Save evidence", systemImage: "camera", action: save)
                    .buttonStyle(.closeoutPrimary)
                    .disabled(pending.isEmpty)
                    .accessibilityIdentifier("saveEvidenceButton")
            }
            .fullScreenCover(isPresented: $showingCamera) {
                CameraPicker { pending.append($0) }.ignoresSafeArea()
            }
            .sheet(isPresented: $showingPaywall) { PaywallView() }
            .onChange(of: pickerItems) { _, items in loadPicked(items) }
        }
    }

    @ViewBuilder private var source: some View {
        VStack(spacing: Theme.Space.m) {
            switch mode {
            case .photo:
                if CameraPicker.isAvailable {
                    Button("Take photo", systemImage: "camera.fill") { showingCamera = true }
                        .buttonStyle(.closeoutSecondary)
                } else {
                    Text("Camera is not available on this device. Use Library instead.")
                        .font(.coSecondary).foregroundStyle(.mutedInk)
                }
            case .library:
                PhotosPicker(selection: $pickerItems, maxSelectionCount: 10, matching: .images) {
                    Label("Choose photos", systemImage: "photo.on.rectangle")
                }
                .buttonStyle(.closeoutSecondary)
            }
            #if DEBUG
            if ProcessInfo.processInfo.arguments.contains("-closeoutUITesting") {
                Button("Add sample photo") { pending.append(SampleImage.jpegData()) }
                    .accessibilityIdentifier("addSamplePhotoButton")
            }
            #endif
        }
        .frame(maxWidth: .infinity, minHeight: 160)
        .cardStyle()
    }

    private var pendingRow: some View {
        ScrollView(.horizontal) {
            HStack(spacing: Theme.Space.s) {
                ForEach(Array(pending.enumerated()), id: \.offset) { _, data in
                    PendingThumbnail(data: data)
                }
            }
        }
        .scrollIndicators(.hidden)
    }

    private var kindPicker: some View {
        SegmentedPills(
            options: [(EvidenceKind.site, "site"), (EvidenceKind.before, "before"), (EvidenceKind.after, "after")],
            selection: $kind
        )
    }

    private func loadPicked(_ items: [PhotosPickerItem]) {
        guard !items.isEmpty else { return }
        Task {
            for item in items {
                if let data = try? await item.loadTransferable(type: Data.self) { pending.append(data) }
            }
            pickerItems = []
        }
    }

    private func save() {
        guard PhotoQuota.canAdd(pending.count, existing: job.photos.count, isPro: isPro) else {
            showingPaywall = true
            return
        }
        do {
            for data in pending {
                let fileName = try EvidenceStore.shared.save(data)
                job.photos.append(EvidencePhoto(fileName: fileName, caption: caption, kind: kind))
            }
            job.updatedAt = .now
            try context.save()
            dismiss()
        } catch {
            Log.app.error("Save evidence failed: \(error.localizedDescription)")
            errorMessage = "Could not save the photo."
        }
    }
}

private struct PendingThumbnail: View {
    let data: Data

    var body: some View {
        Color.line
            .overlay {
                if let image = EvidenceStore.thumbnail(from: data, maxPixel: 160) {
                    Image(decorative: image, scale: 1).resizable().scaledToFill()
                }
            }
            .frame(width: 56, height: 56)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.chip))
    }
}
