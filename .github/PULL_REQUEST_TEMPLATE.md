name: 📝 Pull Request
description: Submit changes to the project
labels: ["needs-review"]
body:
  - type: markdown
    attributes:
      value: |
        Thanks for your contribution! Please fill out this form to help us review your changes.
        
        **Before submitting:**
        - Read the [Contributing Guide](CONTRIBUTING.md)
        - Ensure your changes follow the project's [Philosophy](README.md#philosophy)
        - Run `make validate` to check code snippets
        
  - type: input
    id: issue
    attributes:
      label: Related Issue
      description: Link to the issue this PR addresses (if applicable)
      placeholder: "e.g., #123"
      
  - type: dropdown
    id: type
    attributes:
      label: Change Type
      description: What type of change is this?
      options:
        - Bug fix (correction to existing content)
        - New content (examples, explanations, sections)
        - New chapter or major addition
        - Translation update
        - Infrastructure (scripts, CI, tooling)
        - Documentation (meta-docs, not chapter content)
        - Other (describe below)
    validations:
      required: true
      
  - type: textarea
    id: description
    attributes:
      label: Description of Changes
      description: What did you change and why?
      placeholder: |
        This PR:
        - Fixes incorrect statement in 04-tables.md about...
        - Adds example showing...
        - Clarifies the difference between...
        
        Rationale:
        - The previous explanation was misleading because...
        - This example helps learners understand...
    validations:
      required: true
      
  - type: dropdown
    id: versions
    attributes:
      label: Lua Version Impact
      description: Which Lua versions does this change affect?
      options:
        - All versions (no version-specific change)
        - Lua 5.1 only
        - Lua 5.3 only
        - Lua 5.4 only
        - LuaJIT only
        - Multiple versions (explain in description)
    validations:
      required: true
      
  - type: checkboxes
    id: checklist
    attributes:
      label: PR Checklist
      description: Please verify these items before submitting
      options:
        - label: I have read the Contributing Guide
          required: true
        - label: Code examples are tested and runnable
        - label: EN/ZH parity is maintained (if updating both)
        - label: Version notes are included where needed
        - label: No breaking changes to existing content (or explained if intentional)
        
  - type: textarea
    id: testing
    attributes:
      label: Testing Done
      description: How did you test these changes?
      placeholder: |
        - [x] Ran `make validate` on affected chapters
        - [x] Tested code examples with Lua 5.4
        - [ ] Tested with LuaJIT (if applicable)
        
  - type: textarea
    id: screenshots
    attributes:
      label: Screenshots (if applicable)
      description: For visual changes or new diagrams
      
  - type: input
    id: changelog
    attributes:
      label: Changelog Entry
      description: Suggest a one-line changelog entry
      placeholder: "- Fixed: Table length behavior explanation in 04-tables.md"
      
  - type: checkboxes
    id: terms
    attributes:
      label: Code of Conduct
      description: By submitting this PR, you agree to follow our Code of Conduct
      options:
        - label: I agree to follow this project's Code of Conduct
          required: true
          
  - type: markdown
    attributes:
      value: |
        **Next steps:**
        1. Maintainers will review within 3-5 days
        2. Address any feedback in the same branch
        3. Once approved, your PR will be merged
        4. You'll be credited in CONTRIBUTORS.md and release notes
