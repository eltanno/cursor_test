# Code Linting & Quality Guide

Complete guide to code quality tools and workflows in this project.

## Overview

This project enforces strict code quality through automated linting:
- **Pre-commit hooks**: Auto-fix on every commit
- **Pre-PR checks**: Comprehensive cleanup before Pull Requests
- **Continuous enforcement**: Quality maintained automatically

---

## Linting Tools

### Python: Ruff

**Configuration:** `ruff.toml`

**What it does:**
- Lints Python code (40+ rule sets)
- Formats code (replaces Black)
- Sorts imports automatically
- Checks type hints
- Detects security issues
- Finds unused code

**Usage:**
```bash
# Check issues
ruff check .

# Auto-fix issues
ruff check . --fix

# Format code
ruff format .

# With unsafe fixes (more aggressive)
ruff check . --fix --unsafe-fixes
```

**Configuration highlights:**
- Line length: 88 characters
- Quote style: Single quotes
- Line endings: LF (Unix-style)
- Docstring style: Google

### JavaScript/TypeScript: ESLint

**Configuration:** `.eslintrc.js`

**What it does:**
- Lints JS/TS code
- Enforces Airbnb style guide
- Removes unused imports/variables
- Organizes imports automatically
- Checks code complexity

**Usage:**
```bash
# Ensure Node 20 is active
source ~/.nvm/nvm.sh && nvm use 20

# Check issues
npx eslint .

# Auto-fix issues
npx eslint . --fix

# Check specific file
npx eslint path/to/file.js --fix
```

**Configuration highlights:**
- Style: Airbnb base
- Max line length: 100 characters
- Unused code: Automatically detected
- Import ordering: Enforced

### CSS/SCSS: Stylelint

**Configuration:** `.stylelintrc.json`

**What it does:**
- Lints CSS/SCSS code
- Enforces consistent formatting
- Detects bad practices
- Optimizes properties

**Usage:**
```bash
# Ensure Node 20 is active
source ~/.nvm/nvm.sh && nvm use 20

# Check issues
npx stylelint "**/*.{css,scss}"

# Auto-fix issues
npx stylelint "**/*.{css,scss}" --fix
```

**Configuration highlights:**
- Indentation: 2 spaces
- Quotes: Single quotes
- No ID selectors
- Max nesting: 4 levels

---

## Automated Workflows

### Pre-commit Hooks (Automatic)

**Installation:**
```bash
source venv/bin/activate
pre-commit install
```

**What happens on commit:**
1. Hooks run on staged files
2. Auto-fixes applied automatically
3. Files re-staged if modified
4. Hooks re-run to verify (max 3 attempts)
5. Tests run after all fixes
6. Commit succeeds or blocks with errors

**Hooks include:**
- Ruff (Python linting + formatting)
- ESLint (JS/TS linting)
- Stylelint (CSS/SCSS linting)
- Trailing whitespace removal
- EOF normalization
- Line ending enforcement (LF)
- YAML/JSON/TOML syntax validation
- Large file detection
- Merge conflict detection
- Bandit security scan

**Bypass (use only when necessary):**
```bash
# Skip specific hooks
SKIP=ruff,eslint git commit -m "message"

# Skip all hooks (NOT RECOMMENDED)
git commit --no-verify -m "message"
```

### Pre-PR Quality Check (Manual)

**When to run:**
- Before creating any Pull Request
- After major refactoring
- Before merging feature branches

**Command:**
```bash
source venv/bin/activate
python scripts/quality/pre_pr_check.py
```

**What it does:**
1. Detects unused Python code (Vulture)
2. Auto-fixes all Python issues (Ruff with unsafe fixes)
3. Auto-fixes all JS/TS issues (ESLint)
4. Auto-fixes all CSS/SCSS issues (Stylelint)
5. Runs full test suite
6. Generates summary report

**Exit codes:**
- `0`: All passed or warnings only
- `1`: Tests failed after fixes

---

## Troubleshooting

### Commit Blocked by Linter

**Problem:** `❌ Commit blocked. Please fix the issues above.`

**Solution:**
1. Read the error messages carefully
2. Fix issues that can't be auto-fixed
3. Stage files: `git add .`
4. Try commit again
5. If still blocked after 3 attempts, fix manually

### Tests Fail After Auto-fix

**Problem:** `❌ Tests failed after linter fixes!`

**Solution:**
1. Review what linters changed: `git diff`
2. Check if logic was accidentally broken
3. Fix broken tests or revert problematic changes
4. Run tests manually: `pytest tests/` or `npm test`
5. Commit again once tests pass

### Ruff Finds Too Many Issues

**Problem:** Hundreds of Ruff errors

**Solution:**
```bash
# Run cleanup pass
source venv/bin/activate
ruff check . --fix --unsafe-fixes
ruff format .

# Verify and stage
git add .
git commit -m "chore: ruff cleanup"
```

### ESLint/Stylelint Not Running

**Problem:** Hooks skip JS/CSS files

**Solution:**
```bash
# Ensure Node 20 is active
source ~/.nvm/nvm.sh
nvm use 20

# Install dependencies
npm install

# Try manual run
npx eslint . --fix
npx stylelint "**/*.{css,scss}" --fix
```

---

## Code Quality Standards

### Non-Negotiable Requirements

All code must:
- ✅ Pass all linter checks
- ✅ Have no unused imports/variables/functions
- ✅ Follow consistent formatting
- ✅ Use proper naming conventions
- ✅ Have no security vulnerabilities
- ✅ Pass all tests
- ✅ Use LF line endings
- ✅ Have no trailing whitespace

### Best Practices Enforced

**Python:**
- Type hints on function signatures
- Google-style docstrings
- Imports sorted (stdlib → external → internal)
- Single quotes
- 88-character line length

**JavaScript/TypeScript:**
- `const`/`let` instead of `var`
- Arrow functions for callbacks
- Destructuring where appropriate
- No unused variables/imports
- Organized imports

**CSS/SCSS:**
- No ID selectors (use classes)
- Max 4 nesting levels
- Consistent spacing and formatting
- Shorthand properties
- Lowercase hex colors

---

## Configuration Files

| File | Purpose |
|------|---------|
| `ruff.toml` | Ruff configuration |
| `.eslintrc.js` | ESLint configuration |
| `.stylelintrc.json` | Stylelint configuration |
| `.pre-commit-config.yaml` | Pre-commit hooks |
| `pyproject.toml` | Bandit security config |
| `package.json` | Node.js dependencies |

---

## Quick Reference

### Check All Code
```bash
# Python
source venv/bin/activate
ruff check .

# JavaScript/TypeScript
source ~/.nvm/nvm.sh && nvm use 20
npx eslint .

# CSS/SCSS
npx stylelint "**/*.{css,scss}"
```

### Fix All Issues
```bash
# Python
ruff check . --fix --unsafe-fixes
ruff format .

# JavaScript/TypeScript
npx eslint . --fix

# CSS/SCSS
npx stylelint "**/*.{css,scss}" --fix
```

### Run All Hooks Manually
```bash
source venv/bin/activate
pre-commit run --all-files
```

---

## Getting Help

- **Ruff**: https://docs.astral.sh/ruff/
- **ESLint**: https://eslint.org/docs/
- **Stylelint**: https://stylelint.io/
- **Pre-commit**: https://pre-commit.com/

For project-specific questions, see `.cursorrules`.
