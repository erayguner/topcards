# TopCards

[![CodeQL Security Analysis](https://github.com/erayguner/topcards/workflows/CodeQL%20Security%20Analysis/badge.svg)](https://github.com/erayguner/topcards/actions/workflows/codeql.yml)
[![MegaLinter Security & Quality Scan](https://github.com/erayguner/topcards/workflows/MegaLinter%20Security%20%26%20Quality%20Scan/badge.svg)](https://github.com/erayguner/topcards/actions/workflows/security-scan.yml)

![GitHub issues](https://img.shields.io/github/issues/erayguner/topcards)
![GitHub pull requests](https://img.shields.io/github/issues-pr/erayguner/topcards)
![GitHub](https://img.shields.io/github/license/erayguner/topcards)
![GitHub last commit](https://img.shields.io/github/last-commit/erayguner/topcards)
![GitHub repo size](https://img.shields.io/github/repo-size/erayguner/topcards)

![Terraform](https://img.shields.io/badge/Terraform-1.5+-blue?logo=terraform)
![Google Cloud](https://img.shields.io/badge/Google%20Cloud-Platform-blue?logo=google-cloud)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-16-blue?logo=postgresql)
![Security](https://img.shields.io/badge/Security-Hardened-green?logo=shield)

A secure, well-tested application with comprehensive CI/CD pipelines.

## Security & CI/CD

This repository uses a streamlined, comprehensive security approach with two powerful workflows:

### 🔒 CodeQL Security Analysis

- **Static Application Security Testing (SAST)**: Advanced security vulnerability detection
- **Security-Extended Queries**: Comprehensive security pattern analysis
- **GitHub Security Integration**: Automatic security alerts and reporting
- **Scheduled Scanning**: Weekly automated security assessments

### 🛡️ MegaLinter Security & Quality

- **Comprehensive Scanning**: 70+ linters in security flavor
- **Secret Detection**: Gitleaks integration for credential scanning
- **Code Quality**: YAML, JSON, Markdown, and Terraform validation
- **Container Security**: Dockerfile analysis with Hadolint
- **Infrastructure Security**: Terraform security scanning with TFSec
- **Automated Reporting**: SARIF format with GitHub Security integration

## Workflows

- `.github/workflows/codeql.yml` - CodeQL static application security testing
- `.github/workflows/security-scan.yml` - MegaLinter comprehensive security & quality scanning

## Getting Started

1. Fork or clone this repository
2. Push changes to trigger automated security scanning
3. Review security findings in GitHub Security tab
4. Use the comprehensive security setup as a template for your projects

## Security

This project follows security best practices:

- All secrets are scanned before commit
- Dependencies are continuously monitored
- Infrastructure changes are validated and planned
- Security findings are automatically reported

For security issues, please see our [Security Policy](SECURITY.md).

## Contributing

We welcome contributions to TopCards! Please see our [Contributing Guidelines](CONTRIBUTING.md) for
detailed information on:

- Development workflow and branch naming conventions
- Code style and quality standards
- Security guidelines and best practices
- Testing requirements and procedures
- Pull request process and review guidelines

For questions or support, please create an issue or start a discussion.

<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

No providers.

## Modules

No modules.

## Resources

No resources.

## Inputs

No inputs.

## Outputs

No outputs.
<!-- END_TF_DOCS -->