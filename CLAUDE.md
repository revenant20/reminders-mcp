# CLAUDE.md

## Build & Test

```bash
./build.sh          # Release build with code signing
swift build          # Debug build
swift test           # Run unit tests
```

Output binary: `.build/release/reminders-mcp`

## Project Structure

```
Sources/
  main.swift                          # MCP server, tool definitions, handlers, EventKit integration
  RemindersMCPCore/
    TagHelpers.swift                  # Tag parsing/add/remove via #hashtags in text
    DateHelpers.swift                 # ISO 8601 date parsing and formatting
Tests/
  RemindersMCPCoreTests/
    TagHelpersTests.swift
    DateHelpersTests.swift
```

Single-binary MCP server. All EventKit logic is in `main.swift`.

## Tech Stack

- Swift 6.0+, macOS 14+
- EventKit (Apple framework for Reminders access)
- [MCP Swift SDK](https://github.com/modelcontextprotocol/swift-sdk) v0.10.0+

## Key Conventions

- Async/await with `withCheckedContinuation` wrappers around EventKit's callback-based API
- Tags are stored as `#hashtag` text in notes (not native Reminders tags — EventKit has no API for those)
- Case-insensitive tag operations throughout
- Unicode-aware tag regex: `#[\p{L}\p{N}_]+`
- No Co-Authored-By in commits

## Known EventKit Limitations

- **No native tags API** — tags stored as hashtags in notes field
- **No sections API** — list sections not exposed by Apple
- **No flagged API** — `isFlagged` doesn't exist on EKReminder
- **No Shortcuts/AppleScript workaround** for tags either