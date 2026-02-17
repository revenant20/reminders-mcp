// Copyright 2025 sazonovfm <sazonovfm@gmail.com>
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

@preconcurrency import EventKit
import Foundation
import MCP
import RemindersMCPCore

extension EKReminder: @unchecked @retroactive Sendable {}

// MARK: - EventKit Store

nonisolated(unsafe) let store = EKEventStore()

func ensureAccess() async throws {
    let status = EKEventStore.authorizationStatus(for: .reminder)
    switch status {
    case .authorized, .fullAccess:
        return
    case .notDetermined:
        let granted = try await store.requestFullAccessToReminders()
        guard granted else {
            throw MCPError.internalError("Reminders access denied by user")
        }
    default:
        throw MCPError.internalError(
            "Reminders access not available (status: \(status.rawValue)). Grant access in System Settings > Privacy > Reminders."
        )
    }
}

// MARK: - Tool Definitions

let listListsTool = Tool(
    name: "list_lists",
    description: "Get all reminder lists",
    inputSchema: .object(["type": .string("object")])
)

let listRemindersTool = Tool(
    name: "list_reminders",
    description: "Get reminders from a specific list",
    inputSchema: .object([
        "type": .string("object"),
        "properties": .object([
            "list_name": .object([
                "type": .string("string"),
                "description": .string("Name of the reminder list"),
            ]),
            "filter": .object([
                "type": .string("string"),
                "enum": .array([.string("incomplete"), .string("complete"), .string("all")]),
                "description": .string("Filter by completion status (default: incomplete)"),
            ]),
        ]),
        "required": .array([.string("list_name")]),
    ])
)

let createReminderTool = Tool(
    name: "create_reminder",
    description: "Create a new reminder",
    inputSchema: .object([
        "type": .string("object"),
        "properties": .object([
            "title": .object([
                "type": .string("string"),
                "description": .string("Reminder title"),
            ]),
            "notes": .object([
                "type": .string("string"),
                "description": .string("Reminder notes"),
            ]),
            "list_name": .object([
                "type": .string("string"),
                "description": .string("Name of the list to add to (default: default list)"),
            ]),
            "due_date": .object([
                "type": .string("string"),
                "description": .string(
                    "Due date in ISO 8601 format (YYYY-MM-DD or YYYY-MM-DDTHH:MM:SS)"),
            ]),
            "priority": .object([
                "type": .string("integer"),
                "description": .string("Priority: 0=none, 1=high, 5=medium, 9=low"),
            ]),
        ]),
        "required": .array([.string("title")]),
    ])
)

let updateReminderTool = Tool(
    name: "update_reminder",
    description:
        "Update an existing reminder. Pass only fields you want to change. Set due_date to empty string to remove it.",
    inputSchema: .object([
        "type": .string("object"),
        "properties": .object([
            "id": .object([
                "type": .string("string"),
                "description": .string("Reminder ID (calendarItemIdentifier)"),
            ]),
            "title": .object([
                "type": .string("string"),
                "description": .string("New title"),
            ]),
            "notes": .object([
                "type": .string("string"),
                "description": .string("New notes (empty string to clear)"),
            ]),
            "due_date": .object([
                "type": .string("string"),
                "description": .string(
                    "New due date in ISO 8601 format, or empty string to remove due date"),
            ]),
            "priority": .object([
                "type": .string("integer"),
                "description": .string("Priority: 0=none, 1=high, 5=medium, 9=low"),
            ]),
            "list_name": .object([
                "type": .string("string"),
                "description": .string("Move to a different list"),
            ]),
        ]),
        "required": .array([.string("id")]),
    ])
)

let completeReminderTool = Tool(
    name: "complete_reminder",
    description: "Mark a reminder as completed or uncompleted",
    inputSchema: .object([
        "type": .string("object"),
        "properties": .object([
            "id": .object([
                "type": .string("string"),
                "description": .string("Reminder ID (calendarItemIdentifier)"),
            ]),
            "completed": .object([
                "type": .string("boolean"),
                "description": .string("true to complete, false to uncomplete (default: true)"),
            ]),
        ]),
        "required": .array([.string("id")]),
    ])
)

let deleteReminderTool = Tool(
    name: "delete_reminder",
    description: "Delete a reminder permanently",
    inputSchema: .object([
        "type": .string("object"),
        "properties": .object([
            "id": .object([
                "type": .string("string"),
                "description": .string("Reminder ID (calendarItemIdentifier)"),
            ])
        ]),
        "required": .array([.string("id")]),
    ])
)

let searchRemindersTool = Tool(
    name: "search_reminders",
    description: "Search reminders by text across all lists",
    inputSchema: .object([
        "type": .string("object"),
        "properties": .object([
            "query": .object([
                "type": .string("string"),
                "description": .string("Search text (case-insensitive, matches title and notes)"),
            ]),
            "include_completed": .object([
                "type": .string("boolean"),
                "description": .string("Include completed reminders (default: false)"),
            ]),
        ]),
        "required": .array([.string("query")]),
    ])
)

