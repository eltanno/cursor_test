# Cursor Test - AI Agent Development Workspace

A learning project for understanding Cursor AI agents with opinionated development workflows, automated planning documentation, and GitHub Kanban integration.

## 🎯 Project Goals

This repository demonstrates:

1. **Planning-First Development**: All features start with comprehensive planning documents
2. **Test-Driven Development (TDD)**: Red → Green → Refactor workflow
3. **Automated Ticket Management**: GitHub Issues integrated with Kanban board
4. **Code Quality Enforcement**: Comprehensive linting with auto-fix on commit
5. **Best Practices Enforcement**: Opinionated rules ensure code quality
6. **Git Workflow**: Feature branches with PR approval process

## ✨ Code Quality Features

This project includes a comprehensive code quality system:

- **🐍 Python**: Ruff (linting + formatting)
- **📜 JavaScript/TypeScript**: ESLint with Airbnb style guide
- **🎨 CSS/SCSS**: Stylelint with industry standards
- **🪝 Pre-commit Hooks**: Auto-fix on every commit (max 3 attempts)
- **🧹 Pre-PR Cleanup**: Comprehensive quality check before Pull Requests
- **🔒 Security**: Bandit scanner for Python vulnerabilities
- **🧪 Test Verification**: Tests run after auto-fixes to ensure nothing breaks

**See [docs/LINTING.md](docs/LINTING.md) for complete linting guide.**

## 📋 Table of Contents

