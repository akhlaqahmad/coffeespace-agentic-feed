#!/usr/bin/env python3
"""
Documentation Analysis Script
Analyzes code changes and suggests documentation updates.
"""

import os
import subprocess
import sys
from pathlib import Path
from typing import List, Set

# Color codes for terminal output
class Colors:
    GREEN = '\033[0;32m'
    YELLOW = '\033[1;33m'
    BLUE = '\033[0;34m'
    RED = '\033[0;31m'
    NC = '\033[0m'  # No Color

def get_modified_files() -> List[str]:
    """Get list of modified files from git or analyze all Dart files."""
    files = []
    
    # Try to get git changes
    try:
        result = subprocess.run(
            ['git', 'diff', '--name-only', 'HEAD'],
            capture_output=True,
            text=True,
            check=False
        )
        if result.returncode == 0 and result.stdout.strip():
            files.extend(result.stdout.strip().split('\n'))
        else:
            # Try unstaged changes
            result = subprocess.run(
                ['git', 'diff', '--name-only'],
                capture_output=True,
                text=True,
                check=False
            )
            if result.returncode == 0 and result.stdout.strip():
                files.extend(result.stdout.strip().split('\n'))
    except FileNotFoundError:
        pass
    
    # If no git changes, analyze all Dart files in lib/
    if not files:
        lib_path = Path('lib')
        if lib_path.exists():
            files = [str(f.relative_to('.')) for f in lib_path.rglob('*.dart')]
    
    return [f for f in files if f.strip()]

def analyze_file(file_path: str) -> Set[str]:
    """Analyze a file and return set of documentation files that might need updates."""
    affected_docs = set()
    file_lower = file_path.lower()
    
    # Check for agent-related changes
    if 'agent' in file_lower or 'provider' in file_lower:
        affected_docs.add('docs/agents.md')
    
    # Check for architecture changes
    if any(keyword in file_lower for keyword in [
        'repository', 'datasource', 'usecase', 'usecases',
        'model', 'entity', 'domain', 'data', 'presentation'
    ]):
        affected_docs.add('docs/ARCHITECTURE.md')
    
    # Check for design system changes
    if any(keyword in file_lower for keyword in [
        'theme', 'design', 'color', 'style', 'typography', 'component'
    ]):
        affected_docs.add('docs/design.json')
    
    # Check for pubspec changes
    if file_path == 'pubspec.yaml':
        affected_docs.add('README.md')
        affected_docs.add('docs/ARCHITECTURE.md')
    
    # Check for new directories/structure
    if file_path.startswith('lib/') and file_path.count('/') > 1:
        affected_docs.add('docs/ARCHITECTURE.md')
    
    # Check for main changes
    if file_path == 'lib/main.dart' or file_path == 'README.md':
        affected_docs.add('README.md')
    
    return affected_docs

def main():
    print(f"{Colors.BLUE}📚 CoffeeSpace Documentation Analysis{Colors.NC}")
    print("=" * 50)
    print()
    
    modified_files = get_modified_files()
    
    if not modified_files:
        print(f"{Colors.YELLOW}⚠️  No files to analyze{Colors.NC}")
        return
    
    print(f"{Colors.BLUE}Analyzing {len(modified_files)} file(s)...{Colors.NC}")
    print()
    
    all_affected_docs = set()
    file_docs_map = {}
    
    for file_path in modified_files:
        affected = analyze_file(file_path)
        if affected:
            file_docs_map[file_path] = affected
            all_affected_docs.update(affected)
            print(f"  📄 {file_path}")
            for doc in affected:
                print(f"    → May affect {doc}")
    
    print()
    print(f"{Colors.BLUE}Documentation Update Recommendations:{Colors.NC}")
    print()
    
    if all_affected_docs:
        doc_priority = {
            'docs/agents.md': 'Agent logic, providers, or decision-making changes',
            'docs/ARCHITECTURE.md': 'Structure, patterns, or architecture changes',
            'docs/design.json': 'Design system, colors, or component changes',
            'README.md': 'Setup, installation, or project overview changes'
        }
        
        for doc in sorted(all_affected_docs):
            description = doc_priority.get(doc, 'Review and update')
            print(f"{Colors.YELLOW}⚠️  {doc}{Colors.NC} - {description}")
    else:
        print(f"{Colors.GREEN}✓ No obvious documentation updates needed{Colors.NC}")
    
    print()
    print(f"{Colors.BLUE}Next Steps:{Colors.NC}")
    print("1. Review the suggested documentation files")
    print("2. Update documentation to reflect code changes")
    print("3. Commit documentation updates with code changes")
    print()
    
    # Return exit code based on whether updates are needed
    sys.exit(0 if not all_affected_docs else 1)

if __name__ == '__main__':
    main()

