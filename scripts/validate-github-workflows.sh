#!/bin/bash
# GitHub Actions workflow validation script for TopCards
# Validates security and best practices in GitHub Actions workflows

set -euo pipefail

# Colors for output
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Initialize exit code
EXIT_CODE=0

# Security patterns to check
declare -A SECURITY_CHECKS=(
    ["shell_injection"]='.*\$\{\{.*\}\}.*'
    ["write_permissions"]='permissions:.*contents:\s*write'
    ["pull_request_target"]='on:.*pull_request_target'
    ["unpinned_actions"]='uses:.*@(main|master|latest|v[0-9]+)$'
    ["checkout_ref"]='uses:.*checkout.*ref:\s*\$\{\{.*\}\}'
    ["script_injection"]='run:.*\$\{\{.*\}\}'
)

# Best practice patterns
declare -A BEST_PRACTICES=(
    ["timeout_specified"]='timeout-minutes:\s*[0-9]+'
    ["fail_fast_disabled"]='fail-fast:\s*false'
    ["continue_on_error"]='continue-on-error:\s*true'
    ["matrix_used"]='strategy:.*matrix:'
    ["caching_used"]='uses:.*cache@'
    ["artifacts_retention"]='retention-days:\s*[0-9]+'
)

# Required security permissions
declare -A SECURITY_PERMISSIONS=(
    ["read_only_default"]='permissions:.*contents:\s*read'
    ["security_events"]='permissions:.*security-events:\s*write'
    ["id_token"]='permissions:.*id-token:\s*write'
)

# Function to validate a single workflow file
validate_workflow() {
    local file="$1"
    local issues_found=false

    echo -e "${BLUE}🔍 Validating workflow: $file${NC}"

    # Check for YAML syntax
    if ! yamllint "$file" >/dev/null 2>&1; then
        echo -e "${RED}❌ YAML syntax error in $file${NC}"
        yamllint "$file" || true
        issues_found=true
    fi

    # Security checks
    echo "  🔒 Running security checks..."

    # Check for shell injection vulnerabilities
    if grep -Pq "${SECURITY_CHECKS[shell_injection]}" "$file"; then
        echo -e "${RED}❌ Potential shell injection vulnerability detected${NC}"
        echo "  Found in lines:"
        grep -Pn "${SECURITY_CHECKS[shell_injection]}" "$file" | head -5
        issues_found=true
    fi

    # Check for dangerous permissions
    if grep -Pq "${SECURITY_CHECKS[write_permissions]}" "$file"; then
        echo -e "${YELLOW}⚠️  Write permissions detected${NC}"
        echo "  Consider if write permissions are necessary:"
        grep -Pn "${SECURITY_CHECKS[write_permissions]}" "$file"
    fi

    # Check for pull_request_target usage
    if grep -Pq "${SECURITY_CHECKS[pull_request_target]}" "$file"; then
        echo -e "${RED}❌ pull_request_target trigger detected${NC}"
        echo "  This can be dangerous with untrusted code"
        issues_found=true
    fi

    # Check for unpinned actions
    if grep -Pq "${SECURITY_CHECKS[unpinned_actions]}" "$file"; then
        echo -e "${YELLOW}⚠️  Unpinned actions detected${NC}"
        echo "  Consider pinning to specific commit SHAs:"
        grep -Pn "${SECURITY_CHECKS[unpinned_actions]}" "$file" | head -5
    fi

    # Check for checkout with user-controlled ref
    if grep -Pq "${SECURITY_CHECKS[checkout_ref]}" "$file"; then
        echo -e "${RED}❌ Checkout with user-controlled ref detected${NC}"
        echo "  This can be dangerous:"
        grep -Pn "${SECURITY_CHECKS[checkout_ref]}" "$file"
        issues_found=true
    fi

    # Check for script injection in run commands
    if grep -Pq "${SECURITY_CHECKS[script_injection]}" "$file"; then
        echo -e "${RED}❌ Potential script injection in run command${NC}"
        echo "  Found in lines:"
        grep -Pn "${SECURITY_CHECKS[script_injection]}" "$file" | head -5
        issues_found=true
    fi

    # Best practices checks
    echo "  ✅ Running best practices checks..."

    # Check for timeouts
    if ! grep -Pq "${BEST_PRACTICES[timeout_specified]}" "$file"; then
        echo -e "${YELLOW}⚠️  No timeout specified${NC}"
        echo "  Consider adding timeout-minutes to prevent hanging jobs"
    fi

    # Check for proper permissions
    if ! grep -Pq "${SECURITY_PERMISSIONS[read_only_default]}" "$file"; then
        echo -e "${YELLOW}⚠️  No explicit read-only permissions${NC}"
        echo "  Consider adding 'permissions: contents: read' for security"
    fi

    # Check for artifact retention
    if grep -q "upload-artifact" "$file" && ! grep -Pq "${BEST_PRACTICES[artifacts_retention]}" "$file"; then
        echo -e "${YELLOW}⚠️  No artifact retention policy${NC}"
        echo "  Consider adding retention-days to artifact uploads"
    fi

    # Check for caching
    if grep -q "setup-node\|setup-python\|setup-java" "$file" && ! grep -Pq "${BEST_PRACTICES[caching_used]}" "$file"; then
        echo -e "${BLUE}💡 Consider using caching for better performance${NC}"
    fi

    # Environment-specific checks
    echo "  🌍 Running environment-specific checks..."

    # Check for secrets usage
    if grep -q "secrets\." "$file"; then
        echo -e "${BLUE}🔐 Secrets usage detected${NC}"
        # Verify secrets are not logged
        if grep -A 5 -B 5 "secrets\." "$file" | grep -q "echo.*secrets\."; then
            echo -e "${RED}❌ Secret might be logged in output${NC}"
            issues_found=true
        fi
    fi

    # Check for environment variables
    if grep -q "env:" "$file"; then
        echo -e "${BLUE}🌐 Environment variables detected${NC}"
        # Check for hardcoded sensitive values
        if grep -A 10 "env:" "$file" | grep -Pq ':\s*["\'][^"\']*[Pp][Aa][Ss][Ss][Ww][Oo][Rr][Dd][^"\']*["\']'; then
            echo -e "${RED}❌ Hardcoded password-like value in environment${NC}"
            issues_found=true
        fi
    fi

    # Check for matrix strategy
    if grep -q "strategy:" "$file" && grep -Pq "${BEST_PRACTICES[matrix_used]}" "$file"; then
        echo -e "${GREEN}✅ Matrix strategy used for comprehensive testing${NC}"
    fi

    if $issues_found; then
        echo -e "${RED}❌ Security issues found in $file${NC}"
        EXIT_CODE=1
    else
        echo -e "${GREEN}✅ No security issues found in $file${NC}"
    fi

    echo ""
}

