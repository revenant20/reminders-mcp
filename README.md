# reminders-mcp

[![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](LICENSE)

MCP server for Apple Reminders on macOS. Built with Swift and EventKit.

[Документация на русском](README.ru.md)

## Why This Server

- **Native Swift binary.** No Node.js, Python, or any other runtime required. Single compiled binary — just works.
- **EventKit, not AppleScript.** Direct access to the Reminders database through the official Apple framework. Faster and more reliable than AppleScript-based alternatives.
- **Lightweight.** Minimal dependencies — only the [MCP Swift SDK](https://github.com/modelcontextprotocol/swift-sdk). No heavy frameworks or abstraction layers.
- **Properly signed.** The build script signs the binary with the required entitlements for Reminders access out of the box.

## Tools

### list_lists

Get all reminder lists.

Parameters: none.

### list_reminders

Get reminders from a specific list.

| Parameter | Type | Required | Description |
|---|---|---|---|
| `list_name` | string | yes | Name of the reminder list |
| `filter` | string | no | `incomplete` (default), `complete`, or `all` |

### create_reminder

Create a new reminder.

| Parameter | Type | Required | Description |
|---|---|---|---|
| `title` | string | yes | Reminder title |
| `notes` | string | no | Reminder notes |
| `list_name` | string | no | List name (default: default list) |
| `due_date` | string | no | Due date in ISO 8601 (`YYYY-MM-DD` or `YYYY-MM-DDTHH:MM:SS`) |
| `priority` | integer | no | Priority: 0=none, 1=high, 5=medium, 9=low |
| `tags` | string[] | no | Tags (without `#`). Appended as hashtags to notes |

### update_reminder

Update an existing reminder. Pass only the fields you want to change.

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id` | string | yes | Reminder ID (`calendarItemIdentifier`) |
| `title` | string | no | New title |
| `notes` | string | no | New notes (empty string to clear) |
| `due_date` | string | no | New due date in ISO 8601 (empty string to remove) |
| `priority` | integer | no | Priority |
| `list_name` | string | no | Move to a different list |
| `add_tags` | string[] | no | Tags to add (without `#`). Appended as hashtags to notes |
| `remove_tags` | string[] | no | Tags to remove (without `#`). Removed from both title and notes |

### complete_reminder

Mark a reminder as completed or uncompleted.

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id` | string | yes | Reminder ID |
| `completed` | boolean | no | `true` to complete, `false` to uncomplete (default: `true`) |

### delete_reminder

Delete a reminder permanently.

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id` | string | yes | Reminder ID |

### search_reminders

Search reminders by text and/or tag across all lists.

| Parameter | Type | Required | Description |
|---|---|---|---|
| `query` | string | no* | Search text (case-insensitive, matches title and notes) |
| `tag` | string | no* | Filter by tag (without `#`) |
| `include_completed` | boolean | no | Include completed reminders (default: `false`) |

\* At least `query` or `tag` must be provided.

## Tags

Apple Reminders recognizes hashtags (`#work`, `#shopping`) in reminder text as tags. The server leverages this:

- **Creating** a reminder — the `tags` parameter appends hashtags to notes
- **Updating** — `add_tags` appends new tags to notes, `remove_tags` removes them from title and notes
- **Reading** — the `tags` field in the response contains all tags found in title and notes
- **Searching** — the `tag` parameter filters reminders by tag

## Known Limitations

- **Sections within lists are not supported.** Apple introduced sections in the Reminders UI starting with macOS Sonoma, but has not exposed them in the public EventKit API. Waiting for Apple to add this.

## Build

```bash
./build.sh
```

## Test

```bash
swift test
```
