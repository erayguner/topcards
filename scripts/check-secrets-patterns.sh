#!/bin/bash
# Custom secret pattern detection script for TopCards
# This script provides additional secret detection beyond standard tools

set -euo pipefail

# Colors for output
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Secret patterns to check
declare -a SECRET_PATTERNS=(
    # Google Cloud patterns
    "AIza[0-9A-Za-z\\-_]{35}"  # Google Cloud API Key
    "ya29\\.[0-9A-Za-z\\-_]+"  # Google OAuth2 Access Token
    "\"type\":\s*\"service_account\""  # Service Account JSON

    # AWS patterns
    "AKIA[0-9A-Z]{16}"  # AWS Access Key ID
    "aws_secret_access_key.*[=:]\s*['\"][A-Za-z0-9/+=]{40}['\"]"  # AWS Secret

    # Azure patterns
    "DefaultEndpointsProtocol=https;AccountName.*AccountKey"  # Azure Storage

    # Database patterns
    "postgres://[^:]+:[^@]+@[^/]+/"  # PostgreSQL connection string
    "mysql://[^:]+:[^@]+@[^/]+/"     # MySQL connection string
    "mongodb://[^:]+:[^@]+@[^/]+/"   # MongoDB connection string

    # Generic patterns
    "password['\"]?\s*[=:]\s*['\"][^'\"]{8,}['\"]"  # Password assignments
    "secret['\"]?\s*[=:]\s*['\"][^'\"]{8,}['\"]"    # Secret assignments
    "token['\"]?\s*[=:]\s*['\"][^'\"]{20,}['\"]"    # Token assignments

    # SSH keys
    "-----BEGIN (RSA |OPENSSH |DSA |EC |PGP )?PRIVATE KEY-----"  # Private keys

    # JWT tokens
    "eyJ[A-Za-z0-9_-]*\\.[A-Za-z0-9_-]*\\.[A-Za-z0-9_-]*"  # JWT tokens

    # GitHub tokens
    "ghp_[A-Za-z0-9]{36}"  # GitHub Personal Access Token
    "gho_[A-Za-z0-9]{36}"  # GitHub OAuth Token
    "ghu_[A-Za-z0-9]{36}"  # GitHub User Token
    "ghs_[A-Za-z0-9]{36}"  # GitHub Server Token

    # Slack tokens
    "xox[baprs]-[0-9]{12}-[0-9]{12}-[a-zA-Z0-9]{24}"  # Slack Token

    # Discord tokens
    "[MN][A-Za-z\\d]{23}\\.[\\w-]{6}\\.[\\w-]{27}"  # Discord Bot Token
)

# Files to check (passed as arguments)
FILES=("$@")

# Exit code
EXIT_CODE=0

# Function to check a single file
check_file() {
    local file="$1"
    local found_secrets=false

    # Skip binary files
    if file "$file" | grep -q "binary"; then
        return 0
    fi

    # Skip large files (> 1MB)
    if [[ $(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null || echo 0) -gt 1048576 ]]; then
        echo -e "${YELLOW}⚠️  Skipping large file: $file${NC}"
        return 0
    fi

    echo "🔍 Checking $file for secret patterns..."

    # Check each pattern
    for pattern in "${SECRET_PATTERNS[@]}"; do
        if grep -Pq "$pattern" "$file" 2>/dev/null; then
            if ! $found_secrets; then
                echo -e "${RED}❌ Potential secrets found in $file:${NC}"
                found_secrets=true
            fi

            # Show matching lines with line numbers
            grep -Pn "$pattern" "$file" 2>/dev/null | while read -r line; do
                echo -e "${RED}  Line: $line${NC}"
            done
        fi
    done

    if $found_secrets; then
        EXIT_CODE=1
        return 1
    else
        echo -e "${GREEN}✅ No secrets found in $file${NC}"
        return 0
    fi
}

# Main execution
if [[ ${#FILES[@]} -eq 0 ]]; then
    echo "Usage: $0 <file1> [file2] [file3] ..."
    exit 1
fi

echo "🔐 Running custom secret pattern detection..."
echo "Files to check: ${#FILES[@]}"

for file in "${FILES[@]}"; do
    if [[ -f "$file" ]]; then
        check_file "$file" || true
    else
        echo -e "${YELLOW}⚠️  File not found or not a regular file: $file${NC}"
    fi
done

if [[ $EXIT_CODE -eq 0 ]]; then
    echo -e "\n${GREEN}🎉 No secrets detected in the scanned files!${NC}"
else
    echo -e "\n${RED}🚨 Potential secrets detected! Please review the files above.${NC}"
    echo "If these are false positives, consider:"
    echo "1. Adding them to .gitleaks.toml allowlist"
    echo "2. Using environment variables instead"
    echo "3. Using a proper secret management system"
fi

exit $EXIT_CODE