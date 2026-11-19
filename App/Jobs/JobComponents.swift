import SwiftUI

struct StatusPill: View {
    let status: JobStatus

    var body: some View {
        let color: Color = status == .open ? .amber : .steel
        HStack(spacing: Theme.Space.xs) {
            Circle().fill(color).frame(width: 6, height: 6)
            Text(status == .open ? "Open" : "Closed")
                .font(.system(.caption, weight: .semibold))
                .foregroundStyle(.ink)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background(Capsule().fill(color.opacity(0.16)))
        .accessibilityElement(children: .combine)
    }
}

extension Job {
    /// "Nov 12 - Nov 14", or only the start while the job is open.
    var dateRangeText: String {
        guard let closedAt, !Calendar.current.isDate(closedAt, inSameDayAs: startedAt) else {
            return startedAt.formatted(.dateTime.month(.abbreviated).day())
        }
        return (startedAt..<max(closedAt, startedAt)).formatted(.interval.month(.abbreviated).day())
    }
}

struct JobCard: View {
    let job: Job

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Space.s) {
            HStack {
                Text(job.clientName).font(.coCardTitle).foregroundStyle(.ink)
                Spacer()
                Text(job.numberLabel).font(.coFigure(.caption)).foregroundStyle(.mutedInk)
            }
            if !job.siteAddress.isEmpty {
                Label(job.siteAddress, systemImage: "mappin.and.ellipse")
                    .font(.coSecondary).foregroundStyle(.mutedInk)
            }
            HStack {
                StatusPill(status: job.status)
                Spacer()
                MoneyText(amount: job.totals.total, style: .callout)
                    .foregroundStyle(.ink)
            }
            Text("\(job.photos.count) photos · \(job.receipts.count) receipts")
                .font(.coSecondary).foregroundStyle(.mutedInk)
        }
        .cardStyle()
        .accessibilityElement(children: .combine)
    }
}
