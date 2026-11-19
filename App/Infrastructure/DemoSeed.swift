#if DEBUG
import SwiftData
import UIKit

/// Store-screenshot data (launch argument `-closeoutDemoSeed`): fictional jobs with synthetic photos.
/// Compiled out of Release builds, so no demo content ships.
@MainActor
enum DemoSeed {
    static var isRequested: Bool { ProcessInfo.processInfo.arguments.contains("-closeoutDemoSeed") }

    static func run(in context: ModelContext) throws {
        let profile = BusinessProfile(currencyCode: "USD")
        profile.businessName = "Carter Home Services"
        profile.ownerName = "Alex Carter"
        profile.phone = "(555) 010-0142"
        profile.email = "hello@example.com"
        profile.defaultHourlyRate = 85
        context.insert(profile)

        let kitchen = job(139, "Marta Ruiz", "214 Alder St, Portland", daysAgo: 2, hours: 6.5, materials: 120)
        kitchen.notes = "Replaced corroded drain line under the sink. Pressure-tested, no leaks."
        context.insert(kitchen)
        let scenes: [Shot] = [
            Shot(scene: .corroded, caption: "Corroded drain before repair", kind: .before),
            Shot(scene: .leak, caption: "Active leak at the joint", kind: .before),
            Shot(scene: .valve, caption: "Shut-off valve", kind: .site),
            Shot(scene: .copper, caption: "New copper line", kind: .after),
            Shot(scene: .copperTrap, caption: "New trap installed", kind: .after),
            Shot(scene: .copperClean, caption: "Pressure test done", kind: .after)
        ]
        for (index, shot) in scenes.enumerated() {
            let photo = EvidencePhoto(fileName: try EvidenceStore.shared.save(shot.scene.jpegData()), caption: shot.caption, kind: shot.kind)
            photo.capturedAt = .now.addingTimeInterval(-Double(172_000 - index * 600))
            photo.job = kitchen
            context.insert(photo)
        }
        for (merchant, total, confidence) in [("Home Depot", Decimal(string: "84.37") ?? 0, 0.94),
                                              ("Ferguson Supply", Decimal(string: "46.12") ?? 0, 0.91)] {
            let receipt = Receipt(merchantName: merchant, total: total, currencyCode: "USD",
                                  purchasedAt: .now.addingTimeInterval(-170_000), ocrConfidence: confidence)
            receipt.job = kitchen
            context.insert(receipt)
        }
        let trip = MileageEntry(date: .now.addingTimeInterval(-172_000), miles: 18.4, startLabel: "Depot",
                                endLabel: "Alder St", ratePerMile: profile.defaultMileageRate)
        trip.job = kitchen
        context.insert(trip)

        let others = [
            job(140, "Kestrel Plumbing", "58 Harbor Way", daysAgo: 4, fixed: 1_480),
            job(141, "Dana Whitfield", "902 Birch Ave", daysAgo: 6, hours: 3, materials: 64),
            job(142, "Oakline HOA", "12 Oakline Ct", daysAgo: 9, fixed: 2_250),
            job(138, "Priya Nair", "77 Cedar Row", daysAgo: 20, hours: 4, materials: 38, closed: true)
        ]
        others.forEach { context.insert($0) }
        try context.save()
    }

    private struct Shot {
        let scene: Scene
        let caption: String
        let kind: EvidenceKind
    }

    private static func job(_ number: Int, _ client: String, _ address: String, daysAgo: Int, hours: Double = 0,
                            materials: Decimal = 0, fixed: Decimal = 0, closed: Bool = false) -> Job {
        let job = Job()
        job.number = number
        job.clientName = client
        job.siteAddress = address
        job.startedAt = .now.addingTimeInterval(-Double(daysAgo) * 86_400)
        job.pricing = fixed > 0 ? .fixed : .hourly
        job.fixedPrice = fixed
        job.hourlyRate = 85
        job.laborHours = hours
        job.materialsTotal = materials
        if closed {
            job.status = .closed
            job.closedAt = job.startedAt.addingTimeInterval(86_400)
        }
        return job
    }

    /// Stylised under-sink scenes drawn in code (the simulator has no camera).
    enum Scene {
        case corroded, leak, valve, copper, copperTrap, copperClean

        func jpegData() -> Data {
            UIGraphicsImageRenderer(size: CGSize(width: 1600, height: 1200)).jpegData(withCompressionQuality: 0.85) { ctx in
                draw(in: ctx.cgContext)
            }
        }

        private var isOld: Bool { self == .corroded || self == .leak }

