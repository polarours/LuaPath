# Stage 9: CLI Frameworks

**Stage**: 9 | **Time**: 8–12 hours
**Lua Versions**: 5.1, 5.3, 5.4, LuaJIT

## Overview

Create a command-line argument parser with flags, options, help generation, and version output.

- Topics: argument parsing, help text generation, subcommands, exit codes

## Project

| Project | Description | Skills |
|---------|-------------|--------|
| CLI Framework | A command-line argument parser handling flags, positional arguments, options with values, automatic help generation, and version output. | Command-line argument parsing; Automatic help text generation; Flag vs option distinction |

## Prerequisites

- Completion of the previous stage
- The chapters listed above

## How to Run

```bash
cd cli-framework
lua 01-cli-framework.lua --help
lua 01-cli-framework.lua --name Alice --verbose file.txt
```

Change into the project directory, then run the command above.
