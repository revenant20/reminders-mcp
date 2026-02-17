import Foundation

private let tagPattern = try! NSRegularExpression(pattern: "#[\\p{L}\\p{N}_]+")

/// Extracts tags from text by matching `#word` patterns. Returns tag names without `#`.
public func parseTags(_ text: String) -> [String] {
    let range = NSRange(text.startIndex..., in: text)
    let matches = tagPattern.matches(in: text, range: range)
    return matches.compactMap { match -> String? in
        guard let swiftRange = Range(match.range, in: text) else { return nil }
        return String(text[swiftRange].dropFirst()) // drop '#'
    }
}

/// Appends hashtags to the end of text. Only adds tags not already present.
public func addTags(_ tags: [String], to text: String) -> String {
    guard !tags.isEmpty else { return text }
    let existing = Set(parseTags(text).map { $0.lowercased() })
    let newTags = tags.filter { !existing.contains($0.lowercased()) }
    guard !newTags.isEmpty else { return text }
    let suffix = newTags.map { "#\($0)" }.joined(separator: " ")
    if text.isEmpty {
        return suffix
    }
    return text + " " + suffix
}

/// Removes hashtags from text. Matches are case-insensitive.
public func removeTags(_ tags: [String], from text: String) -> String {
    guard !tags.isEmpty else { return text }
    let tagsToRemove = Set(tags.map { $0.lowercased() })
    let range = NSRange(text.startIndex..., in: text)
    var result = text
    // Find all tag matches in reverse order so ranges stay valid
    let matches = tagPattern.matches(in: text, range: range).reversed()
    for match in matches {
        guard let swiftRange = Range(match.range, in: text) else { continue }
        let tagName = String(text[swiftRange].dropFirst())
        if tagsToRemove.contains(tagName.lowercased()) {
            // Also remove leading/trailing whitespace around the tag
            var removeStart = swiftRange.lowerBound
            var removeEnd = swiftRange.upperBound
            if removeStart > result.startIndex && result[result.index(before: removeStart)] == " " {
                removeStart = result.index(before: removeStart)
            } else if removeEnd < result.endIndex && result[removeEnd] == " " {
                removeEnd = result.index(after: removeEnd)
            }
            result.removeSubrange(removeStart..<removeEnd)
        }
    }
    return result.trimmingCharacters(in: .whitespaces)
}