let allTools = [
    listListsTool, listRemindersTool, createReminderTool,
    updateReminderTool, completeReminderTool, deleteReminderTool,
    searchRemindersTool,
]

// MARK: - Helpers

func findCalendar(named name: String) -> EKCalendar? {
    store.calendars(for: .reminder).first { $0.title == name }
}

func findReminder(id: String) -> EKReminder? {
    store.calendarItem(withIdentifier: id) as? EKReminder
}

func reminderToDict(_ r: EKReminder) -> [String: String] {
    var dict: [String: String] = [
        "id": r.calendarItemIdentifier,
        "title": r.title ?? "",
        "completed": r.isCompleted ? "true" : "false",
        "list": r.calendar?.title ?? "",
        "priority": "\(r.priority)",
    ]
    if let notes = r.notes, !notes.isEmpty {
        dict["notes"] = notes
    }
    if let comps = r.dueDateComponents, let date = Calendar.current.date(from: comps) {
        dict["due_date"] = formatDate(date)
    }
    if let completionDate = r.completionDate {
        dict["completion_date"] = formatDate(completionDate)
    }
    return dict
}

func reminderJSON(_ r: EKReminder) -> String {
    let dict = reminderToDict(r)
    let data = try! JSONSerialization.data(withJSONObject: dict, options: [.sortedKeys])
    return String(data: data, encoding: .utf8)!
}

func fetchReminders(matching predicate: NSPredicate) async -> [EKReminder] {
    await withCheckedContinuation { cont in
        store.fetchReminders(matching: predicate) { reminders in
            cont.resume(returning: reminders ?? [])
        }
    }
}

func fetchReminders(from calendars: [EKCalendar], includeCompleted: Bool, includeIncomplete: Bool)
    async -> [EKReminder]
{
    if includeCompleted && includeIncomplete {
        let incompletePred = store.predicateForIncompleteReminders(
            withDueDateStarting: nil, ending: nil, calendars: calendars)
        let completePred = store.predicateForCompletedReminders(
            withCompletionDateStarting: nil, ending: nil, calendars: calendars)
        let incomplete = await fetchReminders(matching: incompletePred)
        let complete = await fetchReminders(matching: completePred)
        return incomplete + complete
    }

    let predicate: NSPredicate
    if includeCompleted {
        predicate = store.predicateForCompletedReminders(
            withCompletionDateStarting: nil, ending: nil, calendars: calendars)
    } else {
        predicate = store.predicateForIncompleteReminders(
            withDueDateStarting: nil, ending: nil, calendars: calendars)
    }

    return await fetchReminders(matching: predicate)
}

// MARK: - Tool Handlers

func handleListLists() -> CallTool.Result {
    let calendars = store.calendars(for: .reminder)
    let items = calendars.map { cal -> [String: String] in
        ["name": cal.title, "id": cal.calendarIdentifier]
    }
    let data = try! JSONSerialization.data(withJSONObject: items, options: [.sortedKeys])
    return CallTool.Result(content: [.text(String(data: data, encoding: .utf8)!)])
}

func handleListReminders(_ params: CallTool.Parameters) async throws -> CallTool.Result {
    guard let listName = params.arguments?["list_name"]?.stringValue else {
        throw MCPError.invalidParams("list_name is required")
    }
    guard let calendar = findCalendar(named: listName) else {
        return CallTool.Result(
            content: [.text("List '\(listName)' not found")], isError: true)
    }

    let filter = params.arguments?["filter"]?.stringValue ?? "incomplete"
    let includeCompleted = filter == "complete" || filter == "all"
    let includeIncomplete = filter == "incomplete" || filter == "all"

    let reminders = await fetchReminders(
        from: [calendar], includeCompleted: includeCompleted,
        includeIncomplete: includeIncomplete)

    let items = reminders.map { reminderToDict($0) }
    let data = try! JSONSerialization.data(withJSONObject: items, options: [.sortedKeys])
    return CallTool.Result(content: [.text(String(data: data, encoding: .utf8)!)])
}

func handleCreateReminder(_ params: CallTool.Parameters) throws -> CallTool.Result {
    guard let title = params.arguments?["title"]?.stringValue else {
        throw MCPError.invalidParams("title is required")
    }

    let reminder = EKReminder(eventStore: store)
    reminder.title = title

    if let notes = params.arguments?["notes"]?.stringValue {
        reminder.notes = notes
    }

    if let listName = params.arguments?["list_name"]?.stringValue {
        guard let calendar = findCalendar(named: listName) else {
            return CallTool.Result(
                content: [.text("List '\(listName)' not found")], isError: true)
        }
        reminder.calendar = calendar
    } else {
        reminder.calendar = store.defaultCalendarForNewReminders()
    }

    if let dueDateStr = params.arguments?["due_date"]?.stringValue {
        if let date = parseDate(dueDateStr) {
            reminder.dueDateComponents = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute, .second], from: date)
        }
    }

    if let priority = params.arguments?["priority"]?.intValue {
        reminder.priority = priority
    }

    try store.save(reminder, commit: true)

    return CallTool.Result(content: [.text(reminderJSON(reminder))])
}

