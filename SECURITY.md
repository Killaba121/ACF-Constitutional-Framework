# Security Policy

## Reporting a Vulnerability

The ACF team takes security seriously. If you discover a security vulnerability in the framework, its documentation, or any associated tooling, we appreciate your responsible disclosure.

### How to Report

**Email:** [oxygenatedprogress@gmail.com](mailto:oxygenatedprogress@gmail.com)

**Subject line:** `[SECURITY] Brief description of the vulnerability`

Please include the following in your report:

- **Description** of the vulnerability and its potential impact
- **Steps to reproduce** or a proof-of-concept (if applicable)
- **Affected component** — which document, protocol, or tool is affected
- **Severity assessment** — your estimation of the risk level (Critical / High / Medium / Low)
- **Suggested fix** (if you have one)

### What to Expect

| Timeline | Action |
|---|---|
| **48 hours** | Acknowledgment of your report |
| **7 days** | Initial assessment and severity classification |
| **30 days** | Resolution or mitigation plan communicated |
| **90 days** | Public disclosure (coordinated with reporter) |

We will keep you informed throughout the process and credit you in the advisory (unless you prefer to remain anonymous).

## Responsible Disclosure Policy

We follow a **coordinated disclosure** model:

1. **Report privately** using the contact information above.
2. **Allow reasonable time** for us to investigate and address the issue before any public disclosure.
3. **Coordinate disclosure** — we will work with you on the timing and content of any public advisory.
4. **Credit** — reporters will be acknowledged unless they request anonymity.

We ask that you:

- **Do not** disclose the vulnerability publicly until we have had a reasonable opportunity to address it.
- **Do not** exploit the vulnerability beyond what is necessary to demonstrate it.
- **Do not** access, modify, or delete data belonging to others.

## What NOT to Include in Public Issues

**Do not open public GitHub issues for security vulnerabilities.** Additionally, the following types of information should never be included in public issues, pull requests, or discussions:

- Implementation-specific security configurations or credentials
- Detailed exploitation techniques for known vulnerabilities
- Internal system architecture details that could aid an attacker
- Information about unremediated vulnerabilities in active deployments
- Security audit results or penetration testing reports

If you are unsure whether something constitutes a security issue, err on the side of caution and report it privately.

## Scope

This security policy covers:

- The ACF framework specification and all protocol documents
- Reference implementations and tooling provided in this repository
- The project's infrastructure (website, CI/CD, distribution channels)

### Out of Scope

- Third-party implementations of ACF (report to the respective maintainers)
- Theoretical critiques of the framework's governance model (open a regular issue or discussion)
- General AI safety concerns not specific to ACF

## Security Best Practices for Implementers

If you are implementing ACF in a production system, we recommend:

1. **Keep your implementation up to date** with the latest protocol specifications.
2. **Verify protocol integrity** using the checksums and verification methods described in the documentation.
3. **Conduct independent security reviews** of your implementation before deployment.
4. **Report any implementation gaps** where the specification is ambiguous or insufficient for secure implementation.

## Acknowledgments

We gratefully recognize the security researchers and community members who help keep ACF secure through responsible disclosure. Contributors will be listed here (with permission) as reports are resolved.

---

Thank you for helping keep the Autonomous Constitutional Framework secure.