- [Code Quality Features](#code-quality-features)
- [Quick Start](#quick-start)
- [Development Workflow](#development-workflow)
- [Project Structure](#project-structure)
- [GitHub Integration](#github-integration)
- [Linting & Code Quality](#linting--code-quality)
- [Scripts Reference](#scripts-reference)
- [Cursor Rules](#cursor-rules)
- [Contributing](#contributing)

## 🚀 Quick Start

### Prerequisites

- Python 3.8+
- Git
- GitHub account with access to this repository
- GitHub Personal Access Token (see [Setup](#setup))

### Setup

1. **Clone the repository**

```bash
git clone https://github.com/eltanno/cursor_test.git
cd cursor_test
```

2. **Run the setup script (Recommended)**

```bash
./setup.sh
```

This script will:
- Create a Python virtual environment
- Upgrade pip
- Install all dependencies

**Or manually:**

```bash
# Create virtual environment
python3 -m venv venv

# Activate virtual environment
source .venv/bin/activate  # On Linux/Mac
# OR
venv\Scripts\activate     # On Windows

# Install dependencies
pip install -r requirements.txt
```

3. **Configure environment variables**

Copy `.env.example` to `.env` and add your GitHub token:

```bash
cp .env.example .env
```

Edit `.env` and add your token:

```env
GITHUB_API_KEY=ghp_your_token_here
GITHUB_OWNER=eltanno
GITHUB_REPO=cursor_test
GITHUB_PROJECT_NUMBER=1
```

4. **Create GitHub Personal Access Token**

- Go to: https://github.com/settings/tokens
- Click "Generate new token (classic)"
- Select scopes: `repo`, `workflow`, `admin:org`, `project`
- Copy token to `.env` file

5. **Activate virtual environment (if not already active)**

```bash
source .venv/bin/activate  # On Linux/Mac
# OR
venv\Scripts\activate     # On Windows
```

6. **Verify setup**

```bash
python -c "from scripts.utils.github_api import GitHubAPI; api = GitHubAPI(); print('✓ Setup successful!')"
```

> **Note**: Always activate the virtual environment before working on the project or running scripts.

## 🔄 Development Workflow

### Overview

```
Plan → Create Tickets → Implement (TDD) → Review → Test → Done
```

### Detailed Workflow

#### 1. Planning Phase

When requesting a new feature, use planning keywords:

```
"Can you plan a user authentication system?"
```

The AI agent will:
- Create a planning document in `docs/planning/features/`
- Analyze best practices
- Identify reusable components
- **NOT write any code** until you approve

Planning document includes:
- Overview & business value
- Requirements (functional & non-functional)
- Architecture design
- Implementation tasks
- Test strategy
- Dependencies & risks

#### 2. Approval & Ticket Creation

Once you approve the plan:

```
"Proceed with implementation"
```

The agent will:
- Break plan into discrete tasks
- Create GitHub Issues for each task
- Add all issues to **Backlog** column
- Wait for you to move tickets to **Ready**

Or manually create tickets:

```bash
python scripts/github/create_tickets.py docs/planning/features/FEAT-001-example.md
```

#### 3. Implementation Phase

**Your action**: Move ticket from Backlog to **Ready** column

The agent will:
1. Check **Ready** column for work
2. Verify dependencies are met
3. Move ticket to **In Progress**
4. Create feature branch
5. Follow TDD workflow:
   - Write failing tests (RED)
   - Implement minimal code (GREEN)
   - Refactor (REFACTOR)
6. Run all tests (must pass 100%)
7. Commit to feature branch
8. Create PR linked to issue
9. Move ticket to **In Review**
10. Wait for your approval

#### 4. Review Phase

**Your action**: Review the PR

- Review code changes
- Check test coverage
- Approve or request changes
- Move ticket to **In Testing** when approved

#### 5. Testing Phase (PRIORITY)

The agent will:
1. Check **In Testing** column (highest priority)
2. Pull latest changes
3. Run comprehensive test suite
4. **If tests pass**:
   - Move ticket to **Done**
   - Close issue
   - Add test results comment
5. **If tests fail**:
   - Move ticket to **Test Failed**
   - Add detailed failure report
   - Wait for your review

#### 6. Test Failure Handling

**Your action**: Review **Test Failed** tickets

- Review failure details
- Decide on fix approach
- Move back to **Ready** when ready

## 📁 Project Structure

```
cursor_test/
├── .cursorrules              # AI agent behavior rules
├── .env                      # Environment variables (gitignored)
├── .env.example             # Environment template
├── .gitignore               # Git ignore rules
├── requirements.txt         # Python dependencies
├── README.md               # This file
│
├── docs/                   # All documentation
│   └── planning/          # Planning documents
│       ├── features/      # Feature planning docs
│       │   └── template.md
│       ├── architecture/  # Architecture Decision Records
│       ├── designs/       # UI/UX mockups, diagrams
│       │   ├── ui-mockups/
│       │   └── data-models/
│       └── workflows/     # Process documentation
│           └── kanban-workflow.md
│
├── scripts/               # Automation scripts
│   ├── github/           # GitHub integration scripts
│   │   ├── create_tickets.py
│   │   ├── update_ticket.py
│   │   ├── check_dependencies.py
│   │   └── post_test_results.py
│   └── utils/            # Utility modules
│       └── github_api.py
│
├── src/                  # Source code (your application)
│   ├── core/            # Core business logic
│   ├── services/        # External service integrations
│   ├── models/          # Data models
│   ├── utils/           # Utility functions
│   ├── api/             # API endpoints/routes
│   └── config/          # Configuration
│
└── tests/               # All tests
    ├── unit/           # Unit tests
    ├── integration/    # Integration tests
    └── e2e/           # End-to-end tests
```

## 🔗 GitHub Integration

### Kanban Board Columns

| Column | Purpose | Who Manages |
|--------|---------|-------------|
| **Backlog** | New tickets from approved plans | Agent creates |
| **Ready** | Work ready to start | User moves here |
| **In Progress** | Active development | Agent manages |
| **In Review** | PR created, awaiting review | Agent moves, User reviews |
| **In Testing** | Comprehensive testing | Agent tests |
| **Test Failed** | Tests failed, needs fixes | Agent reports, User triages |
| **Done** | Completed & verified | Agent completes |

### Work Prioritization

Agents prioritize in this order:

1. **HIGHEST**: Tickets in **In Testing** column
2. **SECOND**: Tickets in **Ready** column (respecting dependencies)
3. **Labels**: `priority:high` > `priority:medium` > `priority:low`

### Ticket Labels

- `feature` - New functionality
- `bugfix` - Bug fixes
- `testing` - Test-specific work
- `documentation` - Documentation updates
- `refactor` - Code improvements
- `blocked` - Cannot proceed (dependency issue)

---

## 🎯 Linting & Code Quality

This project enforces strict code quality through automated linting and formatting.

### Linters Configured

| Language | Tool | Config File | Auto-fix |
|----------|------|-------------|----------|
| Python | Ruff | `ruff.toml` | ✅ Yes |
| JavaScript/TypeScript | ESLint | `.eslintrc.js` | ✅ Yes |
| CSS/SCSS | Stylelint | `.stylelintrc.json` | ✅ Yes |

### Automated Workflows

**1. Pre-commit Hooks (Automatic)**
- Run on every `git commit`
- Auto-fix issues (up to 3 attempts)
- Block commit if tests fail or unfixable errors
- Configuration: `.pre-commit-config.yaml`

**2. Pre-PR Quality Check (Manual)**
```bash
python scripts/quality/pre_pr_check.py
```
- Detects unused code (Vulture)
- Fixes all linting issues
- Runs full test suite
- Generates summary report

### Quick Commands

**Check issues:**
```bash
# Python
ruff check .

# JavaScript/TypeScript
npx eslint .

# CSS/SCSS
npx stylelint "**/*.{css,scss}"
```

**Auto-fix issues:**
```bash
# Python
ruff check . --fix
ruff format .

# JavaScript/TypeScript
npx eslint . --fix

# CSS/SCSS
npx stylelint "**/*.{css,scss}" --fix
```

**Run all hooks manually:**
```bash
pre-commit run --all-files
```

### Documentation

For complete linting guide, see **[docs/LINTING.md](docs/LINTING.md)**

Topics covered:
- Tool configurations
- Pre-commit hook behavior
- Troubleshooting blocked commits
- Code quality standards
- Best practices enforced

---
- `priority:high` / `priority:medium` / `priority:low`

## 🛠️ Scripts Reference

### Create Tickets from Planning Document

```bash
python scripts/github/create_tickets.py docs/planning/features/FEAT-001-example.md
```

Creates GitHub Issues from an approved planning document and adds them to Backlog.

### Update Ticket Status

```bash
python scripts/github/update_ticket.py <issue-number> "<column-name>" "[comment]"
```

Examples:
```bash
python scripts/github/update_ticket.py 123 "In Progress" "Starting work"
python scripts/github/update_ticket.py 456 "Done" "All tests passing"
```

### Check Dependencies

```bash
python scripts/github/check_dependencies.py <issue-number>
```

Verifies all dependency issues are closed before starting work.

Returns:
- Exit code 0: Dependencies met
- Exit code 1: Unmet dependencies

### Post Test Results

```bash
python scripts/github/post_test_results.py <issue-number> <pass|fail> [test-output-file]
```

Examples:
```bash
python scripts/github/post_test_results.py 123 pass test_results.txt
python scripts/github/post_test_results.py 456 fail test_results.txt
```

Posts test results and moves ticket to Done (pass) or Test Failed (fail).

## 📜 Cursor Rules

This project uses `.cursorrules` to guide AI agent behavior. Key principles:

### Planning Keywords (No Code Written)

When you use these keywords, agents will **only create plans**:
- "plan"
- "design"
- "architect"
- "outline"
- "propose"

### Implementation Keywords (Write Code)

These keywords trigger implementation:
- "implement"
- "proceed"
- "go ahead"
- "create"
- "build"

### Core Principles

1. **Planning First**: All features start with documented plans
2. **Best Practices Analysis**: Plans evaluate if request follows best practices
3. **Reusability Check**: Plans identify existing code to reuse
4. **TDD Always**: Red → Green → Refactor
5. **Test Before Commit**: 100% of tests must pass
6. **Feature Branches**: Never commit to main
7. **PR Approval**: Never merge without user approval
8. **GitHub Integration**: Automated ticket management

### Agent Guardrails

**Agents WILL:**
- ✅ Create comprehensive planning documents
- ✅ Evaluate best practices and suggest alternatives
- ✅ Look for reusable code
- ✅ Work in feature branches
- ✅ Write tests before implementation
- ✅ Run all tests before committing
- ✅ Create PRs and wait for approval
- ✅ Prioritize In Testing column
- ✅ Document test failures thoroughly

**Agents WON'T:**
- ❌ Write code during planning phase
- ❌ Commit directly to main/master
- ❌ Commit with failing tests
- ❌ Merge PRs without approval
- ❌ Ignore best practices without discussion
- ❌ Duplicate code unnecessarily
- ❌ Start work with unmet dependencies

## 🧪 Testing

### Running Tests

```bash
# Run all tests
pytest

# Run with coverage
pytest --cov=src --cov-report=html

# Run specific test file
pytest tests/unit/test_example.py

# Run with verbose output
pytest -v
```

### Test Structure

```
tests/
├── unit/           # Fast, isolated tests
├── integration/    # Tests with databases, APIs
└── e2e/           # Full user flow tests
```

### Test Requirements

- **Minimum 90% code coverage**
- All happy paths covered
- All edge cases covered
- All error conditions covered
- Clear, descriptive test names

### Test Naming Convention

```python
def test_<function>_<scenario>_<expected_result>():
    """Test description following Given-When-Then pattern."""
    # Given: Setup
    # When: Action
    # Then: Assert
```

## 🎨 Code Style

### Python

- **PEP 8** compliant
- **Black** formatter (88 char line length)
- **Type hints** on all function signatures
- **Docstrings** (Google style) on all public functions
- **f-strings** for string formatting

### Git Commits

Follow conventional commits:

```
<type>(<scope>): <description>

[optional body]

[optional footer]
```

Types:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation
- `test`: Tests
- `refactor`: Code refactoring
- `chore`: Maintenance

Examples:
```
feat(auth): add JWT token generation
fix(api): handle null user in endpoint
docs(readme): update installation steps
test(user): add edge case tests
```

## 🤝 Contributing

### For Learning & Practice

This is a learning project for understanding Cursor AI agents. Feel free to:

1. Fork the repository
2. Experiment with the workflow
3. Modify `.cursorrules` to suit your preferences
4. Share your learnings!

### Workflow for Contributors

1. Request a feature using planning keywords
2. Review and approve the generated plan
3. Let the agent create tickets
4. Move tickets to Ready when you want them implemented
5. Review PRs and move to In Testing
6. Agent runs tests and moves to Done or Test Failed

## 📚 Additional Resources

- [Cursor Documentation](https://cursor.sh/docs)
- [GitHub Projects API](https://docs.github.com/en/issues/planning-and-tracking-with-projects)
- [GitHub REST API](https://docs.github.com/en/rest)
- [Conventional Commits](https://www.conventionalcommits.org/)
- [Test-Driven Development](https://testdriven.io/)

## 📝 License

This is a learning project. Feel free to use and modify as needed.

## 🙏 Acknowledgments

Created to learn and demonstrate:
- Cursor AI agent capabilities
- Automated development workflows
- GitHub API integration
- Test-driven development
- Planning-first approach

---

**Project URL**: https://github.com/eltanno/cursor_test
**Kanban Board**: https://github.com/users/eltanno/projects/1
**Last Updated**: 2025-12-25
