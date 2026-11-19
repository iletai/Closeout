import Foundation
import SwiftData

enum AppSchema {
    static let models: [any PersistentModel.Type] = [
        Job.self, EvidencePhoto.self, Receipt.self, MileageEntry.self, BusinessProfile.self
    ]

    static func makeContainer(inMemory: Bool = false) throws -> ModelContainer {
        try ModelContainer(
            for: Schema(models),
            configurations: ModelConfiguration(isStoredInMemoryOnly: inMemory)
        )
    }
}

extension AppSchema {
    /// Persistent container for the running app. UI tests pass `-closeoutResetData` to start from an empty store.
    @MainActor static func launchContainer() -> ModelContainer {
        let container: ModelContainer
        // A fresh install has no Application Support yet; creating it avoids noisy CoreData stat errors.
        try? FileManager.default.createDirectory(at: .applicationSupportDirectory, withIntermediateDirectories: true)
        do {
            container = try makeContainer()
        } catch {
            fatalError("Cannot open the database: \(error)")
        }
        if ProcessInfo.processInfo.arguments.contains("-closeoutResetData") {
            do {
                try container.mainContext.delete(model: Job.self)
                try container.mainContext.delete(model: BusinessProfile.self)
                try container.mainContext.save()
                EvidenceStore.shared.removeAll()
            } catch {
                Log.app.error("Reset failed: \(error.localizedDescription)")
            }
        }
        #if DEBUG
        if DemoSeed.isRequested {
            do {
                try container.mainContext.delete(model: Job.self)
                try container.mainContext.delete(model: BusinessProfile.self)
                EvidenceStore.shared.removeAll()
                try DemoSeed.run(in: container.mainContext)
            } catch {
                Log.app.error("Demo seed failed: \(error.localizedDescription)")
            }
        }
        #endif
        return container
    }
}
