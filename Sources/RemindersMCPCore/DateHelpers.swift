import Foundation

public let iso8601DateOnly: DateFormatter = {
    let f = DateFormatter()
    f.dateFormat = "yyyy-MM-dd"
    f.locale = Locale(identifier: "en_US_POSIX")
    return f
}()

public let iso8601DateTime: DateFormatter = {
    let f = DateFormatter()
    f.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
    f.locale = Locale(identifier: "en_US_POSIX")
    return f
}()

public func parseDate(_ string: String) -> Date? {
    if string.count <= 10 {
        return iso8601DateOnly.date(from: string)
    }
    return iso8601DateTime.date(from: string)
}

public func formatDate(_ date: Date) -> String {
    iso8601DateTime.string(from: date)
}
