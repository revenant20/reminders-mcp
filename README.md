# reminders-mcp

[![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](LICENSE)

MCP server for Apple Reminders on macOS. Built with Swift and EventKit.

[Документация на русском](README.ru.md)

## Why This Server

- **Native Swift binary.** No Node.js, Python, or any other runtime required. Single compiled binary — just works.
- **EventKit, not AppleScript.** Direct access to the Reminders database through the official Apple framework. Faster and more reliable than AppleScript-based alternatives.
- **Lightweight.** Minimal dependencies — only the [MCP Swift SDK](https://github.com/modelcontextprotocol/swift-sdk). No heavy frameworks or abstraction layers.
- **Properly signed.** The build script signs the binary with the required entitlements for Reminders access out of the box.

## Features

- List all reminder lists
- Get reminders from a list (filter by completion status)
- Create, update, delete reminders
- Mark reminders as completed/uncompleted
- Search reminders by text

## Known Limitations

- **Sections within lists are not supported.** Apple introduced sections in the Reminders UI starting with macOS Sonoma, but has not exposed them in the public EventKit API. Waiting for Apple to add this.

## Build

```bash
./build.sh
```