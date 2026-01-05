# Documentation Analysis Workflow

This workflow automatically analyzes code changes and updates documentation files accordingly.

## Workflow Steps

### 1. Change Detection
Analyze all modified files in the current session:
- Modified files (`.dart`, `.yaml`, `.json`, etc.)
- New files created
- Deleted files
- Dependencies added/removed

### 2. Impact Analysis
For each change, determine which documentation files are affected:

| Change Type | Affected Docs |
|------------|---------------|
| Agent code (`lib/**/agents/**` or agent-related providers) | `docs/agents.md` |
| Architecture changes (new folders, repositories, patterns) | `docs/ARCHITECTURE.md` |
| Design system (colors, typography, components) | `docs/design.json` |
| Setup/installation changes | `README.md` |
| New major features | New doc file in `docs/` or relevant existing docs |
| Dependencies (`pubspec.yaml`) | `README.md`, `docs/ARCHITECTURE.md` |

### 3. Documentation Update Priority

**High Priority** (Update immediately):
- Breaking changes
- New major features
- Architecture changes
- API changes

**Medium Priority** (Update in same session):
- New utilities or helpers
- Minor feature additions
- Bug fixes that affect behavior

**Low Priority** (Note for later):
- Code refactoring (unless it changes architecture)
- Test additions
- Comments/documentation only changes

### 4. Update Process

For each affected documentation file:

1. **Read current documentation**
2. **Identify sections to update**
3. **Update with new information**:
   - Add new sections if needed
   - Update existing sections
   - Remove outdated information
   - Update code examples
   - Update diagrams if needed
4. **Verify consistency** with existing style
5. **Check for broken links** or references

### 5. New Documentation Creation

Create new documentation files when:
- New major feature needs dedicated docs
- New architectural pattern introduced
- API documentation needed
- User guides needed

Naming convention: `docs/FEATURE_NAME.md` (e.g., `docs/AUTHENTICATION.md`, `docs/REALTIME_SYNC.md`)

## Automated Execution

This workflow runs automatically after code changes. The AI assistant will:
1. Complete the requested code changes
2. Analyze all changes made
3. Determine affected documentation
4. Update documentation files
5. Report what was updated

## Manual Execution

If you want to manually trigger documentation analysis, you can:
1. Ask: "Analyze changes and update documentation"
2. Or: "Review and update all documentation files"
3. Or: "Check if documentation needs updates"

