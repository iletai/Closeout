import SwiftUI

/// Jobs list root. Empty state until M2 adds job creation.
struct JobsView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView {
                Label("No jobs yet", systemImage: "hammer")
            } description: {
                Text("Photos, receipts and miles for each job end up in one report.")
            } actions: {
                Button("Log your first job") {}
                    .buttonStyle(.closeoutPrimary)
                    .padding(.horizontal, Theme.Space.gutter)
            }
            .background(.paper)
            .navigationTitle("Jobs")
        }
    }
}

#Preview {
    JobsView()
}