# Function to check workflow dependencies
check_workflow_dependencies() {
    echo -e "${BLUE}📦 Checking workflow action dependencies...${NC}"

    # Extract all action dependencies
    local actions_file="/tmp/workflow_actions.txt"
    find .github/workflows -name "*.yml" -o -name "*.yaml" | xargs grep -h "uses:" | sort | uniq > "$actions_file"

    echo "Used GitHub Actions:"
    cat "$actions_file"

    # Check for deprecated actions
    local deprecated_actions=(
        "actions/setup-node@v1"
        "actions/setup-python@v1"
        "actions/checkout@v1"
        "actions/cache@v1"
    )

    for action in "${deprecated_actions[@]}"; do
        if grep -q "$action" "$actions_file"; then
            echo -e "${YELLOW}⚠️  Deprecated action found: $action${NC}"
        fi
    done

    rm -f "$actions_file"
}

# Function to generate workflow security report
generate_security_report() {
    local report_file="workflow-security-report.md"

    echo "# GitHub Workflows Security Report" > "$report_file"
    echo "Generated on: $(date)" >> "$report_file"
    echo "" >> "$report_file"

    echo "## Workflow Files Analyzed" >> "$report_file"
    find .github/workflows -name "*.yml" -o -name "*.yaml" | while read -r file; do
        echo "- $file" >> "$report_file"
    done
    echo "" >> "$report_file"

    echo "## Security Recommendations" >> "$report_file"
    echo "1. Pin actions to specific commit SHAs" >> "$report_file"
    echo "2. Use least privilege permissions" >> "$report_file"
    echo "3. Validate user inputs in workflows" >> "$report_file"
    echo "4. Set appropriate timeouts" >> "$report_file"
    echo "5. Use continue-on-error judiciously" >> "$report_file"
    echo "" >> "$report_file"

    echo "## Action Dependencies" >> "$report_file"
    find .github/workflows -name "*.yml" -o -name "*.yaml" | xargs grep -h "uses:" | sort | uniq >> "$report_file"

    echo -e "${BLUE}📊 Security report generated: $report_file${NC}"
}

# Main execution
echo "🔍 Starting GitHub Actions workflow validation..."

# Check if workflows directory exists
if [[ ! -d ".github/workflows" ]]; then
    echo -e "${YELLOW}⚠️  No .github/workflows directory found${NC}"
    exit 0
fi

# Get list of workflow files
WORKFLOW_FILES=()
while IFS= read -r -d '' file; do
    WORKFLOW_FILES+=("$file")
done < <(find .github/workflows -name "*.yml" -o -name "*.yaml" -print0)

if [[ ${#WORKFLOW_FILES[@]} -eq 0 ]]; then
    echo -e "${YELLOW}⚠️  No workflow files found${NC}"
    exit 0
fi

echo "Found ${#WORKFLOW_FILES[*]} workflow file(s) to validate"

# Validate each workflow file
for file in "${WORKFLOW_FILES[@]}"; do
    validate_workflow "$file"
done

# Check workflow dependencies
check_workflow_dependencies

# Generate security report
generate_security_report

# Final status
if [[ $EXIT_CODE -eq 0 ]]; then
    echo -e "${GREEN}🎉 All workflow validations passed!${NC}"
    echo "Your GitHub Actions workflows follow security best practices."
else
    echo -e "${RED}🚨 Workflow validation found security issues!${NC}"
    echo "Please review and fix the issues above."
    echo ""
    echo "Security guidelines:"
    echo "1. Never use untrusted input in shell commands"
    echo "2. Pin actions to specific commit SHAs"
    echo "3. Use minimal permissions"
    echo "4. Validate pull_request_target usage"
    echo "5. Set appropriate timeouts"
fi

exit $EXIT_CODE