#!/usr/bin/env python3
"""
assess_codebase.py - Analyze legacy codebase and generate assessment report

This script analyzes a legacy codebase to identify:
- Functionality inventory
- Architecture and structure
- Code quality metrics
- Test coverage gaps
- Technical debt
- Security issues
- Refactor opportunities

Usage:
    python scripts/modernize/assess_codebase.py [target_directory]

Output:
    docs/modernization/assessment.md
"""

import argparse
import re
import subprocess
import sys
from datetime import datetime
from pathlib import Path


# Add scripts to path for imports
sys.path.insert(0, str(Path(__file__).parent.parent))


def find_python_files(root_dir: Path) -> list[Path]:
    """Find all Python files, excluding venv and hidden directories."""
    python_files = []
    for path in root_dir.rglob('*.py'):
        # Skip virtual environments and hidden directories
        if any(
            part.startswith('.') or part in ['venv', '.venv', 'node_modules']
            for part in path.parts
        ):
            continue
        python_files.append(path)
    return python_files


def find_js_ts_files(root_dir: Path) -> list[Path]:
    """Find all JavaScript/TypeScript files, excluding node_modules."""
    js_files = []
    for pattern in ['*.js', '*.jsx', '*.ts', '*.tsx']:
        for path in root_dir.rglob(pattern):
            if any(
                part.startswith('.') or part == 'node_modules' for part in path.parts
            ):
                continue
            js_files.append(path)
    return js_files


def count_lines(file_path: Path) -> int:
    """Count lines in a file."""
    try:
        with open(file_path, encoding='utf-8') as f:
            return sum(1 for _ in f)
    except Exception:
        return 0


def detect_complexity(file_path: Path) -> list[tuple[str, int]]:
    """Detect functions/methods with high cyclomatic complexity."""
    # Simple heuristic: count decision points (if, for, while, and, or)
    high_complexity = []

    try:
        with open(file_path, encoding='utf-8') as f:
            content = f.read()

        # Find function definitions
        func_pattern = r'def\s+(\w+)\s*\('
        functions = re.finditer(func_pattern, content)

        for func in functions:
            func_name = func.group(1)
            # Count decision points in function body (rough estimate)
            # This is a simple heuristic, not actual cyclomatic complexity
            keywords = ['if', 'for', 'while', 'and', 'or', 'elif', 'except']
            complexity = sum(
                content[func.start() :].split('def', 1)[0].count(keyword)
                for keyword in keywords
            )

            if complexity > 10:
                high_complexity.append((func_name, complexity))

    except Exception:
        pass

    return high_complexity


def find_todos(file_path: Path) -> list[str]:
    """Find TODO/FIXME comments in file."""
    todos = []
    try:
        with open(file_path, encoding='utf-8') as f:
            for line_num, line in enumerate(f, 1):
                if 'TODO' in line or 'FIXME' in line:
                    todos.append(f'{file_path.name}:{line_num}: {line.strip()}')
    except Exception:
        pass
    return todos


def run_command(cmd: list[str], cwd: Path) -> tuple[int, str]:
    """Run a command and return exit code and output."""
    try:
        result = subprocess.run(
            cmd,
            cwd=cwd,
            capture_output=True,
            text=True,
            timeout=30,
        )
        return result.returncode, result.stdout + result.stderr
    except Exception as e:
        return 1, str(e)


