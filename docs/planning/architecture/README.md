# Architecture Decision Records (ADRs)

## Purpose

This directory contains Architecture Decision Records (ADRs) - documents that capture important architectural decisions made during the project lifecycle.

## ADR Template

Use the following template for new ADRs:

```markdown
# ADR-NNN: [Title]

**Status**: Proposed | Accepted | Deprecated | Superseded  
**Date**: YYYY-MM-DD  
**Deciders**: [List of people involved]  
**Context**: Link to related planning docs or issues

## Context

Describe the context and background:
- What is the issue/problem we're addressing?
- What are the forces at play?
- What constraints exist?

## Decision

What is the change we're proposing and/or doing?

## Consequences

What becomes easier or more difficult to do because of this change?

### Positive Consequences

- Benefit 1
- Benefit 2

### Negative Consequences

- Trade-off 1
- Trade-off 2

### Neutral Consequences

- Impact 1
- Impact 2

## Alternatives Considered

### Alternative 1: [Name]

Description and why it wasn't chosen.

### Alternative 2: [Name]

Description and why it wasn't chosen.

## References

- Link to planning documents
- Link to external resources
- Link to similar decisions in other projects
```

## Naming Convention

Files should be named: `ADR-NNN-short-title.md`

Examples:
- `ADR-001-database-choice.md`
- `ADR-002-authentication-strategy.md`
- `ADR-003-api-versioning.md`

## When to Create an ADR

Create an ADR when:
- Making a significant architectural decision
- Choosing between competing technologies
- Establishing a pattern or standard
- Making a decision that's hard to reverse
- Making a decision that affects multiple teams/components

## ADR Workflow

1. **Draft**: Create ADR with status "Proposed"
2. **Review**: Discuss with team/stakeholders
3. **Decision**: Update status to "Accepted" when decided
4. **Implement**: Reference ADR in related tickets/PRs
5. **Evolve**: Update if circumstances change
6. **Supersede**: If decision changes, create new ADR and update old one

---

Start your ADRs at `ADR-001-[title].md`

