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

/// The caption shown when a category name can't be saved, or nil when it's valid.
/// `isAvailable` is the `isCategoryNameAvailable(...)` result for the same name.
func categoryNameMessage(name: String, isAvailable: Bool) -> String? {
    if isAvailable { return nil }
    let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
    return trimmed.isEmpty ? "Enter a name." : "That name's already taken."
}