def analyze_codebase(root_dir: Path) -> dict:
    """Analyze the codebase and return assessment data."""
    print('🔍 Analyzing codebase...')

    # Initialize results
    results = {
        'total_files': 0,
        'total_lines': 0,
        'languages': {},
        'large_files': [],
        'complex_functions': [],
        'todos': [],
        'test_files': 0,
        'framework': 'Unknown',
    }

    # Find Python files
    python_files = find_python_files(root_dir)
    if python_files:
        print(f'   Found {len(python_files)} Python files')
        results['languages']['Python'] = len(python_files)
        results['total_files'] += len(python_files)

        for py_file in python_files:
            lines = count_lines(py_file)
            results['total_lines'] += lines

            # Track large files
            if lines > 500:
                results['large_files'].append(
                    (str(py_file.relative_to(root_dir)), lines),
                )

            # Find complex functions
            complex_funcs = detect_complexity(py_file)
            for func_name, complexity in complex_funcs:
                results['complex_functions'].append(
                    (str(py_file.relative_to(root_dir)), func_name, complexity),
                )

            # Find TODOs
            todos = find_todos(py_file)
            results['todos'].extend(todos)

    # Find JS/TS files
    js_files = find_js_ts_files(root_dir)
    if js_files:
        print(f'   Found {len(js_files)} JavaScript/TypeScript files')
        results['languages']['JavaScript/TypeScript'] = len(js_files)
        results['total_files'] += len(js_files)

        for js_file in js_files:
            lines = count_lines(js_file)
            results['total_lines'] += lines

            if lines > 500:
                results['large_files'].append(
                    (str(js_file.relative_to(root_dir)), lines),
                )

            todos = find_todos(js_file)
            results['todos'].extend(todos)

    # Detect framework
    if (root_dir / 'manage.py').exists():
        results['framework'] = 'Django'
    elif (root_dir / 'app.py').exists() or (root_dir / 'wsgi.py').exists():
        results['framework'] = 'Flask'
    elif (root_dir / 'package.json').exists():
        try:
            import json

            with open(root_dir / 'package.json') as f:
                pkg = json.load(f)
                deps = {**pkg.get('dependencies', {}), **pkg.get('devDependencies', {})}
                if 'react' in deps:
                    results['framework'] = 'React'
                elif 'express' in deps:
                    results['framework'] = 'Express'
        except Exception:
            pass

    # Count test files
    test_patterns = [
        'test_*.py',
        '*_test.py',
        '*.test.js',
        '*.test.ts',
        '*.spec.js',
        '*.spec.ts',
    ]
    for pattern in test_patterns:
        results['test_files'] += len(list(root_dir.rglob(pattern)))

    print(f'   Total files: {results["total_files"]}')
    print(f'   Total lines: {results["total_lines"]:,}')
    print(f'   Framework: {results["framework"]}')
    print(f'   Test files: {results["test_files"]}')

    return results


