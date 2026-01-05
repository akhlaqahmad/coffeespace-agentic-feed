#!/bin/bash

# Documentation Analysis Script
# This script analyzes code changes and suggests documentation updates

echo "📚 CoffeeSpace Documentation Analysis"
echo "====================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get list of modified files (staged or unstaged)
if [ -d .git ]; then
    MODIFIED_FILES=$(git diff --name-only HEAD 2>/dev/null || git diff --name-only 2>/dev/null)
else
    echo "${YELLOW}⚠️  Not a git repository. Analyzing all Dart files...${NC}"
    MODIFIED_FILES=$(find lib -name "*.dart" 2>/dev/null)
fi

echo "${BLUE}Analyzing changes...${NC}"
echo ""

# Track what needs updating
NEEDS_AGENTS_MD=false
NEEDS_ARCHITECTURE_MD=false
NEEDS_DESIGN_JSON=false
NEEDS_README_MD=false

# Check each file
while IFS= read -r file; do
    if [[ -z "$file" ]]; then
        continue
    fi
    
    echo "  📄 $file"
    
    # Check for agent-related changes
    if [[ "$file" == *"agent"* ]] || [[ "$file" == *"Agent"* ]] || [[ "$file" == *"provider"* ]]; then
        NEEDS_AGENTS_MD=true
        echo "    → May affect docs/agents.md"
    fi
    
    # Check for architecture changes
    if [[ "$file" == *"repository"* ]] || [[ "$file" == *"datasource"* ]] || [[ "$file" == *"usecase"* ]] || [[ "$file" == *"model"* ]] || [[ "$file" == *"entity"* ]]; then
        NEEDS_ARCHITECTURE_MD=true
        echo "    → May affect docs/ARCHITECTURE.md"
    fi
    
    # Check for design system changes
    if [[ "$file" == *"theme"* ]] || [[ "$file" == *"design"* ]] || [[ "$file" == *"color"* ]] || [[ "$file" == *"style"* ]]; then
        NEEDS_DESIGN_JSON=true
        echo "    → May affect docs/design.json"
    fi
    
    # Check for pubspec changes
    if [[ "$file" == "pubspec.yaml" ]]; then
        NEEDS_README_MD=true
        NEEDS_ARCHITECTURE_MD=true
        echo "    → May affect README.md and docs/ARCHITECTURE.md"
    fi
    
    # Check for new directories
    if [[ "$file" == lib/* ]] && [[ $(dirname "$file" | tr '/' '\n' | wc -l) -gt 2 ]]; then
        NEEDS_ARCHITECTURE_MD=true
        echo "    → May affect ARCHITECTURE.md (new structure)"
    fi
    
done <<< "$MODIFIED_FILES"

echo ""
echo "${BLUE}Documentation Update Recommendations:${NC}"
echo ""

if [ "$NEEDS_AGENTS_MD" = true ]; then
    echo "${YELLOW}⚠️  docs/agents.md${NC} - Review and update agent documentation"
fi

if [ "$NEEDS_ARCHITECTURE_MD" = true ]; then
    echo "${YELLOW}⚠️  docs/ARCHITECTURE.md${NC} - Review and update architecture documentation"
fi

if [ "$NEEDS_DESIGN_JSON" = true ]; then
    echo "${YELLOW}⚠️  docs/design.json${NC} - Review and update design system"
fi

if [ "$NEEDS_README_MD" = true ]; then
    echo "${YELLOW}⚠️  README.md${NC} - Review and update project readme"
fi

if [ "$NEEDS_AGENTS_MD" = false ] && [ "$NEEDS_ARCHITECTURE_MD" = false ] && [ "$NEEDS_DESIGN_JSON" = false ] && [ "$NEEDS_README_MD" = false ]; then
    echo "${GREEN}✓ No obvious documentation updates needed${NC}"
fi

echo ""
echo "${BLUE}Next Steps:${NC}"
echo "1. Review the suggested documentation files"
echo "2. Update documentation to reflect code changes"
echo "3. Commit documentation updates with code changes"
echo ""

