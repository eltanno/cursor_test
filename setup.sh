#!/bin/bash
# Unified setup script - handles both greenfield and modernization projects
# Auto-detects project type and runs appropriate setup
#
# Usage:
#   ./setup.sh                           # Manual .env setup
#   ./setup.sh -t TOKEN                  # Auto-create .env with token
#   ./setup.sh --github-token TOKEN      # Auto-create .env with token

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Parse command line arguments
GITHUB_TOKEN=""
while [[ $# -gt 0 ]]; do
    case $1 in
        -t|--github-token)
            GITHUB_TOKEN="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  -t, --github-token TOKEN    Automatically create .env with GitHub token"
            echo "  -h, --help                  Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0                                      # Manual .env setup"
            echo "  $0 -t ghp_your_token_here              # Auto-create .env"
            echo "  $0 --github-token ghp_your_token_here  # Auto-create .env"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use -h or --help for usage information"
            exit 1
            ;;
    esac
done

# Function to print colored output
print_step() {
    echo -e "${BLUE}▶${NC} $1"
}

print_success() {
    echo -e "   ${GREEN}✅${NC} $1"
}

print_warning() {
    echo -e "   ${YELLOW}⚠️${NC}  $1"
}

print_skip() {
    echo -e "   ${YELLOW}⏭️${NC}  $1"
}

print_error() {
    echo -e "${RED}❌ Error:${NC} $1"
}

# Detect project type
detect_project_type() {
    # Check for signs of existing codebase (modernization)
    local has_existing_code=false

    # Look for substantial Python code (not just scaffold)
    if [ -d "src" ] && find src -name "*.py" -type f 2>/dev/null | head -1 | grep -q .; then
        has_existing_code=true
    fi

    # Look for backend/frontend directories with code
    if [ -d "backend/src" ] || [ -d "frontend/src" ]; then
        if find backend frontend -name "*.py" -o -name "*.js" -o -name "*.ts" -o -name "*.tsx" 2>/dev/null | head -5 | grep -q .; then
            has_existing_code=true
        fi
    fi

    # Look for package.json or requirements.txt with dependencies (not just our scaffold)
    if [ -f "requirements.txt" ] && [ $(wc -l < requirements.txt) -gt 10 ]; then
        has_existing_code=true
    fi

    if [ -f "package.json" ] && grep -q "\"dependencies\"" package.json 2>/dev/null; then
        local dep_count=$(grep -A 50 "\"dependencies\"" package.json | grep ":" | wc -l)
        if [ "$dep_count" -gt 3 ]; then
            has_existing_code=true
        fi
    fi

    # Look for Django/Flask/Express specific files
    if [ -f "manage.py" ] || [ -f "app.py" ] || [ -f "server.js" ]; then
        has_existing_code=true
    fi

    if [ "$has_existing_code" = true ]; then
        echo "modernization"
    else
        echo "greenfield"
    fi
}

# Detect languages in project
detect_languages() {
    local langs=()
    if find . -name "*.py" -not -path "*/\.*" -not -path "*/venv/*" -not -path "*/.venv/*" 2>/dev/null | head -1 | grep -q .; then
        langs+=("Python")
    fi
    if find . -name "*.js" -o -name "*.ts" -o -name "*.tsx" -not -path "*/\.*" -not -path "*/node_modules/*" 2>/dev/null | head -1 | grep -q .; then
        langs+=("JavaScript/TypeScript")
    fi
    echo "${langs[@]:-Unknown}"
}

# Detect framework
detect_framework() {
    if [ -f "manage.py" ] || grep -q "django" requirements.txt 2>/dev/null; then
        echo "Django"
    elif grep -q "flask" requirements.txt 2>/dev/null; then
        echo "Flask"
    elif [ -f "package.json" ] && grep -q "react" package.json 2>/dev/null; then
        echo "React"
    elif [ -f "package.json" ] && grep -q "express" package.json 2>/dev/null; then
        echo "Express"
    else
        echo "Unknown"
    fi
}

# Detect structure
detect_structure() {
    if [ -d "frontend" ] && [ -d "backend" ]; then
        echo "Multi-tier"
    else
        echo "Monolithic"
    fi
}

# Count tests
count_tests() {
    local count=0
    if [ -d "tests" ]; then
        count=$(find tests -name "test_*.py" -o -name "*_test.py" -o -name "*.test.js" -o -name "*.test.ts" 2>/dev/null | wc -l)
    fi
    echo "$count"
}

# Auto-detect project type
PROJECT_TYPE=$(detect_project_type)

echo ""
if [ "$PROJECT_TYPE" = "modernization" ]; then
    echo -e "${BLUE}🔍 Legacy Code Modernization Setup${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "✓ Detected existing codebase - running modernization setup"
else
    echo -e "${BLUE}🚀 Greenfield Project Setup${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "✓ Detected new project - running greenfield setup"
fi
echo ""

# Analyze project (for both types)
if [ "$PROJECT_TYPE" = "modernization" ]; then
    print_step "Analyzing legacy project..."
    LANGUAGES=$(detect_languages)
    FRAMEWORK=$(detect_framework)
    STRUCTURE=$(detect_structure)
    TEST_COUNT=$(count_tests)

    echo "   Language(s): $LANGUAGES"
    echo "   Framework: $FRAMEWORK"
    echo "   Structure: $STRUCTURE"
    echo "   Tests: $TEST_COUNT files found"
    echo ""
fi

# Check if git is initialized
if [ ! -d ".git" ]; then
    echo "📦 Git repository not found"
    echo ""
    if [ "$PROJECT_TYPE" = "modernization" ]; then
        print_warning "Git repository required for modernization workflow"
        read -p "Initialize git repository? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            git init
            git branch -m main 2>/dev/null || true
            print_success "Initialized git repository"
        else
            print_error "Git repository required. Exiting."
            exit 1
        fi
    else
        echo "Would you like to:"
        echo "  1) Initialize a new git repository"
        echo "  2) Clone from an existing GitHub repository"
        echo "  3) Skip git setup"
        echo ""
        read -p "Enter your choice (1/2/3): " -n 1 -r GIT_CHOICE
        echo ""
        echo ""

        if [[ $GIT_CHOICE == "1" ]]; then
            echo "📦 Initializing new git repository..."
            git init
            git branch -m main 2>/dev/null || true
            echo "✓ Git repository initialized"
            echo ""
            echo "💡 Don't forget to:"
            echo "   - Add a remote: git remote add origin <your-repo-url>"
            echo "   - Make your first commit after setup completes"
            echo ""
        elif [[ $GIT_CHOICE == "2" ]]; then
            echo "⚠️  To clone from GitHub, please:"
            echo "   1. Exit this script (Ctrl+C)"
            echo "   2. Clone your repository: git clone <your-repo-url>"
            echo "   3. cd into the cloned directory"
            echo "   4. Run ./setup.sh again"
            echo ""
            read -p "Press Enter to continue anyway, or Ctrl+C to exit..."
        else
            echo "⚠️  Skipping git setup"
            echo "   Note: Pre-commit hooks require a git repository"
            echo ""
        fi
    fi
else
    echo "✓ Git repository found"
    if git remote get-url origin &> /dev/null; then
        REMOTE_URL=$(git remote get-url origin)
        echo "  Remote: $REMOTE_URL"
    fi
    echo ""
fi

# Check Python version
PYTHON_CMD=""
if command -v python3 &> /dev/null; then
    PYTHON_CMD="python3"
elif command -v python &> /dev/null; then
    PYTHON_CMD="python"
else
    echo "❌ Error: Python not found. Please install Python 3.8 or higher."
    exit 1
fi

PYTHON_VERSION=$($PYTHON_CMD --version 2>&1 | awk '{print $2}')
echo "✓ Found Python $PYTHON_VERSION"

# Check if python3-venv is available
if ! $PYTHON_CMD -m venv --help &> /dev/null; then
    echo ""
    echo "❌ Error: python3-venv is not installed"
    echo ""
    echo "Please install it with:"
    echo "  sudo apt install python3-venv"
    echo ""
    echo "Then run this script again."
    exit 1
fi

# Create virtual environment
if [ -d ".venv" ]; then
    echo "⚠️  Virtual environment already exists"
    read -p "Do you want to recreate it? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "🗑️  Removing old virtual environment..."
        rm -rf .venv
    else
        echo "Using existing virtual environment"
    fi
fi

if [ ! -d ".venv" ]; then
    echo "📦 Creating virtual environment..."
    $PYTHON_CMD -m venv .venv
    echo "✓ Virtual environment created"
fi

# Activate virtual environment
echo "📦 Installing Python dependencies..."
source .venv/bin/activate

# Upgrade pip
pip install --upgrade pip > /dev/null 2>&1

# Install dependencies
if [ -f "requirements.txt" ]; then
    pip install -r requirements.txt > /dev/null 2>&1
else
    # Install base dependencies for scaffold
    pip install pytest pytest-cov ruff pre-commit vulture bandit > /dev/null 2>&1
fi

echo "✓ Python dependencies installed"
echo ""

# Check Node.js version (for both types if JS/TS detected)
if [[ "$LANGUAGES" == *"JavaScript"* ]] || [ -f "package.json" ]; then
    if command -v node &> /dev/null; then
        NODE_VERSION=$(node --version | cut -d'v' -f2 | cut -d'.' -f1)
        if [ "$NODE_VERSION" -lt 20 ]; then
            echo "⚠️  Node.js $NODE_VERSION detected"
            echo "  Recommended: Node.js 20+"
            if command -v nvm &> /dev/null || [ -s "$HOME/.nvm/nvm.sh" ]; then
                echo "📦 Installing Node 20 with nvm..."
                source ~/.nvm/nvm.sh
                nvm install 20
                nvm use 20
            fi
        else
            echo "✓ Node.js $NODE_VERSION"
        fi
    else
        echo "❌ Node.js not found"
        if command -v nvm &> /dev/null || [ -s "$HOME/.nvm/nvm.sh" ]; then
            echo "📦 Installing Node 20 with nvm..."
            source ~/.nvm/nvm.sh
            nvm install 20
            nvm use 20
        else
            echo "⚠️  Please install Node.js 20+ or nvm for JS/TS linting"
        fi
    fi

    # Install Node dependencies if package.json exists
    if [ -f "package.json" ]; then
        echo "📦 Installing Node.js dependencies..."
        if command -v npm &> /dev/null; then
            npm install > /dev/null 2>&1
            echo "✓ Node.js dependencies installed"
        else
            echo "⚠️  npm not found, skipping Node dependencies"
        fi
    fi
fi

echo ""

# Modernization-specific imports
if [ "$PROJECT_TYPE" = "modernization" ]; then
    print_step "Importing modernization scaffolding..."

    # Create modernization directories
    mkdir -p docs/modernization
    mkdir -p scripts/modernize
    mkdir -p tmp

    # Copy .cursorrules if not exists
    if [ ! -f ".cursorrules" ] && [ -f "$SCRIPT_DIR/.cursorrules" ]; then
        cp "$SCRIPT_DIR/.cursorrules" .
        print_success "Copied .cursorrules"
    fi

    # Copy scripts directories
    if [ ! -d "scripts/github" ] && [ -d "$SCRIPT_DIR/scripts/github" ]; then
        mkdir -p scripts
        cp -r "$SCRIPT_DIR/scripts/github" scripts/
        print_success "Copied scripts/github/"
    fi

    if [ ! -d "scripts/quality" ] && [ -d "$SCRIPT_DIR/scripts/quality" ]; then
        mkdir -p scripts
        cp -r "$SCRIPT_DIR/scripts/quality" scripts/
        print_success "Copied scripts/quality/"
    fi

    if [ ! -d "scripts/utils" ] && [ -d "$SCRIPT_DIR/scripts/utils" ]; then
        mkdir -p scripts
        cp -r "$SCRIPT_DIR/scripts/utils" scripts/
        print_success "Copied scripts/utils/"
    fi

    if [ ! -d "scripts/modernize" ] && [ -d "$SCRIPT_DIR/scripts/modernize" ]; then
        mkdir -p scripts
        cp -r "$SCRIPT_DIR/scripts/modernize" scripts/
        print_success "Copied scripts/modernize/"
    fi

    # Copy docs structure
    mkdir -p docs/architecture docs/api docs/guides docs/planning/features

    if [ ! -f "docs/planning/features/template.md" ] && [ -f "$SCRIPT_DIR/docs/planning/features/template.md" ]; then
        cp "$SCRIPT_DIR/docs/planning/features/template.md" docs/planning/features/
        print_success "Copied docs/planning/features/template.md"
    fi

    # Copy planning documents
    if [ -d "$SCRIPT_DIR/docs/planning/features" ]; then
        for plan in "$SCRIPT_DIR"/docs/planning/features/FEAT-*.md; do
            if [ -f "$plan" ]; then
                basename=$(basename "$plan")
                if [ ! -f "docs/planning/features/$basename" ]; then
                    cp "$plan" docs/planning/features/
                    print_success "Copied docs/planning/features/$basename"
                fi
            fi
        done
    fi

    # Merge .gitignore
    if [ -f "$SCRIPT_DIR/.gitignore" ]; then
        if [ -f ".gitignore" ]; then
            while IFS= read -r line; do
                if [ -n "$line" ] && ! grep -Fxq "$line" .gitignore 2>/dev/null; then
                    echo "$line" >> .gitignore
                fi
            done < "$SCRIPT_DIR/.gitignore"
            print_success "Merged .gitignore"
        else
            cp "$SCRIPT_DIR/.gitignore" .
            print_success "Copied .gitignore"
        fi
    fi

    # Copy other config files
    if [ ! -f ".gitattributes" ] && [ -f "$SCRIPT_DIR/.gitattributes" ]; then
        cp "$SCRIPT_DIR/.gitattributes" .
        print_success "Copied .gitattributes"
    fi

    if [ ! -f ".env.example" ] && [ -f "$SCRIPT_DIR/.env.example" ]; then
        cp "$SCRIPT_DIR/.env.example" .
        print_success "Copied .env.example"
    fi

    print_skip "Skipped .env (contains secrets)"

    # Copy pre-commit config
    if [ ! -f ".pre-commit-config.yaml" ] && [ -f "$SCRIPT_DIR/.pre-commit-config.yaml" ]; then
        cp "$SCRIPT_DIR/.pre-commit-config.yaml" .
        print_success "Copied .pre-commit-config.yaml"
    fi

    # Copy linter configs
    if [ ! -f "ruff.toml" ] && [ -f "$SCRIPT_DIR/ruff.toml" ]; then
        cp "$SCRIPT_DIR/ruff.toml" .
        print_success "Copied ruff.toml"
    fi

    if [ ! -f "pyproject.toml" ] && [ -f "$SCRIPT_DIR/pyproject.toml" ]; then
        cp "$SCRIPT_DIR/pyproject.toml" .
        print_success "Copied pyproject.toml"
    fi

    if [ ! -f ".eslintrc.js" ] && [ -f "$SCRIPT_DIR/.eslintrc.js" ]; then
        cp "$SCRIPT_DIR/.eslintrc.js" .
        print_success "Copied .eslintrc.js"
    fi

    if [ ! -f ".stylelintrc.json" ] && [ -f "$SCRIPT_DIR/.stylelintrc.json" ]; then
        cp "$SCRIPT_DIR/.stylelintrc.json" .
        print_success "Copied .stylelintrc.json"
    fi

    if [ ! -f "package.json" ] && [ -f "$SCRIPT_DIR/package.json" ]; then
        cp "$SCRIPT_DIR/package.json" .
        print_success "Copied package.json"
    fi

    # Copy docs/templates directory
    if [ ! -d "docs/templates" ] && [ -d "$SCRIPT_DIR/docs/templates" ]; then
        mkdir -p docs
        cp -r "$SCRIPT_DIR/docs/templates" docs/
        print_success "Copied docs/templates/"
    fi

    # Copy requirements.txt if not exists
    if [ ! -f "requirements.txt" ] && [ -f "$SCRIPT_DIR/requirements.txt" ]; then
        cp "$SCRIPT_DIR/requirements.txt" .
        print_success "Copied requirements.txt"
    fi

    # Create modernization templates
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
fi

# Install pre-commit hooks
if [ -f ".pre-commit-config.yaml" ]; then
    if command -v pre-commit &> /dev/null; then
        echo "📦 Installing pre-commit hooks..."
        pre-commit install > /dev/null 2>&1
        echo "✓ Pre-commit hooks installed"
    else
        echo "⚠️  pre-commit not found in PATH"
        echo "  Installing via pip..."
        pip install pre-commit > /dev/null 2>&1
        pre-commit install > /dev/null 2>&1
        echo "✓ Pre-commit hooks installed"
    fi
fi

echo ""

# Generate appropriate handoff document
print_step "Generating Cursor handoff document..."

PROJECT_NAME=$(basename "$PWD")
CURRENT_DATE=$(date +%Y-%m-%d)
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null | tr -d '\n' || echo "main")