def generate_assessment_report(root_dir: Path, results: dict) -> str:
    """Generate markdown assessment report."""
    report = f"""# Legacy Codebase Assessment

Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}

## Executive Summary

- **Total Files**: {results['total_files']}
- **Total Lines**: {results['total_lines']:,}
- **Languages**: {', '.join(f'{k} ({v} files)' for k, v in results['languages'].items())}
- **Framework**: {results['framework']}
- **Test Files**: {results['test_files']}
- **Large Files (>500 lines)**: {len(results['large_files'])}
- **Complex Functions (complexity >10)**: {len(results['complex_functions'])}
- **TODO/FIXME Comments**: {len(results['todos'])}

## Functionality Inventory

### Core Features

*Manual review needed. Key areas to document:*
- Main user-facing features
- Business logic components
- Data models and relationships
- External integrations

### Entry Points

"""

    # Detect entry points based on framework
    if results['framework'] == 'Django':
        report += """*Django project:*
- `manage.py runserver` - Development server
- `manage.py` - Management commands
- Check `urls.py` for API endpoints
- Check `admin.py` for admin interface

"""
    elif results['framework'] == 'Flask':
        report += """*Flask project:*
- Look for `app.py` or `wsgi.py`
- Check route decorators (@app.route)

"""
    elif results['framework'] == 'React':
        report += """*React project:*
- `npm start` - Development server
- Check `src/App.js` or `src/App.tsx`
- Review `package.json` scripts

"""

    report += """## Architecture

### Current Structure

```
"""

    # Show directory structure (top level only)
    for item in sorted(root_dir.iterdir()):
        if item.is_dir() and not item.name.startswith('.'):
            report += f'{item.name}/\n'

    report += """```

### Issues

"""

    # Report large files
    if results['large_files']:
        report += '**Large Files (>500 lines):**\n\n'
        for file_path, lines in sorted(
            results['large_files'],
            key=lambda x: x[1],
            reverse=True,
        )[:10]:
            report += f'- ❌ `{file_path}` ({lines:,} lines) - Consider splitting\n'
        report += '\n'

    # Report complex functions
    if results['complex_functions']:
        report += '**Complex Functions (>10 decision points):**\n\n'
        for file_path, func_name, complexity in sorted(
            results['complex_functions'],
            key=lambda x: x[2],
            reverse=True,
        )[:10]:
            report += f'- ⚠️  `{file_path}::{func_name}` (complexity: {complexity}) - REFACTOR\n'
        report += '\n'

    report += """### Dependencies

*Manual review needed:*
- Check `requirements.txt` or `package.json`
- Run security audits: `pip-audit` or `npm audit`
- Check for outdated dependencies

"""

    report += """## Test Coverage

### Current State

"""

    if results['test_files'] == 0:
        report += '- ❌ **No test files found** - CRITICAL RISK\n'
        report += '- This is the highest priority for modernization\n'
    elif results['test_files'] < 10:
        report += (
            f'- ⚠️  **Only {results["test_files"]} test files found** - LOW COVERAGE\n'
        )
        report += '- Significant testing gaps likely exist\n'
    else:
        report += f'- ✅ {results["test_files"]} test files found\n'
        report += '- Coverage analysis needed (run `pytest --cov` or `npm test -- --coverage`)\n'

    report += """
### Gaps

**Critical paths needing characterization tests:**
1. Payment processing (if applicable)
2. User authentication
3. Data validation logic
4. External API integrations
5. Business rule implementations

**Action**: Begin with characterization tests for critical paths.

"""

    report += """## Code Quality

### Complexity

"""

    if results['complex_functions']:
        report += f'- Found {len(results["complex_functions"])} functions with high complexity\n'
        report += '- Top offenders listed above\n'
        report += (
            '- **Action**: Refactor complex functions using Extract Method pattern\n'
        )
    else:
        report += '- ✅ No obviously complex functions detected (basic heuristic)\n'

    report += """
### Technical Debt

"""

    if results['todos']:
        report += f'**TODO/FIXME Comments: {len(results["todos"])}**\n\n'
        if len(results['todos']) <= 20:
            for todo in results['todos'][:20]:
                report += f'- {todo}\n'
        else:
            for todo in results['todos'][:10]:
                report += f'- {todo}\n'
            report += f'\n... and {len(results["todos"]) - 10} more\n'
        report += '\n**Action**: Convert TODOs to GitHub Issues\n\n'
    else:
        report += '- ✅ No TODO/FIXME comments found\n\n'

    report += """### Linting

*Run linters to get detailed report:*
- Python: `ruff check .`
- JavaScript/TypeScript: `npx eslint .`

"""

    report += """## Risk Assessment

### High Risk Areas

"""

    # Identify high-risk areas
    high_risk = []
    if results['test_files'] == 0:
        high_risk.append('❌ **No tests** - Any change is risky')
    if results['complex_functions']:
        high_risk.append(
            f'❌ **{len(results["complex_functions"])} complex functions** - Hard to understand and modify',
        )
    if results['large_files']:
        high_risk.append(
            f'❌ **{len(results["large_files"])} large files** - Difficult to maintain',
        )

    if high_risk:
        for risk in high_risk:
            report += f'{risk}\n'
    else:
        report += '- ✅ No obvious high-risk areas detected\n'

    report += """
### Mitigation Strategy

1. **Write characterization tests first** - Create safety net
2. **Start with quick wins** - Fix linting, remove dead code
3. **Refactor incrementally** - Small, safe changes
4. **Monitor coverage** - Ensure tests increase with changes

"""

    report += """## Refactor Opportunities

### Quick Wins (Low Risk, High Value)

1. ✅ Run linters and fix auto-fixable issues
2. ✅ Add docstrings to public functions
3. ✅ Remove dead code (unused imports, functions)
4. ✅ Extract hardcoded values to configuration
5. ✅ Update dependencies (with tests)

### Strategic Refactors (High Value, Requires Planning)

"""

    if results['large_files']:
        report += '1. 📋 Split large files into smaller modules\n'
    if results['complex_functions']:
        report += '2. 📋 Refactor complex functions (Extract Method pattern)\n'
    report += """3. 📋 Extract business logic into service layer
4. 📋 Add comprehensive logging
5. 📋 Improve error handling

### Long-Term Improvements

1. 🔮 Add API layer (if web app)
2. 🔮 Implement caching strategy
3. 🔮 Add monitoring and alerting
4. 🔮 Containerize application (Docker)

"""

    report += """## Recommended Approach

### Phase 1: Stabilize (Weeks 1-2)

1. ✅ Import template scaffolding (DONE)
2. ✅ Run this assessment (DONE)
3. 📋 Write characterization tests for critical paths
4. 📋 Fix security vulnerabilities (if any)
5. 📋 Update critical dependencies

### Phase 2: Quick Wins (Weeks 3-4)

1. 📋 Run linters, fix auto-fixable issues
2. 📋 Remove dead code
3. 📋 Add missing docstrings
4. 📋 Extract configuration to environment variables
5. 📋 Improve test coverage to 50%

### Phase 3: Strategic Refactor (Months 2-3)

"""

    if results['large_files']:
        report += '1. 📋 Split large files into modules\n'
    if results['complex_functions']:
        report += '2. 📋 Refactor complex functions\n'
    report += """3. 📋 Extract service layer
4. 📋 Add API layer (if applicable)
5. 📋 Improve test coverage to 80%

### Phase 4: Long-Term (Months 4-6)

1. 📋 Consider architectural improvements
2. 📋 Add caching and optimization
3. 📋 Implement monitoring
4. 📋 Add CI/CD pipeline

"""

    report += """## Next Steps

1. **Review this assessment** with your team
2. **Create refactor plan**: `docs/modernization/refactor-plan.md`
   - Break phases into discrete tasks
   - Prioritize by risk and value
   - Define acceptance criteria
3. **Begin characterization tests**: `docs/modernization/characterization-tests.md`
   - Start with critical paths
   - Aim for 80%+ coverage before refactoring
4. **Create GitHub Issues**: `python scripts/modernize/create_refactor_issues.py`
5. **Start with quick wins** to build momentum

## Success Criteria

- [ ] Test coverage >80%
- [ ] All linting issues resolved
- [ ] No security vulnerabilities
- [ ] No functions with complexity >10
- [ ] No files >500 lines
- [ ] All critical paths have characterization tests
- [ ] Dependencies up-to-date
- [ ] Documentation complete

---

**Generated by:** `scripts/modernize/assess_codebase.py`

**See also:**
- Planning: `docs/planning/features/FEAT-003-legacy-code-modernization.md`
- Rules: `.cursorrules` (search for "Legacy Code Modernization")
"""

    return report


