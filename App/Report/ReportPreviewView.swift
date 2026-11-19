import PDFKit
import SwiftData
import SwiftUI
import UniformTypeIdentifiers

/// PDF document wrapper for the Files exporter.
struct PDFFileDocument: FileDocument {
    static let readableContentTypes: [UTType] = [.pdf]
    let data: Data

    init(data: Data) { self.data = data }
    init(configuration: ReadConfiguration) throws { data = configuration.file.regularFileContents ?? Data() }
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper { FileWrapper(regularFileWithContents: data) }
}

private struct PDFPageView: UIViewRepresentable {
    let document: PDFDocument

    func makeUIView(context: Context) -> PDFView {
        let view = PDFView()
        view.autoScales = true
        view.displayMode = .singlePage
        view.backgroundColor = .clear
        view.pageShadowsEnabled = false
        return view
    }

    func updateUIView(_ view: PDFView, context: Context) {
        if view.document !== document { view.document = document }
    }
}

/// Renders the report off the main actor, previews page 1 and offers share / export to Files.
struct ReportPreviewView: View {
    let job: Job

    @Environment(\.dismiss) private var dismiss
    @Environment(\.isPro) private var isPro
    @Query private var profiles: [BusinessProfile]
    @State private var options = ReportOptions()
    @State private var pdfData: Data?
    @State private var fileURL: URL?
    @State private var showingExporter = false

    private var document: PDFDocument? { pdfData.flatMap(PDFDocument.init(data:)) }

    var body: some View {
        NavigationStack {
            VStack(spacing: Theme.Space.m) {
                if let document {
                    PDFPageView(document: document)
                        .overlay(RoundedRectangle(cornerRadius: Theme.Radius.page).stroke(.line, lineWidth: 1))
                        .padding(.horizontal, Theme.Space.gutter)
                        .accessibilityLabel("Report preview")
                    Text("Page 1 of \(document.pageCount)")
                        .font(.coFigure(.footnote)).foregroundStyle(.mutedInk)
                } else {
                    ProgressView().frame(maxHeight: .infinity)
                }
                toggles
            }
            .background(.paper)
            .navigationTitle("Report")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Done") { dismiss() } }
            }
            .bottomBar { actions }
            .fileExporter(
                isPresented: $showingExporter, document: PDFFileDocument(data: pdfData ?? Data()),
                contentType: .pdf, defaultFilename: fileName
            ) { _ in }
        }
        .task(id: options) { await render() }
    }

    private var fileName: String { "Closeout-\(job.numberLabel.dropFirst())" }

    private var toggles: some View {
        HStack(spacing: Theme.Space.s) {
            Toggle("Include receipts", isOn: $options.includeReceipts)
            Toggle("Include mileage", isOn: $options.includeMileage)
        }
        .toggleStyle(.button)
        .tint(.steel)
        .font(.coSecondary)
    }

    private var actions: some View {
        HStack(spacing: Theme.Space.m) {
            Button("Export to Files") { showingExporter = true }
                .buttonStyle(.closeoutSecondary)
                .disabled(pdfData == nil)
                .accessibilityIdentifier("exportReportButton")
            if let fileURL {
                ShareLink(item: fileURL) {
                    Label("Share report", systemImage: "square.and.arrow.up")
                }
                .buttonStyle(.closeoutPrimary)
                .accessibilityIdentifier("shareReportButton")
            } else {
                Button("Share report") {}.buttonStyle(.closeoutPrimary).disabled(true)
            }
        }
    }

    private func render() async {
        let data = ReportData(job: job, profile: profiles.first, isPro: isPro, options: options)
        let rendered = await Task.detached { PDFReportRenderer.render(data) }.value
        pdfData = rendered
        let url = FileManager.default.temporaryDirectory.appending(path: "\(fileName).pdf")
        do {
            try rendered.write(to: url, options: .atomic)
            fileURL = url
        } catch {
            Log.app.error("Writing report failed: \(error.localizedDescription)")
        }
    }
}
