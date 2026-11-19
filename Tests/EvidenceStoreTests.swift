import Foundation
import ImageIO
import SwiftData
import Testing
import UIKit
@testable import Closeout

struct EvidenceStoreTests {
    private func makeStore() -> EvidenceStore {
        EvidenceStore(directory: FileManager.default.temporaryDirectory.appending(path: "evidence-\(UUID().uuidString)"))
    }

    private func jpeg(width: CGFloat, height: CGFloat) -> Data {
        UIGraphicsImageRenderer(size: CGSize(width: width, height: height)).jpegData(withCompressionQuality: 1) { context in
            UIColor.orange.setFill()
            context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        }
    }

    private func pixelSize(of url: URL) -> (width: Int, height: Int)? {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              let props = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
              let width = props[kCGImagePropertyPixelWidth] as? Int,
              let height = props[kCGImagePropertyPixelHeight] as? Int else { return nil }
        return (width, height)
    }

    @Test func savesFileAndDownscalesLongEdge() throws {
        let store = makeStore()
        defer { store.removeAll() }
        let name = try store.save(jpeg(width: 3000, height: 2000))
        #expect(store.exists(name))
        let size = try #require(pixelSize(of: store.url(for: name)))
        #expect(max(size.width, size.height) <= EvidenceStore.maxLongEdge)
        #expect(max(size.width, size.height) == EvidenceStore.maxLongEdge)
    }

    @Test func smallImageIsNotUpscaled() throws {
        let store = makeStore()
        defer { store.removeAll() }
        let name = try store.save(jpeg(width: 400, height: 300))
        let size = try #require(pixelSize(of: store.url(for: name)))
        // Screen scale of the renderer can multiply pixels; the point is: never grow beyond the source.
        #expect(max(size.width, size.height) <= 1200)
    }

    @Test func garbageDataThrows() {
        let store = makeStore()
        #expect(throws: EvidenceError.self) { try store.save(Data("not an image".utf8)) }
    }

    @Test func deletingJobRemovesPhotoFiles() throws {
        let store = makeStore()
        defer { store.removeAll() }
        let context = ModelContext(try AppSchema.makeContainer(inMemory: true))
        let job = Job()
        context.insert(job)
        let name = try store.save(jpeg(width: 800, height: 600))
        job.photos.append(EvidencePhoto(fileName: name))
        try context.save()
        #expect(store.exists(name))

        try JobService.delete(job, in: context, store: store)
        #expect(!store.exists(name))
        #expect(try context.fetchCount(FetchDescriptor<EvidencePhoto>()) == 0)
    }
}

struct PhotoQuotaTests {
    @Test func freeTierCapsAtFour() {
        #expect(PhotoQuota.remaining(existing: 0, isPro: false) == 4)
        #expect(PhotoQuota.remaining(existing: 3, isPro: false) == 1)
        #expect(PhotoQuota.remaining(existing: 6, isPro: false) == 0)
        #expect(PhotoQuota.canAdd(1, existing: 3, isPro: false))
        #expect(!PhotoQuota.canAdd(2, existing: 3, isPro: false))
    }

    @Test func proIsUnlimited() {
        #expect(PhotoQuota.canAdd(100, existing: 50, isPro: true))
    }
}
