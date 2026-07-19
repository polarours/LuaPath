# Stage 36: Event Sourcing

## Title
Event Sourcing — Immutable Event Log with Commands and Projections

## Description
Event sourcing stores all changes as a sequence of immutable events rather than overwriting current state. The current state is derived by replaying events. This provides a complete audit trail, enables temporal queries, and supports multiple read-optimized views (projections) of the same data.

This implementation covers the core event sourcing pattern: an append-only event store, command handlers that validate and emit events, and projections that build read models from the event stream.

## Prerequisites
- Lua tables and metatables
- Closures and functions as values
- Basic serialization concepts
- Understanding of state machines
- Familiarity with event-driven architecture

## How to Run
```bash
lua5.4 01-event-sourcing.lua
```

## Key Concepts
- **Event store**: Append-only log of all state-changing events
- **Commands**: Intentions to change state; validated by handlers before emitting events
- **Events**: Immutable facts about what happened, with timestamps and metadata
- **Aggregates**: Domain objects that enforce invariants during command processing
- **Projections**: Read-optimized views built by replaying events
- **Replay**: Rebuild current state by replaying all events from the beginning
- **Temporal queries**: Query state at any point in time by replaying events up to that timestamp
- **Event versioning**: Support for schema evolution across event versions
