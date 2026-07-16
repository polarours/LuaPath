name: Version Update
description: Report version-specific behavior differences or request version guidance
labels: ["version", "needs-triage"]
body:
  - type: markdown
    attributes:
      value: |
        Use this template to report Lua version-specific differences or request clarification.
        
  - type: input
    id: chapter
    attributes:
      label: Affected Chapter(s)
      description: Which chapter(s) need version updates?
      placeholder: "e.g., 01-basics.md, 07-error-handling.md"
    validations:
      required: true
      
  - type: dropdown
    id: versions
    attributes:
      label: Lua Versions Involved
      description: Which versions have different behavior?
      options:
        - "5.1 vs 5.3"
        - "5.1 vs 5.4"
        - "5.3 vs 5.4"
        - "PUC Lua vs LuaJIT"
        - "All versions"
        - "Other (describe below)"
    validations:
      required: true
      
  - type: textarea
    id: difference
    attributes:
      label: Behavior Difference
      description: Describe how the versions differ
      placeholder: |
        In Lua 5.1, this works as...
        In Lua 5.3+, this changed to...
        LuaJIT handles this differently by...
    validations:
      required: true
      
  - type: textarea
    id: example
    attributes:
      label: Code Example
      description: Show the version-specific behavior with code
      render: lua
      placeholder: |
        -- Lua 5.1
        setfenv(1, {})
        
        -- Lua 5.2+
        _ENV = {}
        
  - type: textarea
    id: recommendation
    attributes:
      label: Suggested Documentation Update
      description: How should this be documented in the chapter?
      placeholder: |
        Add a version note that explains...
        Include a warning about...
        Provide migration guidance for...
        
  - type: input
    id: source
    attributes:
      label: Reference
      description: Link to Lua changelog, manual, or source code
      placeholder: "https://www.lua.org/manual/5.4/readme.html#changes"
      
  - type: checkboxes
    id: terms
    attributes:
      label: Code of Conduct
      description: By submitting this issue, you agree to follow our Code of Conduct
      options:
        - label: I agree to follow this project's Code of Conduct
          required: true
