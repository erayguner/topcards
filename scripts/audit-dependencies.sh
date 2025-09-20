#!/bin/bash
# Dependency vulnerability audit script for TopCards
# Comprehensive dependency scanning for multiple package managers

set -euo pipefail

# Colors for output
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Initialize exit code
EXIT_CODE=0

# Function to check npm dependencies
check_npm_dependencies() {
    if [[ -f "package.json" ]]; then
        echo -e "${BLUE}📦 Checking npm dependencies...${NC}"

        # Install dependencies if node_modules doesn't exist
        if [[ ! -d "node_modules" ]]; then
            echo "Installing npm dependencies..."
            npm install --no-audit --no-fund > /dev/null 2>&1 || true
        fi

        # Run npm audit
        if npm audit --audit-level=moderate; then
            echo -e "${GREEN}✅ npm audit passed${NC}"
        else
            echo -e "${RED}❌ npm audit found vulnerabilities${NC}"
            echo "Run 'npm audit fix' to fix automatically fixable vulnerabilities"
            EXIT_CODE=1
        fi

        # Check for outdated packages
        echo -e "${BLUE}📋 Checking for outdated npm packages...${NC}"
        if npm outdated || true; then
            echo -e "${YELLOW}⚠️  Some packages are outdated. Consider updating.${NC}"
        fi
    fi
}

# Function to check Python dependencies
check_python_dependencies() {
    # Check requirements.txt
    if [[ -f "requirements.txt" ]]; then
        echo -e "${BLUE}🐍 Checking Python dependencies in requirements.txt...${NC}"

        # Use safety to check for vulnerabilities
        if command -v safety >/dev/null 2>&1; then
            if safety check -r requirements.txt; then
                echo -e "${GREEN}✅ safety check passed for requirements.txt${NC}"
            else
                echo -e "${RED}❌ safety check found vulnerabilities in requirements.txt${NC}"
                EXIT_CODE=1
            fi
        else
            echo -e "${YELLOW}⚠️  safety not installed, skipping Python vulnerability check${NC}"
        fi
    fi

    # Check Pipfile
    if [[ -f "Pipfile" ]]; then
        echo -e "${BLUE}🐍 Checking Python dependencies in Pipfile...${NC}"

        if command -v pipenv >/dev/null 2>&1; then
            if pipenv check; then
                echo -e "${GREEN}✅ pipenv check passed${NC}"
            else
                echo -e "${RED}❌ pipenv check found vulnerabilities${NC}"
                EXIT_CODE=1
            fi
        else
            echo -e "${YELLOW}⚠️  pipenv not installed, skipping Pipfile check${NC}"
        fi
    fi

    # Check pyproject.toml
    if [[ -f "pyproject.toml" ]]; then
        echo -e "${BLUE}🐍 Checking Python dependencies in pyproject.toml...${NC}"

        # Try to extract dependencies and check with safety
        if command -v safety >/dev/null 2>&1; then
            # Extract dependencies from pyproject.toml (basic extraction)
            if grep -A 100 '\[tool\.poetry\.dependencies\]' pyproject.toml > /tmp/poetry_deps.txt 2>/dev/null; then
                echo -e "${BLUE}Extracted Poetry dependencies for safety check${NC}"
                # Note: This is a simplified check, proper poetry integration would be better
                safety check || EXIT_CODE=1
            fi
        fi
    fi
}

# Function to check Terraform dependencies
check_terraform_dependencies() {
    if find . -name "*.tf" -type f | head -1 | grep -q "."; then
        echo -e "${BLUE}🏗️  Checking Terraform dependencies...${NC}"

        # Check for terraform version constraints
        if grep -r "required_version" . --include="*.tf" >/dev/null 2>&1; then
            echo -e "${GREEN}✅ Terraform version constraints found${NC}"
        else
            echo -e "${YELLOW}⚠️  No Terraform version constraints found${NC}"
            echo "Consider adding terraform.required_version in your configuration"
        fi

        # Check for provider version constraints
        if grep -r "required_providers" . --include="*.tf" >/dev/null 2>&1; then
            echo -e "${GREEN}✅ Terraform provider version constraints found${NC}"
        else
            echo -e "${YELLOW}⚠️  No Terraform provider version constraints found${NC}"
            echo "Consider pinning provider versions in terraform.required_providers"
        fi

        # Check if terraform init is needed
        if [[ ! -d ".terraform" ]]; then
            echo -e "${YELLOW}⚠️  Terraform not initialized. Run 'terraform init' to check provider dependencies${NC}"
        fi
    fi
}

