name: Translation Issue
description: Report translation errors, terminology inconsistencies, or suggest improvements
labels: ["translation", "needs-triage"]
body:
  - type: markdown
    attributes:
      value: |
        Help us improve the translation quality. Please provide details about the issue.
        
  - type: dropdown
    id: language
    attributes:
      label: Language Track
      description: Which language track is affected?
      options:
        - 简体中文 (zh/)
        - Other (specify below)
    validations:
      required: true
      
  - type: input
    id: chapter
    attributes:
      label: Affected Chapter(s)
      description: Which chapter(s) contain the translation issue?
      placeholder: "e.g., zh/04-tables.md"
    validations:
      required: true
      
  - type: dropdown
    id: issue-type
    attributes:
      label: Issue Type
      description: What kind of translation issue is this?
      options:
        - Incorrect translation
        - Terminology inconsistency
        - Missing content (not synced with EN)
        - Awkward phrasing
        - Technical term should not be translated
        - Other (describe below)
    validations:
      required: true
      
  - type: textarea
    id: current
    attributes:
      label: Current Translation
      description: What does the current translation say?
      placeholder: |
        Current (zh): ...
        
  - type: textarea
    id: suggested
    attributes:
      label: Suggested Translation
      description: How should this be translated?
      placeholder: |
        Suggested (zh): ...
        Reason: This is more accurate because...
        
  - type: textarea
    id: context
    attributes:
      label: Context
      description: Why is this translation problematic?
      placeholder: |
        The current translation implies...
        But the English original means...
        This could mislead learners because...
        
  - type: checkboxes
    id: terms
    attributes:
      label: Code of Conduct
      description: By submitting this issue, you agree to follow our Code of Conduct
      options:
        - label: I agree to follow this project's Code of Conduct
          required: true
