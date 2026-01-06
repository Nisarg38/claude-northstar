#!/bin/bash

# Claude North Star Uninstaller

set -e

HARNESS_DIR=".claude/harness"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo ""
echo -e "${YELLOW}Uninstalling Claude North Star${NC}"
echo ""

if [ ! -d "$HARNESS_DIR" ]; then
    echo -e "${RED}North Star not found at $HARNESS_DIR${NC}"
    exit 1
fi

echo "This will remove:"
echo "  - $HARNESS_DIR/ (all harness files)"
echo ""
echo -e "${YELLOW}Note: This will NOT remove:${NC}"
echo "  - CLAUDE.md (you may want to edit it manually)"
echo "  - Any code North Star helped create"
echo ""

read -p "Are you sure? [y/N] " -n 1 -r
echo

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Uninstall cancelled."
    exit 0
fi

rm -rf "$HARNESS_DIR"

# Clean up empty .claude directory if nothing else is there
if [ -d ".claude" ] && [ -z "$(ls -A .claude)" ]; then
    rmdir ".claude"
fi

echo ""
echo -e "${GREEN}North Star uninstalled.${NC}"
echo ""
echo "You may want to manually:"
echo "  - Remove the North Star section from CLAUDE.md"
echo "  - Remove North Star entries from .gitignore"
echo ""
