---
id: FEAT-002
title: Multi-Tier Project Architecture (Monorepo)
status: draft
created: 2025-12-26
updated: 2025-12-26
author: AI Agent
priority: high
type: architecture
---

# Multi-Tier Project Architecture (Monorepo)

## Overview

Define a comprehensive, opinionated structure for 3-tier applications (frontend, backend, database) that maintains existing development standards (planning-first, TDD, linting, GitFlow) while supporting containerized development with Docker.

## Business Value

- **Consistency**: Single structure for all multi-tier projects
- **Efficiency**: Agents can work seamlessly across full stack
- **Quality**: Same standards (TDD, linting) apply to all tiers
- **Developer Experience**: One command (`docker-compose up`) for local development
- **Atomic Changes**: Feature branches can span multiple tiers
- **Maintainability**: Monorepo keeps code synchronized and reduces coordination overhead

## Requirements

### Functional Requirements

1. **Support 3-Tier Applications**
   - Frontend (web UI)
   - Backend (API/business logic)
   - Database (persistence layer)

2. **Maintain Single-Codebase Compatibility**
   - Projects can be single-tier OR multi-tier
   - Same tooling works for both

3. **Containerization**
   - Each tier has its own Dockerfile
   - Docker Compose for local development
   - Production-ready container configuration

4. **Independent Deployment**
   - Each tier can be deployed separately
   - Or deployed together as a unit

5. **Tier-Specific Tooling**
   - Frontend: ESLint, Stylelint, frontend framework tools
   - Backend: Language-specific linters (Ruff for Python, ESLint for Node.js)
   - Database: Migration tools, seed scripts

### Non-Functional Requirements

1. **Consistency**: All tiers follow same code quality standards
2. **Performance**: Smart CI/CD only tests/builds changed tiers
3. **Scalability**: Structure works for small and large teams
4. **Maintainability**: Clear separation of concerns
5. **Documentation**: Each tier has its own README
6. **Testing**: Comprehensive testing at all levels (unit, integration, E2E)

## Architecture Decision: Monorepo vs Polyrepo

### Decision: **Monorepo** (Single Repository)

**Rationale:**
- ✅ Agents can work across full stack without switching contexts
- ✅ Atomic commits for features spanning multiple tiers
- ✅ Shared tooling (`scripts/`, linting configs) benefits all tiers
- ✅ Single `.cursorrules` ensures consistency
- ✅ Docker Compose handles local development elegantly
- ✅ Planning documents can span multiple tiers naturally
- ✅ Version synchronization is automatic (no dependency hell)
- ✅ Simpler for most use cases

**When Polyrepo might be better:**
- Large teams with strict tier ownership
- Different deployment schedules per tier (rare)
- Tiers in completely different tech stacks requiring different CI/CD
- Strict security boundaries between tiers

## Proposed Directory Structure

