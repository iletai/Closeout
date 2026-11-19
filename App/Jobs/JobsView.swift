import SwiftData
import SwiftUI

/// Jobs list root: search, Open / Closed filter, floating "+" button.
struct JobsView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Job.startedAt, order: .reverse) private var jobs: [Job]
    @State private var path: [Job] = []
    @State private var filter = JobStatus.open
    @State private var search = ""
    @State private var showingNewJob = false
    @State private var jobToDelete: Job?

    private var visibleJobs: [Job] {
        jobs.filter { job in
            job.status == filter && (search.isEmpty
                || job.clientName.localizedStandardContains(search)
                || job.siteAddress.localizedStandardContains(search))
        }
    }

    private var openCount: Int { jobs.filter { $0.status == .open }.count }

    var body: some View {
        NavigationStack(path: $path) {
            Group {
                if jobs.isEmpty { emptyState } else { list }
            }
            .background(.paper)
            .navigationTitle("Jobs")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    NavigationLink { SettingsView() } label: { Image(systemName: "gearshape") }
                        .accessibilityLabel("Settings")
                        .accessibilityIdentifier("settingsButton")
                }
            }
            .navigationDestination(for: Job.self) { JobDetailView(job: $0) }
            .sheet(isPresented: $showingNewJob) {
                JobFormView(job: nil) { path.append($0) }
            }
            .confirmationDialog("Delete this job?", isPresented: .init(
                get: { jobToDelete != nil }, set: { if !$0 { jobToDelete = nil } }
            ), titleVisibility: .visible) {
                Button("Delete job", role: .destructive) {
                    if let jobToDelete { delete(jobToDelete) }
                }
            } message: {
                Text("Photos, receipts and mileage of this job are deleted too.")
            }
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No jobs yet", systemImage: "hammer")
        } description: {
            Text("Photos, receipts and miles for each job end up in one report.")
        } actions: {
            Button("Log your first job") { showingNewJob = true }
                .buttonStyle(.closeoutPrimary)
                .accessibilityIdentifier("logFirstJobButton")
        }
    }

    private var list: some View {
        List {
            Section {
                Text("\(openCount) open · \(jobs.count - openCount) closed")
                    .font(.coSecondary).foregroundStyle(.mutedInk)
                    .listRowBackground(Color.clear).listRowSeparator(.hidden)
                SegmentedPills(
                    options: [(JobStatus.open, "Open"), (JobStatus.closed, "Closed")], selection: $filter
                )
                .listRowBackground(Color.clear).listRowSeparator(.hidden)
            }
            Section {
                ForEach(visibleJobs) { job in
                    Button { path.append(job) } label: { JobCard(job: job) }
                        .buttonStyle(.plain)
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .listRowInsets(.init(top: 6, leading: Theme.Space.gutter, bottom: 6, trailing: Theme.Space.gutter))
                        .swipeActions {
                            Button("Delete", role: .destructive) { jobToDelete = job }
                        }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .searchable(text: $search, prompt: "Search client or address")
        .overlay {
            if visibleJobs.isEmpty {
                Text(filter == .open ? "No open jobs" : "No closed jobs")
                    .font(.coBody).foregroundStyle(.mutedInk)
            }
        }
        .overlay(alignment: .bottomTrailing) {
            Button { showingNewJob = true } label: {
                Image(systemName: "plus")
                    .font(.system(.title2, weight: .semibold))
                    .foregroundStyle(.onRust)
                    .frame(width: 56, height: 56)
                    .background(Circle().fill(.rust))
                    .shadow(color: Color.ink.opacity(0.12), radius: 8, y: 4)
            }
            .padding(Theme.Space.gutter)
            .accessibilityLabel("New job")
            .accessibilityIdentifier("newJobButton")
        }
    }

    private func delete(_ job: Job) {
        do { try JobService.delete(job, in: context) } catch { Log.app.error("Delete failed: \(error.localizedDescription)") }
        jobToDelete = nil
    }
}
