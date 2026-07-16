name: Content Request
description: Suggest new content, examples, or topic coverage
labels: ["enhancement", "content", "needs-triage"]
body:
  - type: markdown
    attributes:
      value: |
        Thanks for suggesting new content! Please help us understand what you'd like to see.
        
  - type: input
    id: topic
    attributes:
      label: Topic or Chapter
      description: Which chapter should this be added to? Or is this a new chapter?
      placeholder: "e.g., 04-tables.md, or 'new chapter on debugging'"
    validations:
      required: true
      
  - type: dropdown
    id: type
    attributes:
      label: Content Type
      description: What type of content are you requesting?
      options:
        - Additional code example
        - Real-world case study
        - Performance note
        - Version-specific clarification
        - Common pitfall / anti-pattern
        - Exercise or project idea
        - New chapter entirely
        - Other (describe below)
    validations:
      required: true
      
  - type: textarea
    id: description
    attributes:
      label: What Should Be Added?
      description: Describe the content you'd like to see
      placeholder: |
        I'd like to see an example that shows...
        A case study about how this is used in...
        Explanation of why this pattern matters for...
    validations:
      required: true
      
  - type: textarea
    id: motivation
    attributes:
      label: Why Is This Important?
      description: How would this help learners? What problem does it solve?
      placeholder: |
        This would help because...
        Many learners struggle with...
        In production, this pattern is common because...
        
  - type: textarea
    id: context
    attributes:
      label: Additional Context
      description: Any references, links, or examples that would help?
      render: lua
      
  - type: checkboxes
    id: contribution
    attributes:
      label: Willing to Contribute?
      description: Would you be willing to write this content yourself?
      options:
        - label: I would like to contribute this myself
        - label: I can provide examples or review the content
        - label: I prefer that maintainers write this
        
  - type: checkboxes
    id: terms
    attributes:
      label: Code of Conduct
      description: By submitting this issue, you agree to follow our Code of Conduct
      options:
        - label: I agree to follow this project's Code of Conduct
          required: true
