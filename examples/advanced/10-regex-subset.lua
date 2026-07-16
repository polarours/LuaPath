-- Example 10: Pattern Matching (Regex Subset)
-- Chapter: 10-advanced
-- Difficulty: Advanced
-- Lua Version: 5.1+
--
-- Demonstrates: Lua pattern matching vs PCRE, common patterns, pattern tester
-- Shows: email validator, URL parser, CSV tokenizer, template engine

local M = {}

function M.show_pattern_syntax()
    print("=== Lua Pattern Syntax vs PCRE ===")
    print("Lua patterns: . %% ^ $ [ ] ( ) + - * ?")
    print()
    print("Lua ONLY:          Lua + PCRE:")
    print("  .  any char         (?=) lookahead")
    print("  %%d digit           (?<=) lookbehind")
    print("  %%a letter          (?:) non-capture")
    print("  %%s whitespace      {n,m} quantifier")
    print("  %%w alphanumeric    | alternation")
    print("  [^x] negated       \\b word boundary")
    print("  +-* greedy/lazy    backreferences \\1")
    print()
    print("Key difference: Lua has NO alternation (|) or lookahead.")
    print()
end

-- Email validator (simplified, Lua pattern style)
function M.validate_email(email)
    -- Basic pattern: chars@chars.chars
    local pattern = "^[%w%.%%%+%-]+@[%w%.%-]+%.%w%w%w?%w?$"
    return email:match(pattern) ~= nil
end

-- URL parser (simplified)
function M.parse_url(url)
    local scheme, host, path = url:match("^(%w+)://([^/]+)(.*)$")
    if not scheme then return nil end
    path = path == "" and "/" or path
    local query = path:match("%?(.+)$")
    path = path:gsub("%?.*$", "")
    return {
        scheme = scheme,
        host = host,
        path = path,
        query = query,
    }
end

-- CSV tokenizer (handles quoted fields)
function M.tokenize_csv(line)
    local fields = {}
    local field_start = 1
    local in_quotes = false

    for i = 1, #line do
        local c = line:sub(i, i)
        if c == '"' then
            in_quotes = not in_quotes
        elseif c == ',' and not in_quotes then
            fields[#fields + 1] = line:sub(field_start, i - 1):gsub('^"(.*)"$', '%1')
            field_start = i + 1
        end
    end
    fields[#fields + 1] = line:sub(field_start):gsub('^"(.*)"$', '%1')
    return fields
end

-- Simple template engine: ${var} substitution
function M.render_template(template, vars)
    return template:gsub("%$%{(%w+)%}", function(key)
        return vars[key] or ("${" .. key .. "}")
    end)
end

-- Pattern tester: show all matches
function M.test_pattern(pattern, text)
    print(string.format("Pattern: %s", pattern))
    print(string.format("Text:    %s", text))
    local matches = {}
    local pos = 1
    while pos <= #text do
        local s, e = text:find(pattern, pos)
        if not s then break end
        matches[#matches + 1] = text:sub(s, e)
        pos = e + 1
    end
    if #matches == 0 then
        print("  No matches.")
    else
        print(string.format("  %d match(es): %s", #matches, table.concat(matches, " | ")))
    end
    print()
end

-- Common Lua patterns library
function M.show_common_patterns()
    print("=== Common Lua Patterns ===")
    local patterns = {
        {"Digits only",     "^%d+$"},
        {"Letters only",    "^%a+$"},
        {"Alphanumeric",    "^%w+$"},
        {"Whitespace only", "^%s+$"},
        {"IP address",      "^%d+%.%d+%.%d+%.%d+$"},
        {"Date (YYYY-MM-DD)", "^%d%d%d%d%-%d%d%-%d%d$"},
        {"Hex color",       "^#?[%da-fA-F][%da-fA-F][%da-fA-F][%da-fA-F][%da-fA-F][%da-fA-F]$"},
        {"Lua identifier",  "^[%a_][%w_]*$"},
        {"File extension",  "%.([%w]+)$"},
    }
    for _, p in ipairs(patterns) do
        print(string.format("  %-22s %s", p[1], p[2]))
    end
    print()
end

-- Word frequency counter using patterns
function M.word_frequency(text)
    local freq = {}
    for word in text:lower():gmatch("%a+") do
        freq[word] = (freq[word] or 0) + 1
    end
    return freq
end

function M.main()
    print("Lua Pattern Matching Examples")
    print(string.rep("=", 40))
    print()

    M.show_pattern_syntax()
    M.show_common_patterns()

    -- Email validation
    print("=== Email Validation ===")
    local emails = {
        "user@example.com", "test.name+tag@domain.co",
        "@missing.com", "no-at-sign.com", "user@.com",
    }
    for _, e in ipairs(emails) do
        print(string.format("  %-30s %s", e, M.validate_email(e) and "VALID" or "INVALID"))
    end
    print()

    -- URL parsing
    print("=== URL Parser ===")
    local urls = {
        "https://example.com/path/to/page?q=hello&lang=en",
        "http://localhost:8080/api/v2",
        "ftp://files.example.org/readme.txt",
    }
    for _, u in ipairs(urls) do
        local parsed = M.parse_url(u)
        if parsed then
            print(string.format("  %s", u))
            print(string.format("    scheme=%s host=%s path=%s query=%s",
                parsed.scheme, parsed.host, parsed.path, parsed.query or "-"))
        end
    end
    print()

    -- CSV tokenizer
    print("=== CSV Tokenizer ===")
    local csv_lines = {
        'name,age,city',
        '"Smith, Jr.",30,"New York"',
        'alice,25,London',
    }
    for _, line in ipairs(csv_lines) do
        local fields = M.tokenize_csv(line)
        print(string.format("  %s -> {%s}", line, table.concat(fields, ", ")))
    end
    print()

    -- Template engine
    print("=== Template Engine ===")
    local tpl = "Hello ${name}, your order #${id} ships to ${city}."
    local vars = { name = "Alice", id = "12345", city = "Portland" }
    print(string.format("  Template: %s", tpl))
    print(string.format("  Rendered: %s", M.render_template(tpl, vars)))
    print()

    -- Pattern tester
    print("=== Pattern Test ===")
    M.test_pattern("%d+", "abc 123 def 456")
    M.test_pattern("%a+", "hello123world456")
    M.test_pattern("[aeiou]", "rhythm")
    print()

    -- Word frequency
    print("=== Word Frequency ===")
    local text = "the cat sat on the mat the cat ate the rat"
    local freq = M.word_frequency(text)
    local sorted = {}
    for w, c in pairs(freq) do sorted[#sorted + 1] = { w = w, c = c } end
    table.sort(sorted, function(a, b) return a.c > b.c end)
    for _, item in ipairs(sorted) do
        print(string.format("  %-8s %d", item.w, item.c))
    end
    print()
end

M.main()
return M
