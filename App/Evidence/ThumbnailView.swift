import SwiftUI

/// Square thumbnail of a stored evidence image, decoded off the main thread.
struct ThumbnailView: View {
    let fileName: String
    var maxPixel = 300
    @State private var image: CGImage?

    var body: some View {
        Color.line
            .overlay {
                if let image {
                    Image(decorative: image, scale: 1).resizable().scaledToFill()
                }
            }
            .clipped()
            .task(id: fileName) {
                let name = fileName
                let pixels = maxPixel
                image = await Task.detached { EvidenceStore.shared.thumbnail(name, maxPixel: pixels) }.value
            }
    }
}