if [ "$PROJECT_TYPE" = "modernization" ]; then
    # Generate modernization handoff
    if [ -f "$SCRIPT_DIR/docs/templates/handoff-modernization-template.md" ]; then
        HANDOFF_FILE="tmp/cursor-handoff-modernization.md"

        # Build JSON for handoff generation
        cat > /tmp/handoff_vars.json << JSONEOF
{
  "PROJECT_NAME": "$PROJECT_NAME",
  "CURRENT_DATE": "$CURRENT_DATE",
  "PROJECT_DIR": "$PROJECT_NAME",
  "PREVIOUS_WORKSPACE": "<previous workspace>",
  "ORIGINAL_PROJECT_PATH": "<original project path>",
  "PROJECT_PATH": "$PWD",
  "SCAFFOLD_PATH": "$SCRIPT_DIR",
  "TECH_STACK": "- **Languages:** $LANGUAGES\\n- **Framework:** $FRAMEWORK\\n- **Structure:** $STRUCTURE",
  "ARCHITECTURE": "**Architecture:** $([ "$STRUCTURE" = "Multi-tier" ] && echo "Multi-tier monorepo" || echo "Monolithic")",
  "WHY_MODERNIZING": "- No automated tests ($TEST_COUNT test files found)\\n- No linting/code quality tools detected\\n- Technical debt accumulated\\n- Needs systematic improvement with safety guarantees",
  "EXCLUDED_ARTIFACTS": "(.db_data, caddy cache, node_modules, __pycache__, backups)",
  "RSYNC_COMMAND": "rsync -av --exclude='.git' --exclude='node_modules' --exclude='__pycache__' --exclude='.venv' --exclude='tmp' <source> <target>",
  "ANALYSIS_RESULTS": "- Language(s): $LANGUAGES\\n- Framework: $FRAMEWORK\\n- Structure: $STRUCTURE\\n- Tests Found: **$TEST_COUNT files**\\n- Linters: None detected\\n- CI/CD: None detected",
  "TIMESTAMP": "$TIMESTAMP",
  "CURRENT_BRANCH": "$CURRENT_BRANCH",
  "GITHUB_TOKEN": "$([ -f ".env" ] && grep -q "GITHUB_API_KEY" .env && echo "(found in .env)" || echo "your_token_here")",
  "APPLICATION_SECRETS": "   - PIPELINES_API_KEY\\n   - POSTGRES_PASSWORD\\n   - REDIS_AUTH\\n   - (check existing .env for more)",
  "SUGGESTED_REPO_NAME": "$PROJECT_NAME",
  "SUGGESTED_REPO_DESCRIPTION": "$PROJECT_NAME - Modernized with TDD, linting, and automated testing",
  "GITHUB_OWNER": "<from .env>",
  "DEFAULT_BRANCH": "$CURRENT_BRANCH",
  "EXAMPLE_FUNCTION": "example_function",
  "EXAMPLE_BUG": "Returns incorrect value",
  "EXAMPLE_INPUT": "test_input",
  "EXAMPLE_OUTPUT": "actual_output",
  "EXPECTED_OUTPUT": "expected_output",
  "USER_STACK_PREFERENCES": "- **Backend:** Django (default)\\n- **Frontend:** React (default)\\n- **Database:** PostgreSQL (default)\\n- **Architecture:** Monorepo (multi-tier in one repo)\\n- **Containerization:** Docker Compose\\n- **Testing:** Unit tests (always) + E2E tests (feature-dependent)",
  "USER_INFO": "- **GitHub Username:** (check .env for GITHUB_OWNER)\\n- **GitHub Token:** Stored in .env as GITHUB_API_KEY\\n- **Token Scopes:** repo, project, admin:org",
  "GITHUB_URLS": "- **User's Projects:** https://github.com/users/<GITHUB_OWNER>/projects/\\n- **New Project:** Will be https://github.com/<GITHUB_OWNER>/$PROJECT_NAME (after Step 3)",
  "SCAFFOLD_GITHUB_URL": "Not yet pushed (local only)"
}
JSONEOF

        if [ -f "$SCRIPT_DIR/scripts/modernize/generate_handoff.py" ]; then
            $PYTHON_CMD "$SCRIPT_DIR/scripts/modernize/generate_handoff.py" \
                "$SCRIPT_DIR/docs/templates/handoff-modernization-template.md" \
                "/tmp/handoff_vars.json" > /dev/null 2>&1

            rm /tmp/handoff_vars.json

            if [ -f "$HANDOFF_FILE" ]; then
                print_success "Generated modernization handoff: $HANDOFF_FILE"
            fi
        fi
    fi

    # Create quick start guide
    cat > tmp/QUICK_START.md << 'EOFQS'