def main():
    """Main entry point."""
    parser = argparse.ArgumentParser(
        description='Analyze legacy codebase and generate assessment report',
    )
    parser.add_argument(
        'target_dir',
        nargs='?',
        default='.',
        help='Target directory to analyze (default: current directory)',
    )
    args = parser.parse_args()

    # Get absolute path
    root_dir = Path(args.target_dir).resolve()

    if not root_dir.exists():
        print(f'❌ Error: Directory does not exist: {root_dir}')
        return 1

    print(f'🔍 Analyzing legacy codebase: {root_dir}')
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━')
    print()

    # Analyze codebase
    results = analyze_codebase(root_dir)

    print()
    print('📝 Generating assessment report...')

    # Generate report
    report = generate_assessment_report(root_dir, results)

    # Write report
    output_dir = root_dir / 'docs' / 'modernization'
    output_dir.mkdir(parents=True, exist_ok=True)
    output_file = output_dir / 'assessment.md'

    with open(output_file, 'w', encoding='utf-8') as f:
        f.write(report)

    print(f'   ✅ Report saved to: {output_file.relative_to(root_dir)}')
    print()
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━')
    print('🎉 Assessment complete!')
    print()
    print('📋 Next steps:')
    print('1. Review assessment: docs/modernization/assessment.md')
    print('2. Create refactor plan: docs/modernization/refactor-plan.md')
    print('3. Begin characterization tests for critical paths')
    print('4. Create GitHub Issues: python scripts/modernize/create_refactor_issues.py')
    print()

    return 0


if __name__ == '__main__':
    sys.exit(main())
