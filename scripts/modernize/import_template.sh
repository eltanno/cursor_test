#!/bin/bash
#
# import_template.sh - Import cursor-test template scaffolding into legacy project
#
# Usage: ./import_template.sh [target_directory]
#
# This script non-destructively imports the template structure into an existing
# legacy codebase, setting up the modernization workflow.

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory (where this script is located)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Target directory (legacy project)
TARGET_DIR="${1:-.}"
TARGET_DIR="$(cd "$TARGET_DIR" && pwd)"

echo -e "${BLUE}🔍 Legacy Code Modernization - Template Import${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Function to print step
print_step() {
    echo -e "${BLUE}▶${NC} $1"
}

# Function to print success
print_success() {
    echo -e "   ${GREEN}✅${NC} $1"
}

# Function to print warning
print_warning() {
    echo -e "   ${YELLOW}⚠️${NC}  $1"
}

# Function to print skip
print_skip() {
    echo -e "   ${YELLOW}⏭️${NC}  $1"
}

# Function to print error
print_error() {
    echo -e "${RED}❌ Error:${NC} $1"
}

# Check if target directory exists
if [ ! -d "$TARGET_DIR" ]; then
    print_error "Target directory does not exist: $TARGET_DIR"
    exit 1
fi

# Check if target directory is a git repository
if [ ! -d "$TARGET_DIR/.git" ]; then
    print_warning "Target directory is not a git repository"
    read -p "Initialize git repository? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        cd "$TARGET_DIR"
        git init
        print_success "Initialized git repository"
    else
        print_error "Git repository required for modernization workflow"
        exit 1
    fi
fi

echo ""
print_step "Analyzing legacy project..."
cd "$TARGET_DIR"

# Detect languages
LANGUAGES=()
if find . -name "*.py" -not -path "*/\.*" -not -path "*/venv/*" -not -path "*/.venv/*" | head -1 | grep -q .; then
    LANGUAGES+=("Python")
fi
if find . -name "*.js" -o -name "*.ts" -not -path "*/\.*" -not -path "*/node_modules/*" | head -1 | grep -q .; then
    LANGUAGES+=("JavaScript/TypeScript")
fi

echo "   Language(s): ${LANGUAGES[*]:-Unknown}"

# Detect framework
FRAMEWORK="Unknown"
if [ -f "manage.py" ] || grep -q "django" requirements.txt 2>/dev/null || grep -q "django" setup.py 2>/dev/null; then
    FRAMEWORK="Django"
elif grep -q "flask" requirements.txt 2>/dev/null || grep -q "flask" setup.py 2>/dev/null; then
    FRAMEWORK="Flask"
elif [ -f "package.json" ] && grep -q "react" package.json 2>/dev/null; then
    FRAMEWORK="React"
elif [ -f "package.json" ] && grep -q "express" package.json 2>/dev/null; then
    FRAMEWORK="Express"
fi

echo "   Framework: $FRAMEWORK"

# Detect structure
if [ -d "frontend" ] && [ -d "backend" ]; then
    STRUCTURE="Multi-tier"
else
    STRUCTURE="Monolithic"
fi

echo "   Structure: $STRUCTURE"

# Check for existing tests
TEST_COUNT=0
if [ -d "tests" ]; then
    TEST_COUNT=$(find tests -name "test_*.py" -o -name "*_test.py" -o -name "*.test.js" -o -name "*.test.ts" 2>/dev/null | wc -l)
fi
echo "   Tests: $TEST_COUNT files found"

# Check for linters
LINTERS=""
[ -f "ruff.toml" ] && LINTERS="$LINTERS Ruff"
[ -f ".eslintrc.js" ] || [ -f ".eslintrc.json" ] && LINTERS="$LINTERS ESLint"
[ -z "$LINTERS" ] && LINTERS="None detected"
echo "   Linters:$LINTERS"

# Check for CI/CD
CICD=""
[ -d ".github/workflows" ] && CICD="$CICD GitHub-Actions"
[ -f ".gitlab-ci.yml" ] && CICD="$CICD GitLab-CI"
[ -f "Jenkinsfile" ] && CICD="$CICD Jenkins"
[ -z "$CICD" ] && CICD="None detected"
echo "   CI/CD:$CICD"

echo ""
print_step "Importing template scaffolding..."

# Create modernization directories
mkdir -p docs/modernization
mkdir -p scripts/modernize
mkdir -p tmp

# Copy .cursorrules (if not exists)
if [ ! -f ".cursorrules" ]; then
    cp "$TEMPLATE_ROOT/.cursorrules" .
    print_success "Copied .cursorrules"
else
    print_skip "Skipped .cursorrules (already exists)"
fi

