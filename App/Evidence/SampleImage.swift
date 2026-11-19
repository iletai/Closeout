#if DEBUG
import UIKit

/// Synthetic photo for UI tests (the simulator has no camera).
enum SampleImage {
    static func jpegData() -> Data {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 3000, height: 2000))
        return renderer.jpegData(withCompressionQuality: 0.9) { context in
            UIColor.systemTeal.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 3000, height: 2000))
        }
    }
}
#endif
