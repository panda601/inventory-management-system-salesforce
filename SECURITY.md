# Security Policy

## Supported Versions

We actively support and fix security vulnerabilities on the following versions of the project:

| Version | Supported          |
| ------- | ------------------ |
| 1.0.x   | :white_check_mark: |
| < 1.0   | :x:                |

## Reporting a Vulnerability

If you discover a security vulnerability in this project, please do **not** open a public issue. Instead, report it confidentially to us:

1. Send an email to `723145roy@gmail.com` with the subject "SECURITY VULNERABILITY".
2. Describe the vulnerability in detail, including steps to reproduce it and any potential impact.
3. Provide your contact details so we can coordinate a fix and credits.

We will acknowledge your report within 48 hours and work with you to release a patch as quickly as possible.

## Secure Coding Practices in this Repo

When writing Apex code:
- Always enforce access controls by querying custom objects with `WITH USER_MODE` or `WITH SYSTEM_MODE` as appropriate.
- Avoid dynamic SOQL queries with user input to prevent SOQL injection. If dynamic queries are required, always bind variables or sanitize input using `String.escapeSingleQuotes()`.
- Validate FLS (Field Level Security) and CRUD permissions on all insert/update/delete operations.
- Avoid checking in private keys, username/password pairs, or consumer secrets. Use Salesforce Named Credentials or protected custom settings.
