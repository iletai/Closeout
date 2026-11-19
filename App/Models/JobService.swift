import Foundation
import SwiftData

/// Job lifecycle operations that touch more than one model.
enum JobService {
    @discardableResult
    static func create(from draft: JobDraft, in context: ModelContext) throws -> Job {
        let job = Job()
        let last = try context.fetch(FetchDescriptor<Job>(sortBy: [SortDescriptor(\.number, order: .reverse)])).first
        job.number = (last?.number ?? 0) + 1
        draft.apply(to: job)
        context.insert(job)
        try context.save()
        return job
    }

    /// Deletes the job (children cascade in the database) and the image files they reference.
    static func delete(_ job: Job, in context: ModelContext, store: EvidenceStore = .shared) throws {
        job.photos.forEach { store.delete($0.fileName) }
        job.receipts.forEach { store.delete($0.fileName) }
        context.delete(job)
        try context.save()
    }
}
