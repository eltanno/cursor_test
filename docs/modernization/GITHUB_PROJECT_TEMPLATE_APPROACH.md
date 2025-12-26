# GitHub Projects V2 - Template-Based Approach

## Problem
GitHub's API cannot create projects with the Kanban template directly. However, it CAN copy existing projects!

## Solution: Template + Copy Pattern

### One-Time Setup (Manual)

1. **Create Template Project:**
   - Go to: https://github.com/YOUR_USERNAME?tab=projects
   - Click "New project"
   - Select **"Kanban"** template (the one with Board view pre-configured)
   - Name it: `cursor-scaffold-kanban-template`
   - Click "Create"

2. **Customize Template (Optional):**
   - Adjust Status field columns if desired
   - Our standard columns: Backlog, Ready, In Progress, In Review, In Testing, Test Failed, Done
   - Save any customizations

3. **Get Template Project Number:**
   ```bash
   # The project URL will be:
   # https://github.com/users/YOUR_USERNAME/projects/X
   # Note down the number X
   ```

4. **Add to .env:**
   ```bash
   # Add to cursor_scaffold/.env.example and your .env:
   GITHUB_TEMPLATE_PROJECT_NUMBER=X
   ```

### Automated Usage (API)

Once the template exists, use `copyProjectV2` mutation:

```python
def create_project_from_template(api: GitHubAPI, repo_name: str) -> dict:
    """Create new project by copying Kanban template."""
    
    # Get template project ID
    template_query = """
    query($owner: String!, $number: Int!) {
      user(login: $owner) {
        projectV2(number: $number) {
          id
        }
      }
    }
    """
    
    template_result = api._make_graphql_request(
        template_query,
        {
            'owner': api.owner,
            'number': int(os.getenv('GITHUB_TEMPLATE_PROJECT_NUMBER'))
        }
    )
    template_id = template_result['user']['projectV2']['id']
    
    # Get owner ID
    owner_query = """
    query($login: String!) {
      user(login: $login) {
        id
      }
    }
    """
    owner_result = api._make_graphql_request(owner_query, {'login': api.owner})
    owner_id = owner_result['user']['id']
    
    # Copy template
    copy_mutation = """
    mutation($projectId: ID!, $ownerId: ID!, $title: String!, $includeDraftIssues: Boolean!) {
      copyProjectV2(input: {
        projectId: $projectId
        ownerId: $ownerId
        title: $title
        includeDraftIssues: $includeDraftIssues
      }) {
        projectV2 {
          id
          number
          title
          url
        }
      }
    }
    """
    
    result = api._make_graphql_request(
        copy_mutation,
        {
            'projectId': template_id,
            'ownerId': owner_id,
            'title': f'{repo_name} Kanban',
            'includeDraftIssues': False
        }
    )
    
    return result['copyProjectV2']['projectV2']
```

## Benefits

✅ **Full Kanban template** - Board view, proper columns, GitHub's defaults
✅ **Consistent setup** - Every project identical
✅ **Fully automated** - After one-time manual template creation
✅ **Maintainable** - Update template once, all future projects benefit
✅ **No API limitations** - Uses supported `copyProjectV2` mutation

## Drawbacks

⚠️ **One-time manual step** - Template must be created manually first
⚠️ **User-specific** - Each user needs their own template project
⚠️ **Template project visible** - The template project will appear in user's projects list

## Recommendation

**Use this approach!** It's the best available solution given GitHub's API limitations.

### Implementation Steps:

1. Update `.env.example` to include `GITHUB_TEMPLATE_PROJECT_NUMBER`
2. Update `create_repo_and_project.py` to use `copyProjectV2` instead of `createProjectV2`
3. Add documentation for one-time template setup
4. Update setup instructions in README

### Future-Proofing:

If/when GitHub adds template support to the API, we can:
- Remove the manual template requirement
- Keep the same workflow (copying/templating is still a good pattern)
- Maintain backward compatibility

---

**Would you like me to implement this now?**

