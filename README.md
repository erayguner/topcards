# TopCards

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

For security issues, please see our security policy in the GitHub Security tab.