func handleUpdateReminder(_ params: CallTool.Parameters) throws -> CallTool.Result {
    guard let id = params.arguments?["id"]?.stringValue else {
        throw MCPError.invalidParams("id is required")
    }
    guard let reminder = findReminder(id: id) else {
        return CallTool.Result(
            content: [.text("Reminder with id '\(id)' not found")], isError: true)
    }

    if let title = params.arguments?["title"]?.stringValue {
        reminder.title = title
    }

    if let notes = params.arguments?["notes"]?.stringValue {
        reminder.notes = notes.isEmpty ? nil : notes
    }

    if let dueDateStr = params.arguments?["due_date"]?.stringValue {
        if dueDateStr.isEmpty {
            reminder.dueDateComponents = nil
        } else if let date = parseDate(dueDateStr) {
            reminder.dueDateComponents = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute, .second], from: date)
        }
    }

    if let priority = params.arguments?["priority"]?.intValue {
        reminder.priority = priority
    }

    if let listName = params.arguments?["list_name"]?.stringValue {
        if let calendar = findCalendar(named: listName) {
            reminder.calendar = calendar
        } else {
            return CallTool.Result(
                content: [.text("List '\(listName)' not found")], isError: true)
        }
    }

    try store.save(reminder, commit: true)

    return CallTool.Result(content: [.text(reminderJSON(reminder))])
}

func handleCompleteReminder(_ params: CallTool.Parameters) throws -> CallTool.Result {
    guard let id = params.arguments?["id"]?.stringValue else {
        throw MCPError.invalidParams("id is required")
    }
    guard let reminder = findReminder(id: id) else {
        return CallTool.Result(
            content: [.text("Reminder with id '\(id)' not found")], isError: true)
    }

    let completed = params.arguments?["completed"]?.boolValue ?? true
    reminder.isCompleted = completed
    if completed {
        reminder.completionDate = Date()
    } else {
        reminder.completionDate = nil
    }

    try store.save(reminder, commit: true)

    return CallTool.Result(content: [.text(reminderJSON(reminder))])
}

func handleDeleteReminder(_ params: CallTool.Parameters) throws -> CallTool.Result {
    guard let id = params.arguments?["id"]?.stringValue else {
        throw MCPError.invalidParams("id is required")
    }
    guard let reminder = findReminder(id: id) else {
        return CallTool.Result(
            content: [.text("Reminder with id '\(id)' not found")], isError: true)
    }

    let title = reminder.title ?? ""
    try store.remove(reminder, commit: true)

    return CallTool.Result(content: [.text("Deleted reminder: \(title)")])
}

func handleSearchReminders(_ params: CallTool.Parameters) async throws -> CallTool.Result {
    guard let query = params.arguments?["query"]?.stringValue else {
        throw MCPError.invalidParams("query is required")
    }
    let includeCompleted = params.arguments?["include_completed"]?.boolValue ?? false

    let calendars = store.calendars(for: .reminder)
    let reminders = await fetchReminders(
        from: calendars, includeCompleted: true, includeIncomplete: true)

    let lowerQuery = query.lowercased()
    let matched = reminders.filter { r in
        let titleMatch = r.title?.lowercased().contains(lowerQuery) ?? false
        let notesMatch = r.notes?.lowercased().contains(lowerQuery) ?? false
        let statusMatch = includeCompleted || !r.isCompleted
        return (titleMatch || notesMatch) && statusMatch
    }

    let items = matched.map { reminderToDict($0) }
    let data = try! JSONSerialization.data(withJSONObject: items, options: [.sortedKeys])
    return CallTool.Result(content: [.text(String(data: data, encoding: .utf8)!)])
}

// MARK: - Server Setup

let server = Server(
    name: "reminders-mcp",
    version: "1.0.0",
    capabilities: .init(tools: .init(listChanged: false))
)

await server.withMethodHandler(ListTools.self) { _ in
    ListTools.Result(tools: allTools)
}

await server.withMethodHandler(CallTool.self) { params in
    try await ensureAccess()

    switch params.name {
    case "list_lists":
        return handleListLists()
    case "list_reminders":
        return try await handleListReminders(params)
    case "create_reminder":
        return try handleCreateReminder(params)
    case "update_reminder":
        return try handleUpdateReminder(params)
    case "complete_reminder":
        return try handleCompleteReminder(params)
    case "delete_reminder":
        return try handleDeleteReminder(params)
    case "search_reminders":
        return try await handleSearchReminders(params)
    default:
        throw MCPError.invalidParams("Unknown tool: \(params.name)")
    }
}

let transport = StdioTransport()
try await server.start(transport: transport)
await server.waitUntilCompleted()
