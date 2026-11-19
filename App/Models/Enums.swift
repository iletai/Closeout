import Foundation

enum JobStatus: String, CaseIterable, Sendable {
    case open, closed
}

enum PricingMode: String, CaseIterable, Sendable {
    case hourly, fixed
}

enum EvidenceKind: String, CaseIterable, Sendable {
    case site, before, after
}