# Function to check Docker dependencies
check_docker_dependencies() {
    if [[ -f "Dockerfile" ]] || find . -name "Dockerfile*" -type f | head -1 | grep -q "."; then
        echo -e "${BLUE}🐳 Checking Docker dependencies...${NC}"

        # Check for latest tags (security anti-pattern)
        if grep -r ":latest" . --include="Dockerfile*" >/dev/null 2>&1; then
            echo -e "${RED}❌ Found usage of :latest tag in Docker files${NC}"
            echo "Consider pinning specific versions instead of using :latest"
            EXIT_CODE=1
        else
            echo -e "${GREEN}✅ No :latest tags found in Docker files${NC}"
        fi

        # Check for FROM scratch or specific base images
        if grep -r "FROM scratch" . --include="Dockerfile*" >/dev/null 2>&1; then
            echo -e "${GREEN}✅ Found usage of minimal base images${NC}"
        fi
    fi
}

# Function to check GitHub Actions dependencies
check_github_actions_dependencies() {
    if [[ -d ".github/workflows" ]]; then
        echo -e "${BLUE}⚙️  Checking GitHub Actions dependencies...${NC}"

        # Check for pinned action versions
        local unpinned_actions=0

        while IFS= read -r -d '' file; do
            if grep -E "uses:.*@(main|master|v[0-9]+)$" "$file" >/dev/null 2>&1; then
                echo -e "${YELLOW}⚠️  Found unpinned actions in $file${NC}"
                grep -n -E "uses:.*@(main|master|v[0-9]+)$" "$file" || true
                unpinned_actions=$((unpinned_actions + 1))
            fi
        done < <(find .github/workflows -name "*.yml" -o -name "*.yaml" -print0)

        if [[ $unpinned_actions -eq 0 ]]; then
            echo -e "${GREEN}✅ All GitHub Actions appear to be pinned to specific versions${NC}"
        else
            echo -e "${YELLOW}⚠️  Consider pinning GitHub Actions to specific commit SHAs for security${NC}"
        fi
    fi
}

# Function to generate dependency report
generate_dependency_report() {
    local report_file="dependency-audit-report.txt"

    echo "# Dependency Audit Report" > "$report_file"
    echo "Generated on: $(date)" >> "$report_file"
    echo "" >> "$report_file"

    # Add npm info if available
    if [[ -f "package.json" ]]; then
        echo "## NPM Dependencies" >> "$report_file"
        npm list --depth=0 >> "$report_file" 2>/dev/null || echo "npm list failed" >> "$report_file"
        echo "" >> "$report_file"
    fi

    # Add Python info if available
    if [[ -f "requirements.txt" ]]; then
        echo "## Python Dependencies (requirements.txt)" >> "$report_file"
        cat requirements.txt >> "$report_file"
        echo "" >> "$report_file"
    fi

    # Add Terraform info if available
    if find . -name "*.tf" -type f | head -1 | grep -q "."; then
        echo "## Terraform Configuration" >> "$report_file"
        echo "### Provider Requirements" >> "$report_file"
        grep -r "required_providers" . --include="*.tf" >> "$report_file" 2>/dev/null || echo "No provider requirements found" >> "$report_file"
        echo "" >> "$report_file"
    fi

    echo -e "${BLUE}📊 Dependency report generated: $report_file${NC}"
}

# Main execution
echo "🔍 Starting comprehensive dependency audit..."

# Check all dependency types
check_npm_dependencies
check_python_dependencies
check_terraform_dependencies
check_docker_dependencies
check_github_actions_dependencies

# Generate report
generate_dependency_report

# Final status
if [[ $EXIT_CODE -eq 0 ]]; then
    echo -e "\n${GREEN}🎉 Dependency audit completed successfully!${NC}"
    echo "No critical vulnerabilities found in scanned dependencies."
else
    echo -e "\n${RED}🚨 Dependency audit found issues!${NC}"
    echo "Please review the vulnerabilities above and update affected dependencies."
    echo ""
    echo "Common remediation steps:"
    echo "1. Update to latest secure versions"
    echo "2. Apply security patches"
    echo "3. Replace vulnerable dependencies"
    echo "4. Use dependency pinning"
fi

exit $EXIT_CODE