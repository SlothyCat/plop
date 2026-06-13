import Foundation

/// Stored on a transaction now; the generation engine arrives in Feature 2.
enum RecurrenceInterval: String, Codable, CaseIterable {
    case none
    case daily
    case weekly
    case monthly
    case yearly
}
