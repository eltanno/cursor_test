# GitHub Kanban Development Workflow

## Overview

This document describes the automated GitHub Kanban workflow used in this project for managing development tasks from planning through completion.

## Workflow Diagram

```
┌─────────────────────────────────────────────────────────────────────┐
│                         PLANNING PHASE                              │
├─────────────────────────────────────────────────────────────────────┤
│ 1. User requests feature                                            │
│ 2. Agent creates plan in docs/planning/features/                    │
│ 3. User reviews and approves plan                                   │
│ 4. Agent breaks plan into discrete tasks                            │
│ 5. Agent creates GitHub Issues                                      │
│ 6. Agent adds all issues to BACKLOG                                 │
└─────────────────────────────────────────────────────────────────────┘
                                ↓
┌─────────────────────────────────────────────────────────────────────┐
│                    KANBAN BOARD WORKFLOW                            │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  ┌──────────┐      ┌───────┐      ┌─────────────┐                │
│  │ BACKLOG  │  →   │ READY │  →   │ IN PROGRESS │                │
│  └──────────┘      └───────┘      └─────────────┘                │
│      ↑                 ↓                  ↓                         │
│   Agent            User              Agent                         │
│   creates          moves             starts                        │
│   tickets          work              work                          │
│                                                                     │
│                                          ↓                          │
│                                  ┌───────────────┐                 │
│                                  │  IN REVIEW    │                 │
│                                  └───────────────┘                 │
│                                          ↓                          │
│                                      User reviews                   │
│                                          ↓                          │
│                                  ┌───────────────┐                 │
│                                  │  IN TESTING   │  (PRIORITY!)    │
│                                  └───────────────┘                 │
│                                     ↓        ↓                      │
│                              Pass /            \ Fail              │
│                                ↓                  ↓                 │
│                          ┌────────┐        ┌──────────────┐       │
│                          │  DONE  │        │ TEST FAILED  │       │
│                          └────────┘        └──────────────┘       │
│                                                    ↓                │
│                                              User reviews           │
│                                                    ↓                │
│                                            Back to READY           │
└─────────────────────────────────────────────────────────────────────┘
```

## Kanban Board Columns

### 1. Backlog
- **Purpose**: Holds all tickets created from approved planning documents
- **Who adds**: Agent automatically after plan approval
- **Who removes**: User (by moving to Ready)
- **Agent behavior**: Does NOT start work from here

### 2. Ready
- **Purpose**: Work that is ready to be started
- **Who adds**: User manually moves tickets from Backlog
- **Who removes**: Agent when starting work
- **Agent behavior**: Checks for available work (after In Testing)

### 3. In Progress
- **Purpose**: Work actively being developed
- **Who adds**: Agent when starting work
- **Who removes**: Agent when PR is created
- **Agent behavior**: 
  - Creates feature branch
  - Follows TDD workflow
  - Runs all tests before committing

### 4. In Review
- **Purpose**: PR created, waiting for user code review
- **Who adds**: Agent after creating PR
- **Who removes**: User after reviewing PR
- **User action**: Review code, approve/request changes, move to In Testing

### 5. In Testing
- **Purpose**: Code approved, needs comprehensive testing
- **Who adds**: User after approving PR
- **Who removes**: Agent after testing
- **Agent behavior**: 
  - **HIGHEST PRIORITY** - checks this column first
  - Runs full test suite
  - Moves to Done (pass) or Test Failed (fail)

### 6. Test Failed
- **Purpose**: Tests failed, needs investigation
- **Who adds**: Agent when tests fail
- **Who removes**: User after reviewing failures
- **Agent behavior**: Adds detailed failure report
- **User action**: Review failures, decide on fix approach, move back to Ready

### 7. Done
- **Purpose**: Completed and verified work
- **Who adds**: Agent after all tests pass
- **Who removes**: N/A (permanent archive)
- **Agent behavior**: Closes issue, adds test results

## Work Prioritization

Agents follow this priority order:

1. **HIGHEST**: Tickets in **In Testing** column
2. **SECOND**: Tickets in **Ready** column (respecting dependencies)
3. **Labels**: Within same column, prioritize:
   - `priority:high` first
   - `priority:medium` second
   - `priority:low` last

## Dependency Management

Before starting any ticket, agent must:

1. Check ticket description for listed dependencies
2. Verify all dependency tickets are in Done column
3. If dependencies not met:
   - Add comment to ticket explaining blocker
   - Add `blocked` label
   - Skip to next ticket

## Ticket Creation Standards

### Issue Title Format
```
[Type] Brief description of work
```

