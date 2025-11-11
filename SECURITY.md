# Security Policy

## Supported Versions

We actively support the following versions of the Blackbaud PowerBI Connector:

| Version | Supported          |
| ------- | ------------------ |
| 2025.x  | ✅ Yes             |
| 2024.x  | ⚠️ Limited Support |
| < 2024  | ❌ No              |

## Reporting a Vulnerability

We take security vulnerabilities seriously. Please help us maintain the security of this project.

### How to Report

**🚨 DO NOT create public GitHub issues for security vulnerabilities.**

Instead, please report security issues privately:

1. **Email**: Send details to [your-email@blackbaud.com]
2. **GitHub Security Advisories**: Use the "Security" tab on this repository
3. **Include**: 
   - Description of the vulnerability
   - Steps to reproduce
   - Potential impact
   - Suggested fix (if available)

### What to Include

- **PowerBI Connector version** affected
- **PowerBI Desktop version** where tested
- **Operating system** and version
- **Detailed reproduction steps**
- **Expected vs actual behavior**

### Response Timeline

- **Initial Response**: Within 2 business days
- **Vulnerability Assessment**: Within 5 business days  
- **Security Fix**: Within 30 days for critical issues

### Security Best Practices for Users

When using the Blackbaud PowerBI Connector:

✅ **Do:**
- Keep PowerBI Desktop updated to the latest version
- Use the latest connector version from official releases
- Store API credentials securely using PowerBI's credential manager
- Enable custom connector security settings as documented

❌ **Don't:**
- Share API keys or credentials in reports or workbooks
- Install connector MEZ files from untrusted sources
- Disable PowerBI security warnings without understanding risks
- Use the connector with compromised Blackbaud accounts

### Scope

This security policy covers:
- **Blackbaud PowerBI Connector** code and MEZ packages
- **Build and release infrastructure** (GitHub Actions workflows)
- **Documentation and examples** in this repository

Out of scope:
- Third-party dependencies (report to respective maintainers)
- PowerBI Desktop itself (report to Microsoft)
- Blackbaud SKY API (report to Blackbaud)

## Contact

For security questions and concerns:
- **Project Maintainer**: [Your contact information]
- **Blackbaud Security**: https://www.blackbaud.com/security
- **GitHub Security**: security@github.com (for repository infrastructure issues)

---

Thank you for helping keep the Blackbaud PowerBI Connector secure! 🔒