        private func draw(in cg: CGContext) {
            let wall: UIColor = isOld ? UIColor(red: 0.45, green: 0.47, blue: 0.5, alpha: 1) : UIColor(red: 0.82, green: 0.85, blue: 0.86, alpha: 1)
            wall.setFill()
            cg.fill(CGRect(x: 0, y: 0, width: 1600, height: 1200))
            UIColor.black.withAlphaComponent(0.12).setStroke()
            cg.setLineWidth(5)
            for step in stride(from: 0, through: 1600, by: 200) {
                cg.move(to: CGPoint(x: step, y: 0)); cg.addLine(to: CGPoint(x: step, y: 1200))
                cg.move(to: CGPoint(x: 0, y: step * 3 / 4)); cg.addLine(to: CGPoint(x: 1600, y: step * 3 / 4))
            }
            cg.strokePath()
            // Vary the framing so the thumbnails do not look identical.
            switch self {
            case .copperTrap: cg.translateBy(x: -300, y: 60); cg.scaleBy(x: 1.25, y: 1.25)
            case .copperClean: cg.translateBy(x: 200, y: -120); cg.scaleBy(x: 0.9, y: 0.9)
            case .valve: cg.translateBy(x: -200, y: 120)
            default: break
            }
            UIColor(red: 0.3, green: 0.2, blue: 0.14, alpha: 1).setFill()
            cg.fill(CGRect(x: 0, y: 940, width: 1600, height: 260))
            let pipe: UIColor = isOld ? UIColor(red: 0.45, green: 0.3, blue: 0.2, alpha: 1) : UIColor(red: 0.85, green: 0.5, blue: 0.3, alpha: 1)
            stroke(cg, pipe, [(CGPoint(x: -20, y: 360), CGPoint(x: 820, y: 360)), (CGPoint(x: 820, y: 360), CGPoint(x: 820, y: 700))])
            let trap = UIBezierPath(arcCenter: CGPoint(x: 960, y: 700), radius: 140, startAngle: .pi, endAngle: 0, clockwise: false)
            trap.addLine(to: CGPoint(x: 1100, y: 360)); trap.addLine(to: CGPoint(x: 1620, y: 360))
            pipe.setStroke(); trap.lineWidth = 78; trap.lineCapStyle = .round; trap.stroke()
            UIColor.white.withAlphaComponent(isOld ? 0.08 : 0.35).setStroke()
            trap.lineWidth = 14; trap.apply(CGAffineTransform(translationX: -18, y: -18)); trap.stroke()
            decorate(cg)
        }

        private func stroke(_ cg: CGContext, _ color: UIColor, _ segments: [(CGPoint, CGPoint)]) {
            cg.setLineCap(.round)
            for (width, shade) in [(CGFloat(78), color), (CGFloat(14), UIColor.white.withAlphaComponent(isOld ? 0.08 : 0.35))] {
                shade.setStroke(); cg.setLineWidth(width)
                for segment in segments {
                    let offset: CGFloat = width < 78 ? -18 : 0
                    cg.move(to: CGPoint(x: segment.0.x + offset, y: segment.0.y + offset))
                    cg.addLine(to: CGPoint(x: segment.1.x + offset, y: segment.1.y + offset))
                }
                cg.strokePath()
            }
        }

        private func decorate(_ cg: CGContext) {
            if self == .corroded || self == .leak {
                UIColor(red: 0.7, green: 0.3, blue: 0.1, alpha: 0.8).setFill()
                for spot in [CGPoint(x: 300, y: 380), CGPoint(x: 560, y: 340), CGPoint(x: 830, y: 520), CGPoint(x: 960, y: 800)] {
                    cg.fillEllipse(in: CGRect(x: spot.x - 40, y: spot.y - 26, width: 80, height: 52))
                }
            }
            if self == .leak {
                UIColor(red: 0.45, green: 0.7, blue: 0.9, alpha: 0.85).setFill()
                for drop in [CGPoint(x: 830, y: 780), CGPoint(x: 835, y: 860), CGPoint(x: 828, y: 930)] {
                    cg.fillEllipse(in: CGRect(x: drop.x - 18, y: drop.y - 26, width: 36, height: 52))
                }
            }
            if self == .valve {
                UIColor(red: 0.75, green: 0.76, blue: 0.78, alpha: 1).setFill()
                cg.fillEllipse(in: CGRect(x: 700, y: 240, width: 240, height: 240))
                UIColor(red: 0.76, green: 0.25, blue: 0.05, alpha: 1).setFill()
                cg.fill(CGRect(x: 640, y: 330, width: 360, height: 60))
            }
        }
    }
}
#endif