# Quick Start - New Cursor Session (Modernization)

## 🚀 First Message to Agent

```
Please read tmp/cursor-handoff-modernization.md and continue from there.

I've updated the .env file with my GitHub API key.

Let's proceed with:
1. Committing the template import
2. Creating the GitHub repository and project
3. Running the codebase assessment
```

## ⚡ Quick Commands

### Commit Template
```bash
git add .
git commit -m "chore: import modernization template"
```

### Create GitHub Repo
```bash
source .venv/bin/activate
python scripts/github/create_repo_and_project.py --name "project-modernized" --private --init-git
git push -u origin main
```

### Run Assessment
```bash
python scripts/modernize/assess_codebase.py
cat docs/modernization/assessment.md
```
EOFQS
    print_success "Created quick start guide: tmp/QUICK_START.md"

else
    # Generate greenfield handoff
    if [ -f "$SCRIPT_DIR/docs/templates/handoff-greenfield-template.md" ]; then
        HANDOFF_FILE="tmp/cursor-handoff-greenfield.md"

        ENV_STATUS="needs configuration"
        [ -f ".env" ] && ENV_STATUS="configured"

        GITHUB_STATUS="⏳"
        GITHUB_DETAILS="- **Status:** Not yet created\n- **Action:** Run \`python scripts/github/create_repo_and_project.py\`"
        GIT_REMOTE="Not yet configured"
        KANBAN_URL="<will be set after repo creation>"

        if git remote get-url origin &> /dev/null; then
            GIT_REMOTE=$(git remote get-url origin)
            GITHUB_STATUS="✅"
            GITHUB_DETAILS="- **Repository:** $GIT_REMOTE\n- **Status:** Created"
        fi

        cat > /tmp/greenfield_handoff_vars.json << JSONEOF
{
  "PROJECT_NAME": "$PROJECT_NAME",
  "PROJECT_DIR": "$PROJECT_NAME",
  "CURRENT_DATE": "$CURRENT_DATE",
  "PROJECT_PHASE": "Initial Setup Complete",
  "CURRENT_STATUS": "✅ Scaffolding ready, awaiting first feature planning",
  "PROJECT_DESCRIPTION": "<to be defined>",
  "PROJECT_PURPOSE": "<to be defined>",
  "TECH_STACK": "- **Languages:** Python, JavaScript/TypeScript (if applicable)\\n- **Framework:** <to be chosen>\\n- **Database:** <to be chosen>",
  "ARCHITECTURE": "**Architecture:** <to be defined - see FEAT-002 for multi-tier guidance>",
  "TOOLING_SETUP": "- ✅ Python virtual environment (.venv)\\n- ✅ Pre-commit hooks\\n- ✅ Linters configured\\n- ✅ Git repository initialized",
  "GITHUB_STATUS": "$GITHUB_STATUS",
  "GITHUB_DETAILS": "$GITHUB_DETAILS",
  "DIRECTORY_STRUCTURE": "├── src/              # Application code (to be created)\\n├── tests/            # Test files (to be created)\\n├── scripts/          # Infrastructure scripts\\n├── docs/             # Documentation\\n├── tmp/              # Temporary files\\n├── .cursorrules      # Development workflow rules\\n└── .venv/            # Python virtual environment",
  "CURRENT_BRANCH": "$CURRENT_BRANCH",
  "GIT_REMOTE": "$GIT_REMOTE",
  "COMMIT_COUNT": "$(git rev-list --count HEAD 2>/dev/null || echo '0')",
  "ENV_STATUS": "$ENV_STATUS",
  "REQUIRED_ENV_VARS": "   - \`GITHUB_API_KEY\`\\n   - \`GITHUB_OWNER\`\\n   - \`GITHUB_REPO\`\\n   - \`GITHUB_PROJECT_NUMBER\`",
  "STEP_1_STATUS": "✅",
  "STEP_2_STATUS": "🔜",
  "STEP_3_STATUS": "⏳",
  "STEP_4_STATUS": "⏳",
  "STEP_5_STATUS": "⏳",
  "SUGGESTED_REPO_NAME": "$PROJECT_NAME",
  "DEFAULT_BRANCH": "$CURRENT_BRANCH",
  "TEST_COMMAND": "pytest tests/",
  "COVERAGE_COMMAND": "pytest --cov=src tests/",
  "PYTHON_PACKAGES": "- pytest, pytest-cov\\n- ruff (linter/formatter)\\n- pre-commit\\n- vulture\\n- bandit",
  "LINTER_CONFIGS": "- **Python:** \`ruff.toml\`\\n- **JavaScript/TypeScript:** \`.eslintrc.js\`\\n- **CSS/SCSS:** \`.stylelintrc.json\`",
  "USER_STACK_PREFERENCES": "- **Backend:** Django (default)\\n- **Frontend:** React (default)\\n- **Database:** PostgreSQL (default)\\n- **Testing:** Unit tests (always) + E2E tests (feature-dependent)",
  "SCAFFOLD_PATH": "$SCRIPT_DIR",
  "SCAFFOLD_GITHUB_URL": "Not yet pushed (local only)",
  "USER_INFO": "- **GitHub Username:** (check .env for GITHUB_OWNER)\\n- **GitHub Token:** Stored in .env as GITHUB_API_KEY",
  "GITHUB_URLS": "- **Your Projects:** https://github.com/users/<GITHUB_OWNER>/projects/",
  "KANBAN_URL": "$KANBAN_URL",
  "NEXT_PHASE": "Planning & Feature Development"
}
JSONEOF

        if [ -f "$SCRIPT_DIR/scripts/utils/generate_greenfield_handoff.py" ]; then
            $PYTHON_CMD "$SCRIPT_DIR/scripts/utils/generate_greenfield_handoff.py" \
                "$SCRIPT_DIR/docs/templates/handoff-greenfield-template.md" \
                "/tmp/greenfield_handoff_vars.json" > /dev/null 2>&1

            rm /tmp/greenfield_handoff_vars.json

            if [ -f "$HANDOFF_FILE" ]; then
                print_success "Generated greenfield handoff: $HANDOFF_FILE"
            fi
        fi
    fi
