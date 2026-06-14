import Foundation

/// True if `name` (trimmed, non-empty) is not already used by another category.
/// Case-insensitive. When `editing`, that category keeps its own name.
func isCategoryNameAvailable(_ name: String,
                             existing: [ExpenseCategory],
                             editing: ExpenseCategory? = nil) -> Bool {
    let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return false }
    return !existing.contains { other in
        if let editing, other === editing { return false }
        return other.name.caseInsensitiveCompare(trimmed) == .orderedSame
    }
}
