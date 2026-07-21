# Security Policy

## Supported Versions

| Version | Supported          | Notes                              |
| ------- | ------------------ | ---------------------------------- |
| Latest  | :white_check_mark: | Always use the most recent release |
| < Latest| :x:                | Not actively maintained            |

## Reporting a Vulnerability

We take security issues seriously. If you discover a security vulnerability, please follow these steps:

### What to Report

1. **Vulnerability in code examples**: If example code could lead to security issues when used in production
2. **Misleading security guidance**: If documentation provides incorrect security advice
3. **Sandbox escape scenarios**: If described sandboxing techniques have known bypasses
4. **C API safety issues**: If C API guidance could lead to memory safety problems

### How to Report

**For non-urgent issues:**
- Open a GitHub issue with the `security` label
- Describe the issue and potential impact

**For urgent/security-sensitive issues:**
- **Do NOT create a public issue**
- Contact maintainers directly at: **[INSERT SECURITY EMAIL]**
- Include:
  - Description of the vulnerability
  - Steps to reproduce
  - Potential impact assessment
  - Suggested fix (if known)

### What to Expect

- **Initial response**: Within 48 hours
- **Status update**: Within 5 business days
- **Resolution timeline**: Depends on severity and complexity

### Disclosure Policy

- We will acknowledge your report and keep you informed of progress
- We prefer coordinated disclosure: fix first, then public disclosure
- You will be credited in the security advisory (unless you prefer anonymity)
- We will not publish details until a fix is available

## Security Considerations in This Project

### Code Examples

Code examples in `LuaPath` are educational. When using them in production:

1. **Validate all inputs**: Examples may not include production-grade validation
2. **Review sandbox configurations**: Sandboxing examples are starting points, not complete solutions
3. **Audit native bindings**: C API examples require careful review for your use case
4. **Consider resource limits**: Examples may not include DoS protection

### Lua-Specific Security Topics

This project covers security-relevant topics in:

- **Chapter 07 (Error Handling)**: Error boundaries and information leakage
- **Chapter 10 (Internals)**: VM behavior that could affect isolation
- **Chapter 11 (C API)**: Memory safety and API boundaries
- **Chapter 14 (Production)**: Sandboxing and deployment security

### Known Limitations

- Examples target educational use; production deployments require additional hardening
- LuaJIT security considerations may differ from PUC Lua
- Sandboxing techniques vary by Lua version and host environment

## Security Best Practices for Lua Development

Based on content in this repository:

1. **Sandbox untrusted scripts**: Remove dangerous globals, set resource limits
2. **Validate script inputs**: Never trust external data in script logic
3. **Audit native bindings**: C API calls can bypass Lua safety mechanisms
4. **Monitor GC behavior**: Memory exhaustion can be a DoS vector
5. **Version awareness**: Security features vary across Lua versions

## External Resources

- [Lua Security Guidelines](https://www.lua.org/manual/)
- [LuaJIT Security Notes](https://luajit.org/security.html)
- [CVE Database](https://cve.mitre.org/) - Search for "Lua"

## Credits

Security improvements to this project benefit the entire Lua community. We appreciate responsible disclosure and collaborative problem-solving.

---

**Last updated**: 2026-03-06