fi

echo ""

# Handle .env creation if token provided
if [ -n "$GITHUB_TOKEN" ]; then
    print_step "Creating .env file with provided token..."

    if [ -f ".env" ]; then
        print_warning ".env file already exists"
        read -p "Overwrite with new token? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_skip "Keeping existing .env file"
        else
            cp .env.example .env
            echo "GITHUB_API_KEY=$GITHUB_TOKEN" >> .env
            print_success "Created .env with GitHub token"
        fi
    else
        cp .env.example .env
        echo "GITHUB_API_KEY=$GITHUB_TOKEN" >> .env
        print_success "Created .env with GitHub token"
    fi
    echo ""
fi

echo ""
echo -e "${GREEN}✅ Setup complete!${NC}"
echo ""
echo "📝 Next steps:"
echo ""

if [ "$PROJECT_TYPE" = "modernization" ]; then
    echo "  1. Review changes:"
    echo "     git diff"
    echo ""

    if [ -z "$GITHUB_TOKEN" ]; then
        echo "  2. Update .env with GitHub API key:"
        echo "     cp .env.example .env && nano .env"
        echo ""
        NEXT_STEP=3
    else
        echo "  2. ✓ .env already configured with GitHub token"
        echo ""
        NEXT_STEP=2
    fi

    echo "  $NEXT_STEP. Commit template import:"
    echo "     git add . && git commit -m 'chore: import modernization template'"
    echo ""
    ((NEXT_STEP++))
    echo "  $NEXT_STEP. Create GitHub repository:"
    echo "     source .venv/bin/activate"
    echo "     python scripts/github/create_repo_and_project.py --name \"$PROJECT_NAME\" --private --init-git"
    echo "     git push -u origin $CURRENT_BRANCH"
    echo ""
    ((NEXT_STEP++))
    echo "  $NEXT_STEP. Run codebase assessment:"
    echo "     python scripts/modernize/assess_codebase.py"
    echo "     cat docs/modernization/assessment.md"
    echo ""
    ((NEXT_STEP++))
    echo "  $NEXT_STEP. For switching Cursor sessions:"
    echo "     Read tmp/cursor-handoff-modernization.md"
else
    echo "  1. Activate virtual environment:"
    echo "     source .venv/bin/activate"
    echo ""

    if [ -z "$GITHUB_TOKEN" ]; then
        echo "  2. Configure environment:"
        echo "     cp .env.example .env && nano .env"
        echo ""
        NEXT_STEP=3
    else
        echo "  2. ✓ .env already configured with GitHub token"
        echo ""
        NEXT_STEP=2
    fi

    echo "  $NEXT_STEP. Create GitHub repository:"
    echo "     python scripts/github/create_repo_and_project.py --name \"$PROJECT_NAME\" --private --init-git"
    echo ""
    ((NEXT_STEP++))
    echo "  $NEXT_STEP. Make initial commit:"
    echo "     git add . && git commit -m 'chore: initial setup'"
    echo "     git push -u origin $CURRENT_BRANCH"
    echo ""
    ((NEXT_STEP++))
    echo "  $NEXT_STEP. For switching Cursor sessions:"
    echo "     Read tmp/cursor-handoff-greenfield.md"
fi

echo ""
echo "🎉 Happy coding!"
echo ""
echo "💡 Tip: Pre-commit hooks will run automatically on 'git commit'"
