import Foundation

/// Free plan holds `freeLimit` photos per job; Pro is unlimited.
enum PhotoQuota {
    static let freeLimit = 4

    static func remaining(existing: Int, isPro: Bool) -> Int {
        isPro ? .max : max(0, freeLimit - existing)
    }

    static func canAdd(_ count: Int, existing: Int, isPro: Bool) -> Bool {
        count <= remaining(existing: existing, isPro: isPro)
    }
}
