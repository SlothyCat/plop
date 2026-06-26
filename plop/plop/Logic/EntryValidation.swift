import Foundation

/// The caption shown when an expense can't be saved, or nil when it's valid.
func entryValidationMessage(hasAmount: Bool, hasCategory: Bool) -> String? {
    switch (hasAmount, hasCategory) {
    case (true, true):   return nil
    case (false, true):  return "Enter an amount."
    case (true, false):  return "Pick a category."
    case (false, false): return "Enter an amount and pick a category."
    }
}
