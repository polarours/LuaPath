# Stage 30: Active Record Pattern

## Title
Active Record Pattern — Object-Relational Mapping for Lua

## Description
The Active Record pattern binds database rows to objects, where the object itself handles persistence. Each record knows how to save, find, and delete itself from the store. This pattern simplifies data access by co-locating data and behavior in a single class.

In this implementation, we use a Lua table as an in-memory store to demonstrate the pattern without external dependencies.

## Prerequisites
- Lua metatables and `__index`/`__newindex`
- Closures and function composition
- Understanding of object-oriented patterns in Lua
- Basic table manipulation

## How to Run
```bash
lua5.4 01-active-record.lua
```

## Key Concepts
- **Model class**: Defines schema, validations, and persistence methods
- **find**: Retrieve a record by ID from the store
- **save**: Insert or update a record in the store
- **delete**: Remove a record from the store
- **Validation**: Ensure data integrity before persistence
- **Callbacks**: Hook into lifecycle events (before_save, after_create)
- **Dirty tracking**: Detect which fields have changed
