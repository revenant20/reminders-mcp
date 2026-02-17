import Foundation
import Testing

@testable import RemindersMCPCore

@Suite("parseDate")
struct ParseDateTests {
    @Test("parses date-only string")
    func parseDateOnly() {
        let date = parseDate("2025-01-15")
        #expect(date != nil)
        let components = Calendar.current.dateComponents([.year, .month, .day], from: date!)
        #expect(components.year == 2025)
        #expect(components.month == 1)
        #expect(components.day == 15)
    }

    @Test("parses date with time")
    func parseDateTime() {
        let date = parseDate("2025-01-15T14:30:00")
        #expect(date != nil)
        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute, .second], from: date!)
        #expect(components.year == 2025)
        #expect(components.month == 1)
        #expect(components.day == 15)
        #expect(components.hour == 14)
        #expect(components.minute == 30)
        #expect(components.second == 0)
    }

    @Test("returns nil for invalid string")
    func parseInvalid() {
        #expect(parseDate("not-a-date") == nil)
    }

    @Test("returns nil for empty string")
    func parseEmpty() {
        #expect(parseDate("") == nil)
    }
}

@Suite("formatDate")
struct FormatDateTests {
    @Test("formats a known date")
    func formatKnownDate() {
        var components = DateComponents()
        components.year = 2025
        components.month = 1
        components.day = 15
        components.hour = 14
        components.minute = 30
        components.second = 0
        let date = Calendar.current.date(from: components)!
        #expect(formatDate(date) == "2025-01-15T14:30:00")
    }

    @Test("roundtrip: parseDate(formatDate(date)) == date")
    func roundtrip() {
        var components = DateComponents()
        components.year = 2025
        components.month = 6
        components.day = 20
        components.hour = 9
        components.minute = 15
        components.second = 45
        let date = Calendar.current.date(from: components)!
        let result = parseDate(formatDate(date))
        #expect(result == date)
    }
}
