#!/bin/bash
# Setup script for cursor-test project
# Creates virtual environment and installs dependencies

set -e  # Exit on error

echo "🚀 Setting up cursor-test development environment..."
echo ""

# Check if git is initialized
if [ ! -d ".git" ]; then
    echo "📦 Git repository not found"
    echo ""
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
else
    echo "✓ Git repository found"
    # Show current remote if exists
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
echo "🔌 Activating virtual environment..."
source .venv/bin/activate

# Upgrade pip
echo "⬆️  Upgrading pip..."
pip install --upgrade pip -q

# Install dependencies
echo "📚 Installing Python dependencies..."
pip install -r requirements.txt -q

# Install pre-commit hooks
if [ -d ".git" ]; then
    echo "🪝 Installing pre-commit hooks..."
    pre-commit install
    echo "✓ Pre-commit hooks installed"
else
    echo "⚠️  Skipping pre-commit hooks (no git repository)"
    echo "   Run 'pre-commit install' after initializing git"
fi

# Check for Node.js and nvm
echo ""
echo "📦 Checking Node.js setup..."
if command -v node &> /dev/null; then
    NODE_VERSION=$(node --version)
    NODE_MAJOR=$(echo $NODE_VERSION | cut -d. -f1 | tr -d 'v')

    if [ "$NODE_MAJOR" -lt 20 ]; then
        echo "⚠️  Node.js $NODE_VERSION found, but version 20+ is required"
        if command -v nvm &> /dev/null || [ -s "$HOME/.nvm/nvm.sh" ]; then
            echo "📦 Switching to Node 20 with nvm..."
            source ~/.nvm/nvm.sh
            nvm use 20 || nvm install 20
        else
            echo "❌ Please install Node.js 20+ or nvm"
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
        npm install
        echo "✓ Node.js dependencies installed"
    else
        echo "⚠️  npm not found, skipping Node dependencies"
    fi
fi

echo ""
echo "📄 Generating Cursor handoff document..."

# Generate greenfield handoff
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_NAME=$(basename "$PWD")
CURRENT_DATE=$(date +%Y-%m-%d)
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null | tr -d '\n' || echo "main")

# Check if .env exists
ENV_STATUS="needs configuration"
if [ -f ".env" ]; then
    ENV_STATUS="configured"
fi

# Check if GitHub repo/project created
GITHUB_STATUS="⏳"
GITHUB_DETAILS="- **Status:** Not yet created\n- **Action:** Run \`python scripts/github/create_repo_and_project.py\`"
GIT_REMOTE="Not yet configured"
KANBAN_URL="<will be set after repo creation>"

if git remote get-url origin &> /dev/null; then
    GIT_REMOTE=$(git remote get-url origin)
    GITHUB_STATUS="✅"
    GITHUB_DETAILS="- **Repository:** $GIT_REMOTE\n- **Status:** Created\n- **Project:** Check GitHub for Kanban board"
    # Extract owner/repo from URL
    if [[ $GIT_REMOTE =~ github\.com[:/]([^/]+)/([^/.]+) ]]; then
        GITHUB_OWNER="${BASH_REMATCH[1]}"
        GITHUB_REPO="${BASH_REMATCH[2]}"
        KANBAN_URL="https://github.com/users/$GITHUB_OWNER/projects/"
    fi
fi

# Determine project phase
PROJECT_PHASE="Initial Setup Complete"
NEXT_PHASE="Planning & Feature Development"
CURRENT_STATUS="✅ Scaffolding ready, awaiting first feature planning"

