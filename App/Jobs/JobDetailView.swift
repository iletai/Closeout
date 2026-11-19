import SwiftData
import SwiftUI

/// Job header, totals and sections for evidence, receipts, mileage and notes.
struct JobDetailView: View {
    @Bindable var job: Job
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @State private var showingEdit = false
    @State private var showingDelete = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Space.xl) {
                header
                totalStrip
                notes
            }
            .padding(.horizontal, Theme.Space.gutter)
            .padding(.bottom, Theme.Space.xl)
        }
        .background(.paper)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showingEdit = true } label: { Image(systemName: "pencil") }
                    .accessibilityLabel("Edit job")
            }
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button(job.status == .open ? "Close job" : "Reopen job", systemImage: "checkmark.circle", action: toggleStatus)
                    Button("Delete job", systemImage: "trash", role: .destructive) { showingDelete = true }
                } label: { Image(systemName: "ellipsis.circle") }
                    .accessibilityLabel("More")
            }
        }
        .sheet(isPresented: $showingEdit) { JobFormView(job: job) }
        .confirmationDialog("Delete this job?", isPresented: $showingDelete, titleVisibility: .visible) {
            Button("Delete job", role: .destructive) {
                do { try JobService.delete(job, in: context) } catch { Log.app.error("Delete failed: \(error.localizedDescription)") }
                dismiss()
            }
        } message: {
            Text("Photos, receipts and mileage of this job are deleted too.")
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: Theme.Space.s) {
            Text(job.numberLabel).font(.coFigure(.caption)).foregroundStyle(.mutedInk)
            Text(job.clientName).font(.coTitle).foregroundStyle(.ink)
            if !job.siteAddress.isEmpty {
                Label(job.siteAddress, systemImage: "mappin.and.ellipse")
                    .font(.coSecondary).foregroundStyle(.mutedInk)
            }
            HStack {
                StatusPill(status: job.status)
                Text(job.dateRangeText).font(.coFigure(.caption)).foregroundStyle(.mutedInk)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var totalStrip: some View {
        let totals = job.totals
        return HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: Theme.Space.xs) {
                Text("Report total").font(.coSecondary).foregroundStyle(.mutedInk)
                MoneyText(amount: totals.total, style: .title, weight: .bold).foregroundStyle(.ink)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: Theme.Space.xs) {
                totalLine("Labor", totals.labor)
                totalLine("Materials", totals.materials)
                totalLine("Receipts", totals.expenses)
                totalLine("Mileage", totals.mileageCost)
            }
        }
        .cardStyle()
    }

    private func totalLine(_ title: LocalizedStringKey, _ amount: Decimal) -> some View {
        HStack(spacing: Theme.Space.s) {
            Text(title).font(.coSecondary)
            MoneyText(amount: amount, style: .caption)
        }
        .foregroundStyle(.mutedInk)
    }

    private var notes: some View {
        VStack(alignment: .leading, spacing: Theme.Space.s) {
            SectionHeader(title: "Notes")
            TextField("What did you finish here?", text: $job.notes, axis: .vertical)
                .lineLimit(3...8)
                .cardStyle()
        }
    }

    private func toggleStatus() {
        job.status = job.status == .open ? .closed : .open
        job.closedAt = job.status == .closed ? .now : nil
        job.updatedAt = .now
    }
}