# Copy scripts/ directory (merge with existing)
if [ ! -d "scripts/github" ]; then
    cp -r "$TEMPLATE_ROOT/scripts/github" scripts/
    print_success "Copied scripts/github/"
fi

if [ ! -d "scripts/quality" ]; then
    cp -r "$TEMPLATE_ROOT/scripts/quality" scripts/
    print_success "Copied scripts/quality/"
fi

if [ ! -d "scripts/utils" ]; then
    cp -r "$TEMPLATE_ROOT/scripts/utils" scripts/
    print_success "Copied scripts/utils/"
fi

# Copy docs/ directory structure
mkdir -p docs/architecture
mkdir -p docs/api
mkdir -p docs/guides
mkdir -p docs/planning/features

if [ ! -f "docs/planning/features/template.md" ]; then
    cp "$TEMPLATE_ROOT/docs/planning/features/template.md" docs/planning/features/
    print_success "Copied docs/planning/features/template.md"
fi

# Copy planning documents
for plan in "$TEMPLATE_ROOT"/docs/planning/features/FEAT-*.md; do
    basename=$(basename "$plan")
    if [ ! -f "docs/planning/features/$basename" ]; then
        cp "$plan" docs/planning/features/
        print_success "Copied docs/planning/features/$basename"
    fi
done

# Merge .gitignore
if [ -f ".gitignore" ]; then
    # Append template entries that don't already exist
    while IFS= read -r line; do
        if [ -n "$line" ] && ! grep -Fxq "$line" .gitignore 2>/dev/null; then
            echo "$line" >> .gitignore
        fi
    done < "$TEMPLATE_ROOT/.gitignore"
    print_success "Merged .gitignore"
else
    cp "$TEMPLATE_ROOT/.gitignore" .
    print_success "Copied .gitignore"
fi

# Copy .gitattributes (if not exists)
if [ ! -f ".gitattributes" ]; then
    cp "$TEMPLATE_ROOT/.gitattributes" .
    print_success "Copied .gitattributes"
fi

# Copy .env.example (if not exists)
if [ ! -f ".env.example" ]; then
    cp "$TEMPLATE_ROOT/.env.example" .
    print_success "Copied .env.example"
fi

# Skip .env (secrets)
print_skip "Skipped .env (contains secrets)"

# Merge .pre-commit-config.yaml
if [ -f ".pre-commit-config.yaml" ]; then
    print_warning "Merging .pre-commit-config.yaml (manual review recommended)"
    # For now, just note that it exists
else
    cp "$TEMPLATE_ROOT/.pre-commit-config.yaml" .
    print_success "Copied .pre-commit-config.yaml"
fi

echo ""
print_step "Setting up tooling..."

# Create Python virtual environment
if [[ " ${LANGUAGES[@]} " =~ " Python " ]]; then
    if [ ! -d ".venv" ]; then
        python3 -m venv .venv
        source .venv/bin/activate
        pip install --upgrade pip > /dev/null 2>&1
        pip install ruff pre-commit > /dev/null 2>&1
        print_success "Created .venv and installed Python tools"
    else
        print_skip "Skipped .venv (already exists)"
    fi
fi

# Install Node.js dependencies (if package.json exists)
if [ -f "package.json" ]; then
    if [ ! -d "node_modules" ]; then
        npm install > /dev/null 2>&1
        print_success "Installed Node.js dependencies"
    else
        print_skip "Skipped npm install (node_modules exists)"
    fi
fi

# Install pre-commit hooks
if [ -f ".pre-commit-config.yaml" ]; then
    if command -v pre-commit &> /dev/null; then
        pre-commit install > /dev/null 2>&1
        print_success "Installed pre-commit hooks"
    else
        print_warning "pre-commit not found, skipping hook installation"
    fi
fi

echo ""
print_step "Creating modernization structure..."

# Create assessment template
cat > docs/modernization/assessment.md << 'EOF'
# Legacy Codebase Assessment

Generated: $(date +%Y-%m-%d)

## Executive Summary

*To be filled by assessment script*

## Functionality Inventory

### Core Features

### Entry Points

## Architecture

### Current Structure

### Issues

## Test Coverage

### Current State

### Gaps

## Code Quality

### Complexity

### Duplication

### Linting Issues

## Dependencies

### Outdated

### Security Issues

## Technical Debt

## Risk Assessment

## Refactor Opportunities

## Recommended Approach

## Next Steps
EOF

print_success "Created docs/modernization/assessment.md"

# Create characterization tests tracking template
cat > docs/modernization/characterization-tests.md << 'EOF'
# Characterization Tests Progress

## Critical Paths

### Feature 1
- [ ] test_name_1
- [ ] test_name_2
- **Coverage**: 0% (target: 90%)

