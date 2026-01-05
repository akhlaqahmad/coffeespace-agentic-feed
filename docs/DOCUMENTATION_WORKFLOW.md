# Documentation Workflow Guide

This document explains how the automatic documentation analysis and update workflow works in CoffeeSpace Agentic Feed.

## Overview

The documentation workflow ensures that all code changes are reflected in the project documentation. This happens automatically through Cursor AI's understanding of the project structure and documentation requirements.

## How It Works

### 1. Automatic Analysis

When you complete a coding task in Cursor, the AI automatically:

1. **Analyzes all changes** made during the session
2. **Determines impact** on documentation files
3. **Updates relevant documentation** files
4. **Reports** what was updated

### 2. Documentation Files

The workflow monitors and updates these files:

| File | Purpose | When Updated |
|------|---------|--------------|
| `docs/agents.md` | Agent system documentation | Agent code, providers, or logic changes |
| `docs/ARCHITECTURE.md` | Architecture and patterns | Structure, patterns, or layers change |
| `docs/design.json` | Design system configuration | Colors, typography, or components change |
| `README.md` | Project overview and setup | Installation, dependencies, or setup changes |
| `docs/*.md` | Feature-specific docs | New major features or modules |

### 3. Change Detection Rules

#### Agent Documentation (`docs/agents.md`)

**Update when:**
- New agent classes or providers are created
- Agent logic, algorithms, or decision-making changes
- Agent communication patterns change
- New agent types are introduced
- Agent configuration or settings are modified

**Example triggers:**
```
✅ lib/features/feed/presentation/agents/feed_curation_agent.dart
✅ lib/features/feed/presentation/providers/agent_provider.dart
✅ Any file containing "Agent" or "agent" in path/name
```

#### Architecture Documentation (`docs/ARCHITECTURE.md`)

**Update when:**
- New folders or modules are added to `lib/`
- Repository patterns change
- State management patterns change (new providers, state structures)
- Data models change (new fields, relationships)
- New dependencies are added to `pubspec.yaml`
- Networking layer changes
- Storage layer changes

**Example triggers:**
```
✅ lib/features/feed/data/repositories/feed_repository.dart
✅ lib/features/feed/domain/usecases/get_feed_usecase.dart
✅ pubspec.yaml (new dependencies)
✅ New folders in lib/features/
```

#### Design System (`docs/design.json`)

**Update when:**
- New colors are added
- Typography scales change
- Spacing values change
- New component styles are defined
- Theme values change

**Example triggers:**
```
✅ lib/core/theme/app_theme.dart
✅ lib/core/theme/colors.dart
✅ Any theme-related file changes
```

#### README (`README.md`)

**Update when:**
- Installation steps change
- Dependencies change
- Build/deployment process changes
- Project structure significantly changes

**Example triggers:**
```
✅ pubspec.yaml (dependencies)
✅ Changes to setup/installation files
✅ New build scripts
✅ Project structure reorganization
```

## Workflow Files

### `.cursorrules`

This file contains instructions for Cursor AI to automatically analyze and update documentation after code changes. It defines:
- When to update documentation
- Which files to update
- How to analyze changes

**Location**: Root directory

### `.cursor/workflows/doc-analysis.md`

Detailed workflow specification that explains:
- Change detection process
- Impact analysis rules
- Update priority levels
- Update procedures

**Location**: `.cursor/workflows/doc-analysis.md`

### `scripts/analyze_docs.sh`

Bash script for manual documentation analysis:
- Analyzes git changes
- Suggests which docs need updates
- Can be run manually or in CI/CD

**Usage:**
```bash
chmod +x scripts/analyze_docs.sh
./scripts/analyze_docs.sh
```

## Manual Workflow Execution

### Option 1: Ask Cursor AI

Simply ask:
```
"Analyze the changes and update documentation"
```

or

```
"Review all documentation files and update them based on recent changes"
```

### Option 2: Run Analysis Script

```bash
# Make script executable (first time only)
chmod +x scripts/analyze_docs.sh

# Run analysis
./scripts/analyze_docs.sh
```

### Option 3: Review Checklist

Manually check these after code changes:

- [ ] Are there new agents or agent logic changes? → Update `docs/agents.md`
- [ ] Are there architecture or structural changes? → Update `docs/ARCHITECTURE.md`
- [ ] Are there design system changes? → Update `docs/design.json`
- [ ] Are there dependency or setup changes? → Update `README.md`
- [ ] Are there new major features? → Create or update feature docs

## Workflow Best Practices

### 1. Review Before Committing

Always review documentation updates before committing:
```bash
git diff docs/agents.md
git diff docs/ARCHITECTURE.md
# etc.
```

### 2. Keep Documentation Synchronized

Documentation should be updated in the same commit as code changes:
```bash
git add lib/features/feed/presentation/agents/new_agent.dart
git add docs/agents.md  # Documentation update
git commit -m "Add new agent and update documentation"
```

### 3. Validate Documentation

After updates, verify:
- ✅ Code examples still compile
- ✅ Links are valid
- ✅ Formatting is consistent
- ✅ All new concepts are documented

### 4. Documentation Standards

Follow these standards:
- Use clear, concise language
- Include code examples when relevant
- Keep formatting consistent
- Update diagrams if needed
- Remove outdated information

## Troubleshooting

### Documentation Not Updating

If documentation isn't updating automatically:

1. **Check `.cursorrules`** - Ensure file exists and is readable
2. **Ask explicitly** - Request documentation update: "Update documentation"
3. **Run script** - Use `scripts/analyze_docs.sh` to identify needed updates
4. **Manual review** - Use the checklist above

### Overly Aggressive Updates

If documentation is updating too frequently:

1. Check `.cursorrules` for overly broad triggers
2. Adjust rules to be more specific
3. Review changes before accepting documentation updates

### Missing Updates

If important changes aren't reflected in docs:

1. Review change detection rules
2. Manually update affected documentation
3. Consider improving `.cursorrules` rules
4. Add comments to code to trigger documentation updates

## Integration with CI/CD

The `scripts/analyze_docs.sh` script can be integrated into CI/CD pipelines:

```yaml
# Example GitHub Actions workflow
- name: Check Documentation
  run: |
    chmod +x scripts/analyze_docs.sh
    ./scripts/analyze_docs.sh
```

This ensures documentation stays in sync with code in collaborative environments.

## Future Enhancements

Planned improvements:
- [ ] Automated documentation validation
- [ ] Documentation coverage metrics
- [ ] Pre-commit hooks for documentation checks
- [ ] AI-powered documentation generation from code comments
- [ ] Documentation diff visualization

## Support

If you have questions or issues with the documentation workflow:
1. Check this guide first
2. Review `.cursorrules` file
3. Run `scripts/analyze_docs.sh` for diagnostics
4. Ask Cursor AI: "Help me understand the documentation workflow"

