# TopCards

[![Terraform CI/CD](https://github.com/erayguner/topcards/workflows/Terraform%20CI%2FCD/badge.svg)](https://github.com/erayguner/topcards/actions/workflows/terraform.yml)
[![Terraform Security Scanning](https://github.com/erayguner/topcards/workflows/Terraform%20Security%20Scanning/badge.svg)](https://github.com/erayguner/topcards/actions/workflows/terraform-security.yml)
[![Security Policy Enforcement](https://github.com/erayguner/topcards/workflows/Security%20Policy%20Enforcement/badge.svg)](https://github.com/erayguner/topcards/actions/workflows/security-policy.yml)
[![Security Scanning](https://github.com/erayguner/topcards/workflows/Security%20Scanning/badge.svg)](https://github.com/erayguner/topcards/actions/workflows/security-scan.yml)
[![Secret Scanning](https://github.com/erayguner/topcards/workflows/Secret%20Scanning/badge.svg)](https://github.com/erayguner/topcards/actions/workflows/secret-scanning.yml)

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

This repository includes comprehensive GitHub Actions workflows for:

### 🔒 Security Scanning
- **Secret Detection**: Multi-tool scanning with TruffleHog, Gitleaks, Semgrep, and detect-secrets
- **Dependency Scanning**: OWASP dependency vulnerability checks
- **Code Analysis**: CodeQL security analysis
- **Container Security**: Trivy vulnerability scanning
- **License Compliance**: Automated license validation
- **Security Scorecard**: OSSF security posture assessment

### 🏗️ Infrastructure
- **Terraform CI/CD**: Validation, planning, security scanning, and automated deployment
- **Format Checking**: Automated Terraform formatting validation
- **Security Scanning**: Checkov and TFSec integration
- **Plan Comments**: Automated PR comments with Terraform plans

### 📊 Monitoring & Reporting
- **SARIF Integration**: Security findings uploaded to GitHub Advanced Security
- **Automated Summaries**: Comprehensive security and deployment reports
- **Scheduled Scans**: Daily security assessments
- **Performance Tracking**: Workflow execution metrics

## Workflows

- `.github/workflows/terraform.yml` - Terraform CI/CD pipeline
- `.github/workflows/secret-scanning.yml` - Multi-tool secret detection
- `.github/workflows/security-policy.yml` - Security policy enforcement

## Getting Started

1. Configure your Terraform backend in `terraform/` directory
2. Set up required GitHub secrets for deployment
3. Push to trigger automated security scanning and validation

## Security

This project follows security best practices:
- All secrets are scanned before commit
- Dependencies are continuously monitored
- Infrastructure changes are validated and planned
- Security findings are automatically reported

For security issues, please see our [Security Policy](SECURITY.md).

## Contributing

We welcome contributions to TopCards! Please see our [Contributing Guidelines](CONTRIBUTING.md) for detailed information on:

- Development workflow and branch naming conventions
- Code style and quality standards
- Security guidelines and best practices
- Testing requirements and procedures
- Pull request process and review guidelines

For questions or support, please create an issue or start a discussion.