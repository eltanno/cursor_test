# Modernization Setup - Improved Workflow

## Issue Identified

The `setup.sh` script for modernization was incomplete - it was missing several critical file copies:
- `ruff.toml` (Python linter config)
- `pyproject.toml` (Python project config)
- `.eslintrc.js` (JS/TS linter config)
- `.stylelintrc.json` (CSS/SCSS linter config)
- `package.json` (Node.js dependencies)
- `docs/templates/` (Handoff templates)

## Recommended Workflow (Simplified)

For modernizing legacy projects, use `scripts/modernize/import_template.sh` which is purpose-built for this:

```bash
# From cursor_scaffold directory:
./scripts/modernize/import_template.sh /path/to/legacy-project
```

This script:
- Analyzes the legacy project
- Copies ALL necessary scaffold files
- Generates proper handoff document
- Provides clear next steps

## Alternative: Manual Setup (What Went Wrong)

The issue we encountered was:
1. Copying just `setup.sh` to the project
2. Running it from within the project
3. `$SCRIPT_DIR` pointed to project, not scaffold
4. Files couldn't be found to copy

**Solution:** Run setup FROM scaffold, not from project.

## Fixes Applied

1. ✅ Added `requirements.txt` with all Python dependencies
2. ✅ Fixed `GitHubAPI` to not require repo vars when creating repos
3. ✅ Updated `create_repo_and_project.py` to fetch owner from GitHub API
4. ⏳ Need to add missing file copies to `setup.sh` (OR recommend `import_template.sh` instead)

## Recommendation

**Option A: Fix setup.sh** (Complex, 864 lines, many edge cases)
**Option B: Document to use `import_template.sh` for modernization** (Simple, already works)

**Chosen:** Option B - Document proper usage of existing tools.