```
project/
├── frontend/                  # Frontend application (React/Vue/Angular/Svelte)
│   ├── src/                  # Frontend source code
│   │   ├── components/       # UI components
│   │   ├── pages/            # Page components
│   │   ├── services/         # API clients
│   │   ├── utils/            # Frontend utilities
│   │   ├── styles/           # Global styles
│   │   └── config/           # Frontend configuration
│   ├── tests/
│   │   ├── unit/             # Component tests
│   │   ├── integration/      # API integration tests
│   │   └── e2e/              # Frontend E2E tests
│   ├── public/               # Static assets
│   ├── Dockerfile            # Frontend container
│   ├── .dockerignore
│   ├── package.json
│   ├── tsconfig.json         # TypeScript config
│   ├── .eslintrc.js          # Frontend-specific ESLint
│   ├── .stylelintrc.json     # Frontend-specific Stylelint
│   └── README.md             # Frontend documentation
│
├── backend/                   # Backend application (Python/Node.js/Go)
│   ├── src/                  # Backend source code
│   │   ├── api/              # REST/GraphQL endpoints
│   │   │   ├── routes/       # Route definitions
│   │   │   └── handlers/     # Request handlers
│   │   ├── services/         # Business logic layer
│   │   ├── models/           # Data models/ORM
│   │   ├── middleware/       # Auth, logging, etc.
│   │   ├── utils/            # Backend utilities
│   │   └── config/           # Backend configuration
│   ├── tests/
│   │   ├── unit/             # Service/model tests
│   │   ├── integration/      # API integration tests
│   │   └── e2e/              # Backend E2E tests
│   ├── Dockerfile            # Backend container
│   ├── .dockerignore
│   ├── requirements.txt      # Python dependencies
│   │   # OR package.json     # Node.js dependencies
│   ├── ruff.toml             # Python-specific Ruff config
│   │   # OR .eslintrc.js     # Node.js-specific ESLint
│   └── README.md             # Backend documentation
│
├── database/                  # Database configuration and migrations
│   ├── migrations/           # Schema migrations
│   │   └── versions/         # Timestamped migration files
│   ├── seeds/                # Test/demo data
│   │   ├── dev/              # Development seeds
│   │   └── test/             # Test seeds
│   ├── init/                 # Initial setup scripts
│   │   └── 001_create_schema.sql
│   ├── Dockerfile            # Custom DB image (if needed)
│   └── README.md             # Database documentation
│
├── shared/                    # Shared code across tiers (optional)
│   ├── types/                # TypeScript type definitions
│   ├── constants/            # Shared constants
│   ├── schemas/              # API schemas/contracts (OpenAPI, GraphQL)
│   └── README.md
│
├── scripts/                   # Infrastructure code (same as single-tier)
│   ├── github/               # GitHub API utilities
│   ├── quality/              # Linting, pre-PR checks
│   ├── docker/               # Docker helper scripts
│   │   ├── build_all.sh      # Build all containers
│   │   ├── test_all.sh       # Run all tier tests
│   │   └── clean.sh          # Clean Docker artifacts
│   └── deploy/               # Deployment scripts
│       ├── deploy_frontend.sh
│       ├── deploy_backend.sh
│       └── deploy_all.sh
│
├── docs/                      # Documentation
│   ├── architecture/         # Architecture decision records
│   │   └── ADR-001-monorepo.md
│   ├── api/                  # API documentation
│   ├── planning/
│   │   └── features/
│   └── guides/
│       ├── getting-started.md
│       ├── frontend-guide.md
│       ├── backend-guide.md
│       ├── database-guide.md
│       └── docker-guide.md
│
├── tests/                     # Cross-tier integration tests
│   └── e2e/                  # Full-stack E2E tests
│       ├── user-flows/       # Complete user journeys
│       └── api-to-ui/        # Backend → Frontend flows
│
├── .github/
│   └── workflows/            # CI/CD pipelines
│       ├── frontend.yml      # Frontend CI
│       ├── backend.yml       # Backend CI
│       ├── database.yml      # Database migration tests
│       └── integration.yml   # Full-stack integration tests
│
├── docker-compose.yml         # Local development environment
├── docker-compose.prod.yml    # Production-like setup
├── docker-compose.test.yml    # Testing environment
├── .env.example              # All environment variables
├── .cursorrules              # Agent rules (applies to all tiers)
├── .gitignore
├── README.md                 # Project overview and quick start
└── QUICKSTART.md             # Quick reference
```

## Key Design Principles

### 1. Each Tier is Self-Contained

**Why:**
- Clear separation of concerns
- Independent deployment capability
- Easier to reason about
- Can be extracted to separate repo if needed

**How:**
- Each tier has its own `src/`, `tests/`, `Dockerfile`
- Each tier has tier-specific dependencies
- Each tier has its own README with setup instructions
- Each tier can be run independently in Docker

### 2. Shared Tooling at Root

**Why:**
- Consistent quality standards across all tiers
- Single source of truth for workflows
- Reduced duplication

**How:**
- `scripts/` directory used by all tiers
- Root `.cursorrules` applies to all code
- Shared pre-commit hooks
- Shared GitHub Actions workflows

### 3. Docker-First Development

**Why:**
- Consistent environments (dev, test, prod)
- No "works on my machine" issues
- Easy onboarding for new developers
- Matches production deployment

