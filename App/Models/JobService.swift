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

    static func delete(_ job: Job, in context: ModelContext) throws {
        context.delete(job)
        try context.save()
    }
}
