name: Bug Report
description: Report an error or inaccuracy in the content
labels: ["bug", "needs-triage"]
body:
  - type: markdown
    attributes:
      value: |
        Thanks for taking the time to report an issue! Please fill out this form to help us understand the problem.
        
  - type: input
    id: chapter
    attributes:
      label: Affected Chapter(s)
      description: Which chapter(s) does this bug affect? (e.g., "04-tables.md", "en/10-lua-internals.md")
      placeholder: "e.g., 04-tables.md"
    validations:
      required: true
      
  - type: dropdown
    id: language
    attributes:
      label: Language Version
      description: Which language track is affected?
      options:
        - English (en/)
        - 简体中文 (zh/)
        - Both
    validations:
      required: true
      
  - type: dropdown
    id: lua-version
    attributes:
      label: Lua Version
      description: Which Lua version(s) does this affect?
      options:
        - All versions
        - Lua 5.1 only
        - Lua 5.3 only
        - Lua 5.4 only
        - LuaJIT only
        - Multiple (specify in description)
    validations:
      required: true
      
  - type: textarea
    id: description
    attributes:
      label: Bug Description
      description: Describe what is incorrect, missing, or misleading
      placeholder: |
        The section on table length states that...
        However, the actual behavior is...
        This affects understanding because...
    validations:
      required: true
      
  - type: textarea
    id: reproduction
    attributes:
      label: Code Example (if applicable)
      description: Provide a code snippet that demonstrates the issue
      render: lua
      placeholder: |
        -- Current example in the chapter:
        local t = {1, 2, 3}
        print(#t)  -- What does this show?
        
  - type: textarea
    id: expected
    attributes:
      label: Expected Content
      description: What should the documentation say instead?
      placeholder: |
        The documentation should clarify that...
        A better example would be...
        
  - type: input
    id: source
    attributes:
      label: Reference Source
      description: Link to Lua manual, source code, or other reference (if available)
      placeholder: "https://www.lua.org/manual/5.4/manual.html#..."
      
  - type: checkboxes
    id: terms
    attributes:
      label: Code of Conduct
      description: By submitting this issue, you agree to follow our Code of Conduct
      options:
        - label: I agree to follow this project's Code of Conduct
          required: true
