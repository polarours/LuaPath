--[[
  Example: Command Pattern
  Chapter: Stage 19 — Advanced
  Difficulty: Advanced
  Lua Version: 5.4
  Demonstrates: Command encapsulation, undo/redo stack, macro recording and playback
]]

local CommandExecutor = {}
CommandExecutor.__index = CommandExecutor

function CommandExecutor:new()
    local self = setmetatable({}, CommandExecutor)
    self.undoStack = {}
    self.redoStack = {}
    self.macro = nil
    self.macroName = nil
    return self
end

function CommandExecutor:execute(command)
    command:execute()
    self.undoStack[#self.undoStack + 1] = command
    self.redoStack = {}
    if self.macro then self.macro[#self.macro + 1] = command end
end

function CommandExecutor:undo()
    if #self.undoStack == 0 then print("  Nothing to undo"); return false end
    local cmd = table.remove(self.undoStack)
    cmd:undo()
    self.redoStack[#self.redoStack + 1] = cmd
    return true
end

function CommandExecutor:redo()
    if #self.redoStack == 0 then print("  Nothing to redo"); return false end
    local cmd = table.remove(self.redoStack)
    cmd:execute()
    self.undoStack[#self.undoStack + 1] = cmd
    return true
end

function CommandExecutor:startMacro(name)
    self.macro = {}
    self.macroName = name
    print("  Recording macro: " .. name)
end

function CommandExecutor:stopMacro()
    local macro = self.macro
    self.macro = nil
    self.macroName = nil
    print("  Macro recorded: " .. tostring(#macro) .. " commands")
    return macro
end

function CommandExecutor:playMacro(macro)
    print("  Playing macro...")
    for _, cmd in ipairs(macro) do
        cmd:execute()
        self.undoStack[#self.undoStack + 1] = cmd
    end
end

function CommandExecutor:history()
    print("  Undo stack:", #self.undoStack, "commands")
    print("  Redo stack:", #self.redoStack, "commands")
end

-- Concrete Commands
local InsertCommand = {}
InsertCommand.__index = InsertCommand
function InsertCommand:new(buffer, text, position)
    return setmetatable({ buffer = buffer, text = text, position = position }, InsertCommand)
end
function InsertCommand:execute()
    table.insert(self.buffer, self.position, self.text)
    print("    Inserted '" .. self.text .. "' at position " .. self.position)
end
function InsertCommand:undo()
    table.remove(self.buffer, self.position)
    print("    Undid insert at position " .. self.position)
end

local DeleteCommand = {}
DeleteCommand.__index = DeleteCommand
function DeleteCommand:new(buffer, position)
    return setmetatable({ buffer = buffer, position = position, text = buffer[position] }, DeleteCommand)
end
function DeleteCommand:execute()
    self.text = table.remove(self.buffer, self.position)
    print("    Deleted '" .. self.text .. "' from position " .. self.position)
end
function DeleteCommand:undo()
    table.insert(self.buffer, self.position, self.text)
    print("    Undid delete, restored '" .. self.text .. "'")
end

local ReplaceCommand = {}
ReplaceCommand.__index = ReplaceCommand
function ReplaceCommand:new(buffer, position, newText)
    return setmetatable({ buffer = buffer, position = position, newText = newText }, ReplaceCommand)
end
function ReplaceCommand:execute()
    self.oldText = self.buffer[self.position]
    self.buffer[self.position] = self.newText
    print("    Replaced '" .. self.oldText .. "' with '" .. self.newText .. "'")
end
function ReplaceCommand:undo()
    self.buffer[self.position] = self.oldText
    print("    Undid replace, restored '" .. self.oldText .. "'")
end

-- Demo
local function main()
    print("=== Command Pattern Demo ===\n")
    local executor = CommandExecutor:new()
    local buffer = {}
    print("--- Execute commands ---")
    executor:execute(InsertCommand:new(buffer, "hello", 1))
    executor:execute(InsertCommand:new(buffer, "world", 2))
    executor:execute(InsertCommand:new(buffer, "lua", 2))
    print("  Buffer:", table.concat(buffer, ", "))
    print("\n--- Undo twice ---")
    executor:undo()
    executor:undo()
    print("  Buffer:", table.concat(buffer, ", "))
    print("\n--- Redo once ---")
    executor:redo()
    print("  Buffer:", table.concat(buffer, ", "))
    print("\n--- Macro recording ---")
    executor:startMacro("build-list")
    executor:execute(InsertCommand:new(buffer, "alpha", #buffer + 1))
    executor:execute(InsertCommand:new(buffer, "beta", #buffer + 1))
    executor:execute(InsertCommand:new(buffer, "gamma", #buffer + 1))
    local macro = executor:stopMacro()
    print("  Buffer:", table.concat(buffer, ", "))
    print("\n--- History ---")
    executor:history()
    print("\n--- Replace command ---")
    executor:execute(ReplaceCommand:new(buffer, 2, "WORLD"))
    print("  Buffer:", table.concat(buffer, ", "))
    executor:undo()
    print("  After undo:", table.concat(buffer, ", "))
    print("\n=== Command pattern complete ===")
end

main()