**How:**
- Each tier has optimized Dockerfile
- `docker-compose.yml` for local development
- One command to start everything: `docker-compose up`
- Hot reloading in development
- Separate compose files for different environments

### 4. Testing Strategy

**Tier-Specific Tests:**
- Each tier has `tests/unit/`, `tests/integration/`, `tests/e2e/`
- Tests run independently per tier
- Fast feedback loop

**Cross-Tier Tests:**
- Root `tests/e2e/` for full-stack scenarios
- Run after all tier tests pass
- Test complete user flows

**Test Pyramid:**
```
        /\
       /  \    E2E (few, slow, expensive)
      /____\
     /      \  Integration (some, medium)
    /________\
   /          \ Unit (many, fast, cheap)
  /__________\
```

### 5. CI/CD Strategy

**Smart Pipeline Execution:**
```yaml
# Only run frontend tests if frontend changed
if: contains(github.event.commits.*.modified, 'frontend/')

# Only build backend if backend changed
if: contains(github.event.commits.*.modified, 'backend/')
```

**Pipeline Stages:**
1. **Lint**: Run linters for changed tiers
2. **Test**: Run tests for changed tiers
3. **Build**: Build Docker images for changed tiers
4. **Integration**: Run cross-tier tests if multiple tiers changed
5. **Deploy**: Deploy changed tiers

## Environment Variables Structure

**Unified `.env` for all tiers:**

```bash
# GitHub Integration (used by scripts)
GITHUB_API_KEY=your_token_here
GITHUB_OWNER=your_username
GITHUB_REPO=your_repo
GITHUB_PROJECT_NUMBER=1

# Frontend Configuration
FRONTEND_PORT=3000
FRONTEND_API_URL=http://localhost:8000/api
FRONTEND_ENV=development

# Backend Configuration
BACKEND_PORT=8000
BACKEND_HOST=0.0.0.0
BACKEND_ENV=development
BACKEND_DEBUG=true
BACKEND_LOG_LEVEL=info

# Database Configuration
DATABASE_URL=postgresql://user:password@postgres:5432/dbname
DATABASE_HOST=postgres
DATABASE_PORT=5432
DATABASE_NAME=dbname
DATABASE_USER=user
DATABASE_PASSWORD=password

# Database (PostgreSQL specific)
POSTGRES_USER=user
POSTGRES_PASSWORD=password
POSTGRES_DB=dbname

# Security
JWT_SECRET=your_jwt_secret_here
API_KEY=your_api_key_here

# External Services (examples)
REDIS_URL=redis://redis:6379
ELASTICSEARCH_URL=http://elasticsearch:9200
```

## Docker Compose Configuration

### Development Environment (`docker-compose.yml`)

```yaml
version: '3.8'

services:
  frontend:
    build:
      context: ./frontend
      dockerfile: Dockerfile
      target: development
    ports:
      - "${FRONTEND_PORT}:3000"
    environment:
      - REACT_APP_API_URL=${BACKEND_URL}
    volumes:
      - ./frontend/src:/app/src      # Hot reloading
      - /app/node_modules            # Don't override
    depends_on:
      - backend
    networks:
      - app-network

  backend:
    build:
      context: ./backend
      dockerfile: Dockerfile
      target: development
    ports:
      - "${BACKEND_PORT}:8000"
    environment:
      - DATABASE_URL=${DATABASE_URL}
      - DEBUG=${BACKEND_DEBUG}
    volumes:
      - ./backend/src:/app/src       # Hot reloading
    depends_on:
      - postgres
      - redis
    networks:
      - app-network

  postgres:
    image: postgres:15-alpine
    environment:
      - POSTGRES_USER=${DATABASE_USER}
      - POSTGRES_PASSWORD=${DATABASE_PASSWORD}
      - POSTGRES_DB=${DATABASE_NAME}
    volumes:
      - postgres-data:/var/lib/postgresql/data
      - ./database/init:/docker-entrypoint-initdb.d
    ports:
      - "${DATABASE_PORT}:5432"
    networks:
      - app-network

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
    networks:
      - app-network

volumes:
  postgres-data:

networks:
  app-network:
    driver: bridge
```

