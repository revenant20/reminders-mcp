import Foundation
import Testing

@testable import RemindersMCPCore

@Suite("parseTags")
struct ParseTagsTests {
    @Test("extracts single tag")
    func singleTag() {
        #expect(parseTags("Buy milk #shopping") == ["shopping"])
    }

    @Test("extracts multiple tags")
    func multipleTags() {
        #expect(parseTags("Task #work #urgent") == ["work", "urgent"])
    }

    @Test("returns empty for no tags")
    func noTags() {
        #expect(parseTags("Just a plain reminder").isEmpty)
    }

    @Test("returns empty for empty string")
    func emptyString() {
        #expect(parseTags("").isEmpty)
    }

    @Test("handles tags with numbers")
    func numbersInTags() {
        #expect(parseTags("Release #v2 #2024") == ["v2", "2024"])
    }

    @Test("handles tags with underscores")
    func underscoresInTags() {
        #expect(parseTags("Fix #bug_fix #to_do") == ["bug_fix", "to_do"])
    }

    @Test("handles unicode tags")
    func unicodeTags() {
        #expect(parseTags("Задача #работа #срочно") == ["работа", "срочно"])
    }

    @Test("ignores hash without word")
    func hashAlone() {
        #expect(parseTags("Issue # and more").isEmpty)
    }

    @Test("tag at start of string")
    func tagAtStart() {
        #expect(parseTags("#important do this") == ["important"])
    }
}

@Suite("addTags")
struct AddTagsTests {
    @Test("adds tags to text")
    func addToText() {
        #expect(addTags(["work", "urgent"], to: "My task") == "My task #work #urgent")
    }

    @Test("skips already existing tags")
    func skipExisting() {
        #expect(addTags(["work", "new"], to: "Task #work") == "Task #work #new")
    }

    @Test("case-insensitive duplicate check")
    func caseInsensitive() {
        #expect(addTags(["Work"], to: "Task #work") == "Task #work")
    }

    @Test("adds to empty string")
    func emptyText() {
        #expect(addTags(["tag"], to: "") == "#tag")
    }

    @Test("no tags to add")
    func noTags() {
        #expect(addTags([], to: "Text") == "Text")
    }

    @Test("all tags already exist")
    func allExist() {
        #expect(addTags(["a", "b"], to: "Text #a #b") == "Text #a #b")
    }
}

@Suite("removeTags")
struct RemoveTagsTests {
    @Test("removes a tag from text")
    func removeOne() {
        #expect(removeTags(["work"], from: "Task #work #urgent") == "Task #urgent")
    }

    @Test("removes all tags")
    func removeAll() {
        #expect(removeTags(["work", "urgent"], from: "Task #work #urgent") == "Task")
    }

    @Test("case-insensitive removal")
    func caseInsensitive() {
        #expect(removeTags(["Work"], from: "Task #work") == "Task")
    }

    @Test("no tags to remove")
    func noTags() {
        #expect(removeTags([], from: "Task #work") == "Task #work")
    }

    @Test("tag not found — text unchanged")
    func tagNotFound() {
        #expect(removeTags(["missing"], from: "Task #work") == "Task #work")
    }

    @Test("removes tag from beginning")
    func tagAtStart() {
        #expect(removeTags(["important"], from: "#important do this") == "do this")
    }
}
