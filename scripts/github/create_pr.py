#!/usr/bin/env python3
"""
Create a Pull Request from current branch to main.

Usage:
    python create_pr.py <title> <body> [base_branch]

Example:
    python create_pr.py "feat: add feature" "Description here" main
"""

import sys
import os
from pathlib import Path

# Add parent directory to path for imports
sys.path.insert(0, str(Path(__file__).parent.parent.parent))

from scripts.utils.github_api import GitHubAPI, GitHubAPIError
import subprocess


def get_current_branch() -> str:
    """Get the current git branch name."""
    result = subprocess.run(
        ['git', 'rev-parse', '--abbrev-ref', 'HEAD'],
        capture_output=True,
        text=True,
        check=True
    )
    return result.stdout.strip()


def create_pull_request(
    title: str,
    body: str,
    base: str = 'main'
) -> dict:
    """Create a pull request.
    
    Args:
        title: PR title
        body: PR description
        base: Base branch to merge into (default: main)
        
    Returns:
        Created PR data
    """
    api = GitHubAPI()
    
    # Get current branch
    head = get_current_branch()
    
    if head == base:
        raise ValueError(f"Cannot create PR: currently on base branch '{base}'")
    
    print(f"\n📝 Creating Pull Request")
    print(f"   From: {head}")
    print(f"   To: {base}")
    print(f"   Title: {title}")
    
    # Create PR using REST API
    endpoint = f'/repos/{api.owner}/{api.repo}/pulls'
    data = {
        'title': title,
        'body': body,
        'head': head,
        'base': base
    }
    
    pr = api._make_request('POST', endpoint, data)
    
    print(f"\n✅ Pull Request created successfully!")
    print(f"   📋 PR #{pr['number']}: {pr['title']}")
    print(f"   🔗 {pr['html_url']}")
    print(f"\n⏳ Waiting for user review and approval...")
    
    return pr


def main():
    """Main entry point."""
    if len(sys.argv) < 3:
        print("Usage: python create_pr.py <title> <body> [base_branch]")
        print("\nExample:")
        print('  python create_pr.py "feat: add feature" "Description" main')
        sys.exit(1)
    
    title = sys.argv[1]
    body = sys.argv[2]
    base = sys.argv[3] if len(sys.argv) > 3 else 'main'
    
    try:
        create_pull_request(title, body, base)
    except GitHubAPIError as e:
        print(f"❌ GitHub API Error: {e}")
        sys.exit(1)
    except Exception as e:
        print(f"❌ Error: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)


if __name__ == '__main__':
    main()

