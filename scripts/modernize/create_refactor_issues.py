#!/usr/bin/env python3
"""
create_refactor_issues.py - Create GitHub Issues from refactor plan

Parses docs/modernization/refactor-plan.md and creates GitHub Issues for each task.

Usage:
    python scripts/modernize/create_refactor_issues.py [refactor_plan_file]

Requirements:
    - .env file with GITHUB_API_KEY, GITHUB_OWNER, GITHUB_REPO, GITHUB_PROJECT_NUMBER
    - Refactor plan with tasks in specific format (see FEAT-003 for template)
"""

import argparse
import re
import sys
from pathlib import Path


# Add scripts to path for imports
sys.path.insert(0, str(Path(__file__).parent.parent))

try:
    from utils.github_api import GitHubAPI, GitHubAPIError
except ImportError:
    print('❌ Error: Could not import GitHub API utilities')
    print('   Make sure scripts/utils/github_api.py exists')
    sys.exit(1)


def parse_refactor_plan(plan_file: Path) -> list[dict]:
    """Parse refactor plan markdown and extract tasks."""
    print(f'📖 Parsing refactor plan: {plan_file}')

    with open(plan_file, encoding='utf-8') as f:
        content = f.read()

    tasks = []
    # Pattern to match tasks: #### TASK-NNN: Title
    task_pattern = r'####\s+TASK-(\d+):\s+(.+?)(?=####|$)'

    for match in re.finditer(task_pattern, content, re.DOTALL):
        task_id = match.group(1)
        task_block = match.group(2)

        # Extract title (first line)
        lines = task_block.strip().split('\n')
        title = lines[0].strip()

        # Extract priority
        priority_match = re.search(r'\*\*Priority\*\*:\s+(\w+)', task_block)
        priority = priority_match.group(1).lower() if priority_match else 'medium'

        # Extract risk
        risk_match = re.search(r'\*\*Risk\*\*:\s+(\w+)', task_block)
        risk = risk_match.group(1).lower() if risk_match else 'medium'

        # Extract effort
        effort_match = re.search(r'\*\*Effort\*\*:\s+(.+)', task_block)
        effort = effort_match.group(1).strip() if effort_match else 'TBD'

        # Extract what section
        what_match = re.search(r'\*\*What\*\*:\s*\n((?:- .+\n?)+)', task_block)
        what = what_match.group(1).strip() if what_match else ''

        # Extract why section
        why_match = re.search(r'\*\*Why\*\*:\s*\n((?:- .+\n?)+)', task_block)
        why = why_match.group(1).strip() if why_match else ''

        # Extract acceptance criteria
        criteria_match = re.search(
            r'\*\*Acceptance Criteria\*\*:\s*\n((?:- \[.\] .+\n?)+)',
            task_block,
        )
        criteria = criteria_match.group(1).strip() if criteria_match else ''

        # Extract dependencies
        deps_match = re.search(r'\*\*Dependencies\*\*:\s+(.+)', task_block)
        dependencies = deps_match.group(1).strip() if deps_match else 'None'

        tasks.append(
            {
                'id': f'TASK-{task_id}',
                'title': title,
                'priority': priority,
                'risk': risk,
                'effort': effort,
                'what': what,
                'why': why,
                'criteria': criteria,
                'dependencies': dependencies,
            },
        )

    print(f'   Found {len(tasks)} tasks')
    return tasks


def create_issue_body(task: dict) -> str:
    """Create GitHub Issue body from task data."""
    return f"""**Task ID:** {task['id']}
**Priority:** {task['priority'].upper()}
**Risk:** {task['risk'].upper()}
**Effort:** {task['effort']}

## What

{task['what']}

## Why

{task['why']}

## Acceptance Criteria

{task['criteria']}

## Dependencies

{task['dependencies']}

---

**Part of legacy code modernization workflow.**

See: `docs/modernization/refactor-plan.md`
"""


def get_priority_label(priority: str) -> str:
    """Map priority to GitHub label."""
    mapping = {
        'urgent': 'priority:high',
        'high': 'priority:high',
        'medium': 'priority:medium',
        'low': 'priority:low',
    }
    return mapping.get(priority.lower(), 'priority:medium')


def main():
    """Main entry point."""
    parser = argparse.ArgumentParser(
        description='Create GitHub Issues from refactor plan',
    )
    parser.add_argument(
        'plan_file',
        nargs='?',
        default='docs/modernization/refactor-plan.md',
        help='Path to refactor plan file (default: docs/modernization/refactor-plan.md)',
    )
    args = parser.parse_args()

    plan_file = Path(args.plan_file)

    if not plan_file.exists():
        print(f'❌ Error: Refactor plan not found: {plan_file}')
        print()
        print('Create a refactor plan first:')
        print('1. Review: docs/modernization/assessment.md')
        print('2. Create: docs/modernization/refactor-plan.md')
        print('3. Use template from FEAT-003 planning document')
        return 1

    print('🚀 Creating GitHub Issues from Refactor Plan')
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━')
    print()

    # Parse refactor plan
    tasks = parse_refactor_plan(plan_file)

    if not tasks:
        print('⚠️  No tasks found in refactor plan')
        print('   Check that tasks follow the format:')
        print('   #### TASK-NNN: Title')
        return 1

    print()
    print('🔑 Initializing GitHub API...')

    try:
        api = GitHubAPI()
    except GitHubAPIError as e:
        print(f'❌ Error: {e}')
        print()
        print('Make sure .env file has:')
        print('- GITHUB_API_KEY')
        print('- GITHUB_OWNER')
        print('- GITHUB_REPO')
        print('- GITHUB_PROJECT_NUMBER')
        return 1

    print()
    print('📋 Creating GitHub Issues...')
    print()

    created_issues = []
    failed_issues = []

    for task in tasks:
        # Create issue title
        issue_title = f'[Modernization] {task["id"]}: {task["title"]}'

        # Create issue body
        issue_body = create_issue_body(task)

        # Determine labels
        labels = [
            'modernization',
            get_priority_label(task['priority']),
        ]

        # Add risk label if high
        if task['risk'].lower() == 'high':
            labels.append('high-risk')

        try:
            # Create issue using helper method (auto-adds to project)
            issue = api.create_issue(
                title=issue_title,
                body=issue_body,
                labels=labels,
                add_to_project=True,
                column_name='Backlog',
            )

            print(f'✅ Created Issue #{issue["number"]}: {task["id"]}')
            created_issues.append((task['id'], issue['number']))

        except GitHubAPIError as e:
            print(f'❌ Failed to create issue for {task["id"]}: {e}')
            failed_issues.append(task['id'])

    print()
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━')

    if created_issues:
        print(f'🎉 Successfully created {len(created_issues)} issues:')
        print()
        for task_id, issue_num in created_issues:
            print(f'   {task_id} → Issue #{issue_num}')

    if failed_issues:
        print()
        print(f'❌ Failed to create {len(failed_issues)} issues:')
        for task_id in failed_issues:
            print(f'   {task_id}')

    print()
    print('📋 Next steps:')
    print('1. Review issues on GitHub')
    print('2. Move issues from Backlog to Ready as you prioritize them')
    print('3. Agents will work on tickets in Ready column')
    print('4. Follow the modernization workflow from FEAT-003')
    print()

    return 0 if not failed_issues else 1


if __name__ == '__main__':
    sys.exit(main())