### Production Environment (`docker-compose.prod.yml`)

```yaml
version: '3.8'

services:
  frontend:
    build:
      context: ./frontend
      dockerfile: Dockerfile
      target: production
    ports:
      - "80:80"
    environment:
      - NODE_ENV=production
    restart: unless-stopped

  backend:
    build:
      context: ./backend
      dockerfile: Dockerfile
      target: production
    ports:
      - "8000:8000"
    environment:
      - DATABASE_URL=${DATABASE_URL}
      - ENVIRONMENT=production
    restart: unless-stopped

  postgres:
    image: postgres:15-alpine
    environment:
      - POSTGRES_USER=${DATABASE_USER}
      - POSTGRES_PASSWORD=${DATABASE_PASSWORD}
      - POSTGRES_DB=${DATABASE_NAME}
    volumes:
      - postgres-data:/var/lib/postgresql/data
    restart: unless-stopped

volumes:
  postgres-data:
    driver: local
```

## Git Workflow for Multi-Tier

### Branch Naming Conventions

**Feature branches that span tiers:**
```
feature/user-authentication
  - frontend/src/pages/Login.tsx
  - backend/src/api/routes/auth.py
  - database/migrations/001_add_users_table.sql
```

**Tier-specific branches:**
```
feature/frontend-dark-mode
  - Only touches frontend/

feature/backend-caching
  - Only touches backend/

feature/database-indexing
  - Only touches database/
```

### Commit Strategy

**Atomic commits per tier:**
```bash
# Commit frontend changes
git add frontend/
git commit -m "feat(frontend): add login page UI"

# Commit backend changes
git add backend/
git commit -m "feat(backend): add authentication endpoint"

# Commit database changes
git add database/
git commit -m "feat(database): add users table migration"
```

**OR combined commit for tightly coupled changes:**
```bash
git add frontend/ backend/ database/
git commit -m "feat(auth): implement user authentication across stack

- Add login page UI (frontend)
- Add authentication API endpoint (backend)
- Add users table migration (database)"
```

### Testing Requirements

**Before creating PR, ALL must pass:**
- ✅ Linters for all changed tiers
- ✅ Unit tests for all changed tiers
- ✅ Integration tests for all changed tiers
- ✅ Cross-tier E2E tests if multiple tiers changed
- ✅ All Docker images build successfully

## Linting Strategy for Multi-Tier

### Pre-commit Hook Behavior

**Smart tier detection:**
```python
# Detect which tiers were modified
frontend_changed = any('frontend/' in f for f in staged_files)
backend_changed = any('backend/' in f for f in staged_files)

# Run appropriate linters
if frontend_changed:
    run_eslint('frontend/')
    run_stylelint('frontend/')

if backend_changed:
    if is_python_backend:
        run_ruff('backend/')
    elif is_node_backend:
        run_eslint('backend/')
```

### Tier-Specific Linting Configs

**Frontend:**
- `frontend/.eslintrc.js` (React/Vue/Angular specific rules)
- `frontend/.stylelintrc.json` (CSS/SCSS rules)
- `frontend/tsconfig.json` (TypeScript rules)

**Backend (Python):**
- `backend/ruff.toml` (Python linting)
- `backend/pyproject.toml` (Tool configs)

**Backend (Node.js):**
- `backend/.eslintrc.js` (Node.js specific rules)
- `backend/tsconfig.json` (TypeScript rules)

## Migration Path

### From Single-Tier to Multi-Tier

If a project starts as single-tier and grows:

**Current structure:**
```
project/
├── src/          # Backend code
├── tests/
└── scripts/
```

**Migration:**
```bash
# Create tier directories
mkdir -p frontend backend database

# Move existing code
mv src backend/
mv tests backend/

# Keep scripts/ at root (shared)
# scripts/ stays where it is

# Add new directories
mkdir -p frontend/src frontend/tests
mkdir -p database/migrations database/seeds

# Update paths in configs
# Update .cursorrules to reflect multi-tier
```