Examples:
- `[Feature] Add user authentication endpoint`
- `[Bugfix] Fix null pointer in login handler`
- `[Testing] Add integration tests for payment flow`

### Issue Description Template

```markdown
## Description
Clear description of what needs to be done.

## Acceptance Criteria
- [ ] Criterion 1
- [ ] Criterion 2
- [ ] Criterion 3

## Planning Document
Link to: `docs/planning/features/FEAT-XXX-name.md`

## Dependencies
- #issue_number: Description of dependency

## Implementation Notes
- Note 1
- Note 2

## Test Requirements
- Unit tests needed
- Integration tests needed
- Test scenarios to verify
```

### Required Labels

Every ticket must have at least:
- **Type label**: `feature`, `bugfix`, `testing`, `documentation`, or `refactor`
- **Priority label**: `priority:high`, `priority:medium`, or `priority:low`

## Agent Automated Actions

### When Creating Tickets
1. Parse approved planning document
2. Break into discrete, testable tasks
3. Create GitHub Issue for each task
4. Add proper labels
5. Link to planning document
6. Identify and document dependencies
7. Add all to Backlog column
8. Post summary comment in planning document

### When Starting Work (Ready → In Progress)
1. Check ticket dependencies
2. Post comment: "Starting work on this ticket"
3. Move ticket to In Progress
4. Create feature branch: `feature/issue-{number}-brief-description`
5. Update ticket with branch name

### When Creating PR (In Progress → In Review)
1. Ensure all tests pass
2. Create PR with template
3. Link PR to issue (using keywords: "Closes #123")
4. Move ticket to In Review
5. Add PR link to ticket
6. Post comment with PR number

### When Testing (In Testing → Done/Test Failed)
1. Pull latest changes
2. Checkout PR branch
3. Run full test suite
4. Generate test report
5. Post results to ticket
6. **If PASS**:
   - Move to Done
   - Close issue
   - Post success message
7. **If FAIL**:
   - Move to Test Failed
   - Post detailed failure report
   - Keep issue open

### Test Failure Report Format

```markdown
## Test Results: FAILED

### Summary
X tests passed, Y tests failed out of Z total

### Failed Tests

#### Test: test_name_1
**Error**: Error message
**Stack Trace**:
```
Stack trace here
```
**Steps to Reproduce**:
1. Step 1
2. Step 2

#### Test: test_name_2
...

### Environment
- Python version: X.Y.Z
- OS: Linux/Windows/Mac
- Branch: feature/xxx

### Suggested Fixes
- Suggestion 1
- Suggestion 2

### Next Steps
Moved to Test Failed column for user review.
```

## User Responsibilities

### Planning Phase
- Review and approve/reject planning documents
- Request changes if needed

### Backlog Management
- Review tickets in Backlog
- Move appropriate tickets to Ready when ready to work
- Consider dependencies and priority

### Code Review
- Review PRs in In Review column
- Approve or request changes
- Move approved PRs to In Testing

### Test Failure Triage
- Review tickets in Test Failed column
- Decide on fix approach
- Move back to Ready when fix approach decided

## GitHub API Integration

All ticket management uses GitHub's API with these endpoints:

- **Create Issue**: `POST /repos/{owner}/{repo}/issues`
- **Update Issue**: `PATCH /repos/{owner}/{repo}/issues/{number}`
- **Add to Project**: GraphQL `addProjectV2ItemById`
- **Move in Project**: GraphQL `updateProjectV2ItemFieldValue`
- **Add Comment**: `POST /repos/{owner}/{repo}/issues/{number}/comments`
- **Link PR**: Uses keywords in PR description ("Closes #123")

Configuration stored in `.env`:
```bash
GITHUB_API_KEY=ghp_...
GITHUB_OWNER=eltanno
GITHUB_REPO=cursor_test
GITHUB_PROJECT_NUMBER=1
```

## Best Practices

1. **Keep tickets small**: Each ticket should be completable in 1-2 hours
2. **Clear acceptance criteria**: Every ticket needs testable criteria
3. **Document dependencies**: Always list what's needed before starting
4. **Test before moving**: Never move to In Review without passing tests
5. **Detailed failure reports**: Help future debugging with clear reports
6. **Regular updates**: Add comments when status changes

## Troubleshooting

### Ticket stuck in In Progress
- Check if agent encountered errors
- Review last commit timestamp
- Check if tests are failing
- May need user intervention

### Dependencies unclear
- Review planning document
- Check with user if unsure
- Better to ask than block

### Tests failing repeatedly
- Review test logs in ticket comments
- May indicate architectural issue
- Escalate to user if persistent

---

Last Updated: 2025-12-25