## Complex Functions

## Summary

- **Total Tests Written**: 0
- **Total Tests Needed**: TBD
- **Overall Coverage**: 0% (goal: 80%)
EOF

print_success "Created docs/modernization/characterization-tests.md"

# Create refactor plan template
cat > docs/modernization/refactor-plan.md << 'EOF'
# Legacy Code Refactor Plan

## Overview

This plan breaks the modernization into discrete, safe tasks.

**Guiding Principles**:
1. Characterization tests must pass at all times
2. Small, incremental changes
3. Each PR maintains existing behavior

## Task Breakdown

### Phase 1: Stabilize

#### TASK-001: Title
**Priority**: HIGH/MEDIUM/LOW
**Risk**: HIGH/MEDIUM/LOW
**Effort**: X days

**What**:
- Description

**Why**:
- Rationale

**Acceptance Criteria**:
- [ ] Criterion 1
- [ ] All characterization tests pass

**Dependencies**: None

---

## Progress Tracking

Use GitHub Issues and Kanban board.
EOF

print_success "Created docs/modernization/refactor-plan.md"

# Create tmp/ README
cat > tmp/README.md << 'EOF'
# Temporary Files Directory

This directory is for temporary files created during development and modernization.

**Purpose:**
- Session summaries
- Scratch calculations
- Temporary scripts
- Debug output

**Important:**
- This directory is gitignored
- Files here can be deleted after session
- Use descriptive names: `session-summary-YYYY-MM-DD.md`
EOF

print_success "Created tmp/README.md"

echo ""
print_step "Generating import report..."

# Create import report
REPORT_FILE="tmp/import-report-$(date +%Y%m%d-%H%M%S).md"
cat > "$REPORT_FILE" << EOF
# Template Import Report

Generated: $(date +%Y-%m-%d %H:%M:%S)

## Analysis Results

- **Language(s)**: ${LANGUAGES[*]:-Unknown}
- **Framework**: $FRAMEWORK
- **Structure**: $STRUCTURE
- **Tests Found**: $TEST_COUNT files
- **Linters**:$LINTERS
- **CI/CD**:$CICD

## Files Imported

### Copied
- .cursorrules
- scripts/github/
- scripts/quality/
- scripts/utils/
- docs/planning/features/template.md
- docs/planning/features/FEAT-*.md
- .gitattributes
- .env.example
- .pre-commit-config.yaml (if not existed)

### Merged
- .gitignore (appended template entries)

### Created
- docs/modernization/assessment.md
- docs/modernization/characterization-tests.md
- docs/modernization/refactor-plan.md
- tmp/README.md

### Skipped
- .env (contains secrets)
- Existing source code
- Existing tests
- Project-specific configs

## Tooling Setup

- Python virtual environment: $([ -d ".venv" ] && echo "✅ Created" || echo "⏭️  Skipped")
- Pre-commit hooks: $([ -f ".git/hooks/pre-commit" ] && echo "✅ Installed" || echo "⏭️  Skipped")

## Next Steps

1. **Review changes**: \`git diff\`
2. **Review .env.example**: Copy to .env and fill in values
3. **Commit template import**:
   \`\`\`bash
   git add .
   git commit -m "chore: import modernization template"
   \`\`\`
4. **Run assessment**:
   \`\`\`bash
   source .venv/bin/activate  # if Python project
   python scripts/modernize/assess_codebase.py
   \`\`\`
5. **Review assessment**: \`docs/modernization/assessment.md\`
6. **Begin characterization tests**: Start with critical paths

## Documentation

- **Planning**: \`docs/planning/features/FEAT-003-legacy-code-modernization.md\`
- **Rules**: \`.cursorrules\` (search for "Legacy Code Modernization")

## Support

For issues or questions, refer to the planning documents or create a GitHub issue.

---

🚀 **Ready to modernize your legacy codebase!**
EOF

echo ""
echo -e "${GREEN}🎉 Template scaffolding imported successfully!${NC}"
echo ""
echo "📋 Import report saved to: $REPORT_FILE"
echo ""
echo -e "${BLUE}Next Steps:${NC}"
echo "1. Review changes: git diff"
echo "2. Review .env.example and create .env"
echo "3. Commit template: git add . && git commit -m \"chore: import modernization template\""
echo "4. Run assessment: python scripts/modernize/assess_codebase.py"
echo "5. Review assessment: docs/modernization/assessment.md"
echo ""
echo -e "${BLUE}Documentation:${NC}"
echo "- Planning: docs/planning/features/FEAT-003-legacy-code-modernization.md"
echo "- Rules: .cursorrules (search for \"Legacy Code Modernization\")"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
