# Contributing to TopCards

Thank you for your interest in contributing to TopCards! This document provides guidelines and
information for contributors.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Workflow](#development-workflow)
- [Pull Request Process](#pull-request-process)
- [Coding Standards](#coding-standards)
- [Security Guidelines](#security-guidelines)
- [Testing](#testing)
- [Documentation](#documentation)

## Code of Conduct

By participating in this project, you agree to abide by our Code of Conduct. Please treat all
participants with respect and create a welcoming environment for everyone.

## Getting Started

### Prerequisites

- **Terraform** 1.5 or later
- **Google Cloud SDK** with active project
- **Git** for version control
- **GitHub account** for contributions

### Setup Development Environment

1. **Fork the repository**

   ```bash
   # Fork on GitHub, then clone your fork
   git clone https://github.com/YOUR_USERNAME/topcards.git
   cd topcards
   ```

2. **Set up upstream remote**

   ```bash
   git remote add upstream https://github.com/erayguner/topcards.git
   ```

3. **Install development tools**

   ```bash
   # Install Terraform
   # Install Google Cloud SDK
   # Install pre-commit hooks (optional but recommended)
   ```

4. **Configure Terraform**
   ```bash
   cd terraform
   cp terraform.tfvars.example terraform.tfvars
   # Edit with your test project values
   ```

## Development Workflow

### Branch Naming Convention

Use descriptive branch names with prefixes:

- `feature/` - New features or enhancements
- `fix/` - Bug fixes
- `docs/` - Documentation updates
- `refactor/` - Code refactoring
- `security/` - Security improvements
- `chore/` - Maintenance tasks

Examples:

- `feature/add-monitoring-dashboard`
- `fix/database-connection-timeout`
- `docs/update-terraform-readme`

### Making Changes

1. **Create a feature branch**

   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make your changes**
   - Follow the coding standards below
   - Add tests if applicable
   - Update documentation

3. **Test your changes**

   ```bash
   # Terraform validation
   cd terraform
   terraform fmt -check -recursive
   terraform validate

   # Security scanning
   checkov -f .
   tfsec .
   ```

4. **Commit your changes**

   ```bash
   git add .
   git commit -m "feat: add new monitoring dashboard

   - Add Grafana dashboard configuration
   - Include CloudWatch metrics integration
   - Update documentation

   Closes #123"
   ```

### Commit Message Format

Follow [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

**Types:**

- `feat:` - New features
- `fix:` - Bug fixes
- `docs:` - Documentation changes
- `style:` - Code style/formatting
- `refactor:` - Code refactoring
- `test:` - Adding or updating tests
- `chore:` - Maintenance tasks
- `security:` - Security improvements

## Pull Request Process

### Before Submitting

1. **Sync with upstream**

   ```bash
   git fetch upstream
   git rebase upstream/main
   ```

2. **Run quality checks**

   ```bash
   # All checks should pass
   terraform fmt -check -recursive
   terraform validate
   checkov -f .
   tfsec .
   ```

3. **Update documentation**
   - Update README.md if needed
   - Add/update inline comments
   - Update terraform/README.md for infrastructure changes

### Submitting the PR

1. **Push your branch**

   ```bash
   git push origin feature/your-feature-name
   ```

2. **Create Pull Request**
   - Use the PR template
   - Provide clear description
   - Link related issues
   - Add appropriate labels

3. **PR Requirements**
   - ✅ All CI/CD checks pass
   - ✅ Security scans pass
   - ✅ Terraform validation passes
   - ✅ Documentation updated
   - ✅ Tests added/updated (if applicable)
   - ✅ Code review approved

### Review Process

1. **Automated checks** run first
2. **Security review** for security-related changes
3. **Code review** by maintainers
4. **Testing** in development environment
5. **Approval and merge**

## Coding Standards

### Terraform

#### File Organization

```
terraform/
├── main.tf              # Main configuration
├── providers.tf         # Provider configuration
├── variables.tf         # Input variables
├── outputs.tf          # Output values
├── apis.tf             # API enablement
├── networking.tf       # Network resources
├── storage.tf          # Storage resources
├── security.tf         # Security resources
├── compute.tf          # Compute resources
├── database.tf         # Database resources
└── bigquery.tf         # BigQuery resources
```

#### Naming Conventions

- **Resources**: `snake_case` with descriptive names
- **Variables**: `snake_case` with validation rules
- **Outputs**: `snake_case` with clear descriptions

#### Code Style

```hcl
# Good: Clear, descriptive resource names
resource "google_compute_instance" "web_server" {
  name         = "${var.environment}-web-${count.index + 1}"
  machine_type = var.machine_type
  zone         = var.zone

  # Clear grouping and spacing
  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2004-lts"
      size  = 20
      type  = "pd-standard"
    }
  }

  # Inline comments for complex configurations
  metadata_startup_script = file("${path.module}/startup-script.sh")

  tags = ["web-server", var.environment]

  labels = var.labels
}
```

#### Variables

- Always include descriptions
- Add validation rules where appropriate
- Provide sensible defaults
- Use consistent types

```hcl
variable "machine_type" {
  description = "Machine type for compute instances"
  type        = string
  default     = "e2-micro"
  validation {
    condition = contains([
      "e2-micro", "e2-small", "e2-medium"
    ], var.machine_type)
    error_message = "Machine type must be a valid GCP machine type."
  }
}
```

### Documentation

#### Inline Comments

- Explain **why**, not **what**
- Use comments for complex logic
- Document security considerations
- Explain business requirements

#### README Structure

- Clear overview and architecture
- Prerequisites and setup
- Configuration examples
- Troubleshooting guide
- Security considerations

## Security Guidelines

### Infrastructure Security

1. **Least Privilege**
   - Minimal IAM permissions
   - Service account restrictions
   - Network segmentation

2. **Data Protection**
   - Encryption at rest and in transit
   - Secret management
   - Access logging

3. **Network Security**
   - Private subnets
   - Firewall rules
   - VPN/private connectivity

### Code Security

1. **No Hardcoded Secrets**
   - Use variables and secret management
   - Check .gitignore completeness
   - Scan for exposed credentials

2. **Security Scanning**
   - Run Checkov and TFSec
   - Address high/critical findings
   - Document accepted risks

3. **Access Control**
   - Review IAM bindings
   - Validate service account permissions
   - Check resource-level access

## Testing

### Terraform Testing

1. **Validation Testing**

   ```bash
   terraform init
   terraform validate
   terraform plan
   ```

2. **Security Testing**

   ```bash
   checkov -f .
   tfsec .
   terrascan scan -t gcp
   ```

3. **Format Testing**
   ```bash
   terraform fmt -check -recursive
   ```

### Manual Testing

1. **Development Environment**
   - Test in isolated project
   - Verify resource creation
   - Test functionality

2. **Rollback Testing**
   - Test destruction process
   - Verify cleanup completeness
   - Document manual cleanup steps

## Documentation

### Code Documentation

- **Inline comments** for complex logic
- **Variable descriptions** for all inputs
- **Output descriptions** for all outputs
- **Resource comments** for security/business context

### External Documentation

- **README updates** for new features
- **Architecture diagrams** for major changes
- **Runbooks** for operational procedures
- **Security notes** for security-related changes

### Documentation Standards

- Use clear, concise language
- Include examples and code snippets
- Keep documentation current with code
- Follow markdown best practices

## Getting Help

### Resources

- 📖 [Terraform Documentation](https://terraform.io/docs)
- 🏗️ [Google Cloud Documentation](https://cloud.google.com/docs)
- 🛡️ [Security Best Practices](https://cloud.google.com/security/best-practices)

### Communication

- **Issues**: Use GitHub issues for bugs and feature requests
- **Discussions**: Use GitHub discussions for questions
- **Security**: Follow responsible disclosure for security issues

### Support

If you need help:

1. Check existing documentation
2. Search GitHub issues
3. Create a new issue with:
   - Clear description
   - Steps to reproduce
   - Expected vs actual behavior
   - Environment details

## Recognition

Contributors are recognized through:

- GitHub contributor graphs
- Release notes mentions
- Documentation credits

Thank you for contributing to TopCards! 🚀