## Implementation Tasks

If this plan is approved, the following tasks would be created:

1. **Update `.cursorrules`**
   - Add multi-tier structure guidance
   - Add Docker workflow rules
   - Add tier-specific testing requirements

2. **Create Architecture Decision Record**
   - Document monorepo decision
   - Document structure rationale

3. **Create Docker Guide**
   - Local development with Docker Compose
   - Building and deploying containers

4. **Update Pre-commit Hooks**
   - Add tier detection logic
   - Run appropriate linters per tier

5. **Create Docker Helper Scripts**
   - `scripts/docker/build_all.sh`
   - `scripts/docker/test_all.sh`
   - `scripts/docker/clean.sh`

6. **Update Documentation**
   - Add multi-tier quick start to README
   - Create tier-specific guides

7. **Create Template Docker Compose Files**
   - Development environment
   - Production environment
   - Testing environment

8. **Update `.env.example`**
   - Add all tier-specific variables
   - Group by tier with comments

## Test Strategy

### Unit Tests (Each Tier)

**Frontend:**
- Component rendering tests
- Utility function tests
- State management tests

**Backend:**
- Service layer tests
- Model validation tests
- Utility function tests

**Database:**
- Migration up/down tests
- Seed data validation

### Integration Tests (Each Tier)

**Frontend:**
- API client integration
- Component interaction tests

**Backend:**
- API endpoint tests
- Database query tests

### E2E Tests (Cross-Tier)

**Full-stack scenarios:**
- Complete user registration flow
- Authentication flow
- Data CRUD operations
- Error handling across tiers

## Dependencies

**External:**
- Docker and Docker Compose
- Language runtimes per tier

**Internal:**
- Existing linting setup (Ruff, ESLint, Stylelint)
- Existing GitHub API integration
- Existing Git workflow (feature branches, PRs)

## Risks & Mitigation

### Risk 1: Monorepo becomes too large

**Mitigation:**
- Use `.dockerignore` to exclude unnecessary files from builds
- Smart CI/CD only tests changed tiers
- Can split to polyrepo if truly needed

### Risk 2: Different deployment schedules per tier

**Mitigation:**
- Each tier can be deployed independently
- Docker images are tier-specific
- Versioning strategy can differ per tier

### Risk 3: Merge conflicts across tiers

**Mitigation:**
- Tiers are well-separated (different directories)
- Conflicts should be rare
- When they occur, they're explicit and easy to resolve

### Risk 4: Tier dependencies become tangled

**Mitigation:**
- API contracts defined in `shared/schemas/`
- Clear interface boundaries (REST/GraphQL)
- Integration tests catch breaking changes

### Risk 5: Local development complexity

**Mitigation:**
- Docker Compose handles all complexity
- One command to start: `docker-compose up`
- Hot reloading in development
- Comprehensive docker-guide.md

## Success Criteria

- [ ] `.cursorrules` updated with multi-tier guidance
- [ ] Architecture decision documented
- [ ] Docker workflow documented
- [ ] Template structure clear and documented
- [ ] Agents understand when to use single vs multi-tier
- [ ] Existing single-tier projects remain unaffected

## Future Enhancements

- Kubernetes manifests for production deployment
- Service mesh for inter-tier communication
- Monitoring and observability stack (Prometheus, Grafana)
- Automated database backups and restore scripts
- Load testing across tiers

---

## Approval Status

**Status:** Draft - Awaiting user review

**Questions for User:**

1. ✅ Monorepo structure confirmed?
2. 📋 Typical tech stack preferences (React/Vue? Python/Node.js? PostgreSQL/MySQL)?
3. 📋 Kubernetes needed, or Docker Compose sufficient?
4. 📋 `shared/` directory for types/schemas?
5. 📋 Any additional services (Redis, Elasticsearch, message queues)?

**Next Steps After Approval:**
1. Update `.cursorrules` with multi-tier guidance
2. Create ADR for monorepo decision
3. Wait for user to create GitHub issues for implementation tasks