# Build JSON for handoff
mkdir -p tmp
cat > /tmp/greenfield_handoff_vars.json << JSONEOF
{
  "PROJECT_NAME": "$PROJECT_NAME",
  "PROJECT_DIR": "$PROJECT_NAME",
  "CURRENT_DATE": "$CURRENT_DATE",
  "PROJECT_PHASE": "$PROJECT_PHASE",
  "CURRENT_STATUS": "$CURRENT_STATUS",
  "PROJECT_DESCRIPTION": "<to be defined>",
  "PROJECT_PURPOSE": "<to be defined>",
  "TECH_STACK": "- **Languages:** Python, JavaScript/TypeScript (if applicable)\\n- **Framework:** <to be chosen>\\n- **Database:** <to be chosen>",
  "ARCHITECTURE": "**Architecture:** <to be defined - see FEAT-002 for multi-tier guidance>",
  "TOOLING_SETUP": "- ✅ Python virtual environment (.venv)\\n- ✅ Pre-commit hooks (Ruff, ESLint, Stylelint)\\n- ✅ Linters configured\\n- ✅ Git repository initialized",
  "GITHUB_STATUS": "$GITHUB_STATUS",
  "GITHUB_DETAILS": "$GITHUB_DETAILS",
  "DIRECTORY_STRUCTURE": "├── src/              # Application code (to be created)\\n├── tests/            # Test files (to be created)\\n├── scripts/          # Infrastructure scripts\\n├── docs/             # Documentation\\n├── tmp/              # Temporary files\\n├── .cursorrules      # Development workflow rules\\n└── .venv/            # Python virtual environment",
  "CURRENT_BRANCH": "$CURRENT_BRANCH",
  "GIT_REMOTE": "$GIT_REMOTE",
  "COMMIT_COUNT": "$(git rev-list --count HEAD 2>/dev/null || echo '0')",
  "ENV_STATUS": "$ENV_STATUS",
  "REQUIRED_ENV_VARS": "   - \`GITHUB_API_KEY\` - Your GitHub Personal Access Token\\n   - \`GITHUB_OWNER\` - Your GitHub username\\n   - \`GITHUB_REPO\` - Repository name\\n   - \`GITHUB_PROJECT_NUMBER\` - Project number (auto-filled)",
  "STEP_1_STATUS": "✅",
  "STEP_2_STATUS": "🔜",
  "STEP_3_STATUS": "⏳",
  "STEP_4_STATUS": "⏳",
  "STEP_5_STATUS": "⏳",
  "SUGGESTED_REPO_NAME": "$PROJECT_NAME",
  "DEFAULT_BRANCH": "$CURRENT_BRANCH",
  "TEST_COMMAND": "pytest tests/",
  "COVERAGE_COMMAND": "pytest --cov=src tests/",
  "PYTHON_PACKAGES": "- pytest, pytest-cov\\n- ruff (linter/formatter)\\n- pre-commit\\n- vulture (dead code detection)\\n- bandit (security)",
  "LINTER_CONFIGS": "- **Python:** \`ruff.toml\` (88 char lines, single quotes, 40+ rule sets)\\n- **JavaScript/TypeScript:** \`.eslintrc.js\` (Airbnb style, 100 char lines)\\n- **CSS/SCSS:** \`.stylelintrc.json\` (standard config, no IDs, max 4 nesting)",
  "USER_STACK_PREFERENCES": "- **Backend:** Django (default)\\n- **Frontend:** React (default)\\n- **Database:** PostgreSQL (default)\\n- **Architecture:** Monorepo (multi-tier in one repo)\\n- **Containerization:** Docker Compose\\n- **Testing:** Unit tests (always) + E2E tests (feature-dependent)",
  "SCAFFOLD_PATH": "$SCRIPT_DIR",
  "SCAFFOLD_GITHUB_URL": "Not yet pushed (local only)",
  "USER_INFO": "- **GitHub Username:** (check .env for GITHUB_OWNER)\\n- **GitHub Token:** Stored in .env as GITHUB_API_KEY\\n- **Token Scopes:** repo, project, admin:org",
  "GITHUB_URLS": "- **Your Projects:** https://github.com/users/<GITHUB_OWNER>/projects/\\n- **This Project:** $GIT_REMOTE",
  "KANBAN_URL": "$KANBAN_URL",
  "NEXT_PHASE": "$NEXT_PHASE"
}
JSONEOF

# Generate handoff if template exists
if [ -f "$SCRIPT_DIR/docs/templates/handoff-greenfield-template.md" ]; then
    python3 "$SCRIPT_DIR/scripts/utils/generate_greenfield_handoff.py" \
        "$SCRIPT_DIR/docs/templates/handoff-greenfield-template.md" \
        "/tmp/greenfield_handoff_vars.json" > /dev/null 2>&1

    rm /tmp/greenfield_handoff_vars.json

    if [ -f "tmp/cursor-handoff-greenfield.md" ]; then
        echo "✓ Greenfield handoff generated: tmp/cursor-handoff-greenfield.md"
    fi
else
    echo "⚠️  Handoff template not found, skipping"
fi

echo ""
echo "✅ Setup complete!"
echo ""
echo "📝 Next steps:"
echo "  1. Activate the virtual environment:"
echo "     source .venv/bin/activate"
echo ""
echo "  2. If using Node.js/TypeScript, activate Node 20:"
echo "     source ~/.nvm/nvm.sh && nvm use 20"
echo ""
echo "  3. Copy .env.example to .env and add your GitHub token:"
echo "     cp .env.example .env"
echo "     nano .env  # or use your preferred editor"
echo ""
echo "  4. Verify setup:"
echo "     python -c \"from scripts.utils.github_api import GitHubAPI; api = GitHubAPI(); print('✓ Ready!')\""
echo ""
echo "  5. Read the linting guide:"
echo "     cat docs/LINTING.md"
echo ""
echo "  6. For switching Cursor sessions:"
echo "     cat tmp/cursor-handoff-greenfield.md"
echo ""
echo "🎉 Happy coding!"
echo ""
echo "💡 Tip: Pre-commit hooks are now installed and will run automatically on 'git commit'"
