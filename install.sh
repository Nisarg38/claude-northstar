#!/bin/bash

# Claude North Star Installer
# Usage: curl -fsSL https://raw.githubusercontent.com/nisarg38/claude-northstar/main/install.sh | bash

set -e

HARNESS_DIR=".claude/harness"
REPO_URL="https://raw.githubusercontent.com/nisarg38/claude-northstar/main"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_banner() {
    echo ""
    echo -e "${BLUE}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${NC}     ${GREEN}Claude North Star${NC}                      ${BLUE}║${NC}"
    echo -e "${BLUE}║${NC}     Transform CLI agents into autonomous partners        ${BLUE}║${NC}"
    echo -e "${BLUE}╚═══════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

log_info() {
    echo -e "${GREEN}✓${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}!${NC} $1"
}

log_error() {
    echo -e "${RED}✗${NC} $1"
}

# Check if running in a git repo
check_git_repo() {
    if [ ! -d ".git" ]; then
        log_warn "Not a git repository. North Star works best with version control."
        read -p "Continue anyway? [y/N] " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
}

# Check for existing installation
check_existing() {
    if [ -d "$HARNESS_DIR" ]; then
        log_warn "North Star already installed at $HARNESS_DIR"
        read -p "Reinstall? This will overwrite existing files. [y/N] " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Installation cancelled."
            exit 0
        fi
    fi
}

# Create directory structure
create_directories() {
    log_info "Creating directory structure..."
    mkdir -p "$HARNESS_DIR/prompts"
}

# Download a file from the repo
download_file() {
    local src="$1"
    local dest="$2"

    if command -v curl &> /dev/null; then
        curl -fsSL "$REPO_URL/$src" -o "$dest" 2>/dev/null || {
            # If download fails, use embedded content
            return 1
        }
    elif command -v wget &> /dev/null; then
        wget -q "$REPO_URL/$src" -O "$dest" 2>/dev/null || {
            return 1
        }
    else
        return 1
    fi
}

# Create harness files (embedded for offline installation)
create_harness_files() {
    log_info "Creating harness files..."

    # north-star.md
    cat > "$HARNESS_DIR/north-star.md" << 'NORTHSTAR'
# Project North Star

> This document defines the vision. The harness refers to it constantly.

## Vision

<!-- What are you building? Describe it in 2-3 sentences. -->

## Success Criteria

<!-- What does "done" look like? Be specific. -->

- [ ] Criterion 1
- [ ] Criterion 2
- [ ] Criterion 3

## Constraints

<!-- What are the boundaries? Tech stack, timeline, etc. -->

-
-

## Out of Scope

<!-- What are you NOT building? -->

-

---

*Update this document as the vision evolves. The harness adapts.*
NORTHSTAR

    # project-state.json
    cat > "$HARNESS_DIR/project-state.json" << 'PROJSTATE'
{
  "version": "1.0.0",
  "lastUpdated": null,
  "phase": "initial",
  "milestones": [],
  "currentFocus": null,
  "gaps": [],
  "blockers": [],
  "metrics": {
    "totalMilestones": 0,
    "completedMilestones": 0,
    "progress": 0
  },
  "sessions": []
}
PROJSTATE

    # decisions.md
    cat > "$HARNESS_DIR/decisions.md" << 'DECISIONS'
# Architecture Decisions Log

This document tracks important technical decisions for cross-session consistency.

---

<!-- Template for new decisions:

## YYYY-MM-DD: [Decision Title]

**Context**: What prompted this decision?

**Decision**: What was decided?

**Options Considered**:
1. Option A - pros/cons
2. Option B - pros/cons

**Rationale**: Why this choice?

**Consequences**: What does this mean going forward?

---
-->
DECISIONS

    # progress-log.md
    cat > "$HARNESS_DIR/progress-log.md" << 'PROGRESS'
# Progress Log

Session-by-session progress toward the north star.

---

<!-- Template for new sessions:

## Session N (YYYY-MM-DD)

**Focus**: What milestone/goal was being worked on

**Completed**:
- Item 1
- Item 2

**In Progress**:
- Item (X% done)

**Blockers**:
- None / Description

**Next Session**:
- What to pick up

**Notes**:
- Any observations, learnings, or decisions made

---
-->
PROGRESS

    log_info "Created core harness files"
}

# Create sub-agent prompts
create_prompts() {
    log_info "Creating sub-agent prompts..."

    # Product Researcher
    cat > "$HARNESS_DIR/prompts/product-researcher.md" << 'RESEARCHER'
# Product Researcher Sub-Agent

You are a Product Researcher. Your role is to gather market intelligence and inform product decisions.

## Responsibilities
1. Research competitors and alternatives
2. Identify market gaps and opportunities
3. Understand user needs and pain points
4. Find relevant examples and inspiration

## Context
**Project Vision**: {north_star_content}
**Research Question**: {research_question}

## Tools Available
- **WebSearch**: Search for competitors, articles, discussions
- **WebFetch**: Read specific pages for deeper analysis

## Output Format
```json
{
  "status": "completed",
  "question": "The research question",
  "findings": [
    {
      "type": "competitor|article|discussion|example",
      "source": "URL or description",
      "summary": "Key takeaways",
      "relevance": "How this applies to our project"
    }
  ],
  "insights": ["Key insight 1", "Key insight 2"],
  "recommendations": ["Recommendation based on research"],
  "gaps": ["Areas needing more research"]
}
```

## Guidelines
- Focus on actionable insights, not exhaustive lists
- Prioritize recent and relevant sources
- Note if information might be outdated
- Suggest follow-up questions if needed
RESEARCHER

    # Strategist
    cat > "$HARNESS_DIR/prompts/strategist.md" << 'STRATEGIST'
# Strategist Sub-Agent

You are a Technical Strategist. Your role is to make architecture decisions and evaluate trade-offs.

## Responsibilities
1. Evaluate technical options and recommend approaches
2. Analyze trade-offs (effort, risk, scalability)
3. Ensure consistency with previous decisions
4. Plan feature breakdowns

## Context
**Project Vision**: {north_star_content}
**Previous Decisions**: {previous_decisions}
**Question**: {specific_task}

## Tools Available
- **Read**: Review codebase and documentation
- **Glob/Grep**: Search for patterns
- **WebSearch**: Research best practices (if needed)

## Output Format
```json
{
  "status": "completed",
  "question": "The decision to make",
  "options": [
    {
      "name": "Option A",
      "description": "What this entails",
      "pros": ["pro 1", "pro 2"],
      "cons": ["con 1"],
      "effort": "low|medium|high",
      "risk": "low|medium|high"
    }
  ],
  "recommendation": "Option A",
  "rationale": "Why this is best for our context",
  "implementation": ["Step 1", "Step 2"],
  "needsHumanInput": false,
  "humanQuestion": null
}
```

## Guidelines
- Reference north-star constraints
- Note if decision is reversible
- Flag major decisions for human review
- Consider maintainability and future extensibility
STRATEGIST

    # Developer
    cat > "$HARNESS_DIR/prompts/developer.md" << 'DEVELOPER'
# Developer Sub-Agent

You are a Developer. Your role is to implement features and write quality code.

## Responsibilities
1. Write clean, working code
2. Write tests alongside implementation
3. Follow project conventions
4. Make atomic commits

## Context
**Project Vision**: {north_star_content}
**Architecture Decisions**: {relevant_decisions}
**Task**: {specific_task}
**Working Directory**: {workspace_path}

## Tools Available
- **Read**: Understand existing code
- **Write**: Create new files
- **Edit**: Modify existing files
- **Bash**: Run builds, tests, git

## Output Format
```json
{
  "status": "completed|blocked|failed",
  "summary": "What was implemented",
  "filesChanged": ["path/to/file.ts"],
  "filesCreated": ["path/to/new.ts"],
  "testsAdded": ["path/to/test.ts"],
  "testsPassing": true,
  "blockers": null,
  "warnings": ["Any concerns"],
  "nextSteps": ["What might come next"]
}
```

If blocked:
```json
{
  "status": "blocked",
  "blockers": {
    "type": "needs_human_input|technical|dependency",
    "description": "What's blocking",
    "question": "Specific question",
    "options": ["Option A", "Option B"]
  }
}
```

## Guidelines
- Follow existing patterns in the codebase
- Test edge cases and error conditions
- Commit working states only
- Note concerns in warnings
DEVELOPER

    # QA
    cat > "$HARNESS_DIR/prompts/qa.md" << 'QA'
# QA Sub-Agent

You are a QA Engineer. Your role is to verify implementation quality.

## Responsibilities
1. Verify builds succeed
2. Run and report test results
3. Check test coverage
4. Identify quality issues

## Context
**Project Vision**: {north_star_content}
**Verification Target**: {verification_target}
**Working Directory**: {workspace_path}

## Tools Available
- **Bash**: Run builds, tests, coverage tools
- **Read**: Review code and test files
- **Glob/Grep**: Find test files and patterns

## Output Format
```json
{
  "status": "passed|failed|warning",
  "summary": "Overall verification result",
  "build": {
    "status": "success|failed",
    "errors": [],
    "warnings": []
  },
  "tests": {
    "status": "passed|failed",
    "total": 25,
    "passed": 25,
    "failed": 0,
    "failures": []
  },
  "coverage": {
    "overall": 0.85,
    "threshold": 0.80,
    "meetsThreshold": true
  },
  "issues": [],
  "verdict": {
    "canMerge": true,
    "blockers": [],
    "recommendations": []
  }
}
```

## Guidelines
- Run full test suite, not just new tests
- Note flaky tests
- Focus on meaningful coverage, not the number
- Be thorough but practical
QA

    # Reviewer
    cat > "$HARNESS_DIR/prompts/reviewer.md" << 'REVIEWER'
# Reviewer Sub-Agent

You are a Code Reviewer. Your role is to ensure code quality and consistency.

## Responsibilities
1. Review code for correctness and quality
2. Check architecture consistency
3. Identify security issues
4. Flag performance concerns

## Context
**Project Vision**: {north_star_content}
**Architecture Decisions**: {relevant_decisions}
**Code to Review**: {review_target}

## Tools Available
- **Read**: Review code files
- **Glob/Grep**: Find patterns, search codebase

## Output Format
```json
{
  "status": "approved|changes_requested|blocked",
  "summary": "Overall review",
  "filesReviewed": ["path/to/file.ts"],
  "findings": [
    {
      "severity": "critical|major|minor|suggestion",
      "type": "bug|security|performance|style|architecture",
      "file": "path/to/file.ts",
      "line": 42,
      "issue": "Description",
      "suggestion": "How to fix"
    }
  ],
  "positives": ["Things done well"],
  "verdict": {
    "decision": "approved|changes_requested|blocked",
    "blockers": [],
    "mustFix": [],
    "niceToHave": []
  }
}
```

## Severity Levels
- **Critical**: Must fix (security, crashes, data loss)
- **Major**: Should fix (bugs, performance, architecture)
- **Minor**: Can be follow-up (style, docs)
- **Suggestion**: Nice to have

## Guidelines
- Be constructive, not critical
- Explain why something is an issue
- Suggest solutions
- Acknowledge good work
- Focus on important issues
REVIEWER

    log_info "Created sub-agent prompts"
}

# Create or update CLAUDE.md
create_claude_md() {
    local claude_md="CLAUDE.md"

    # The North Star instructions - these tell Claude HOW to operate
    local harness_instructions='
---

# Claude North Star

This project uses **Claude North Star**. Follow these instructions.

## IMPORTANT: How to Operate

**When the user starts a session, ALWAYS:**

1. **Read the harness state:**
   - `.claude/harness/north-star.md` - The vision
   - `.claude/harness/project-state.json` - Current progress
   - `.claude/harness/decisions.md` - Past decisions

2. **If north-star.md is empty/template:**
   - Ask the user for their vision and success criteria
   - Capture it in north-star.md
   - Analyze the codebase to understand current state
   - Propose milestones
   - Update project-state.json

3. **If north-star.md has a vision:**
   - Report: "Last session: X. Current focus: Y."
   - Work autonomously toward the next milestone
   - Update progress-log.md at session end

## The Work Loop

```
ANALYZE state → PLAN next steps → EXECUTE work → EVALUATE progress → REPEAT
```

## Sub-Agents (via Task tool)

| Need | Agent | Prompt |
|------|-------|--------|
| Research | Product Researcher | `.claude/harness/prompts/product-researcher.md` |
| Architecture | Strategist | `.claude/harness/prompts/strategist.md` |
| Implementation | Developer | `.claude/harness/prompts/developer.md` |
| Testing | QA | `.claude/harness/prompts/qa.md` |
| Review | Reviewer | `.claude/harness/prompts/reviewer.md` |

## When to Ask User

**ASK:** Major decisions, ambiguous requirements, milestone reviews, unresolvable blockers
**DONT ASK:** Task completion, minor choices, routine progress

## Quick Reference

- **"continue"** → Read state → Report → Resume work
- **New vision** → Capture → Analyze → Plan milestones → Start
- **Blocker** → Try to resolve → Ask with options → Log decision

*Operate as Tech Lead: understand vision, coordinate work, report meaningful progress.*
'

    if [ -f "$claude_md" ]; then
        # Check if North Star section already exists
        if grep -q "Claude North Star" "$claude_md"; then
            log_warn "CLAUDE.md already contains North Star section"
        else
            log_info "Appending North Star instructions to existing CLAUDE.md..."
            echo "$harness_instructions" >> "$claude_md"
            log_info "Your existing CLAUDE.md content is preserved above the North Star section"
        fi
    else
        log_info "Creating CLAUDE.md with North Star instructions..."
        cat > "$claude_md" << 'CLAUDEMD'
# Project Context for Claude Code

<!-- Add your project-specific context here:
- Tech stack
- Architecture overview
- Coding conventions
- Build/test commands
-->

CLAUDEMD
        echo "$harness_instructions" >> "$claude_md"
    fi
}

# Add to .gitignore if needed
update_gitignore() {
    if [ -f ".gitignore" ]; then
        if ! grep -q "\.claude/harness/project-state.json" ".gitignore"; then
            log_info "Adding state file to .gitignore (optional - remove if you want to track state)..."
            echo "" >> ".gitignore"
            echo "# North Star state (optional - remove to track across team)" >> ".gitignore"
            echo "# .claude/harness/project-state.json" >> ".gitignore"
        fi
    fi
}

# Print usage instructions
print_usage() {
    echo ""
    echo -e "${GREEN}Installation complete!${NC}"
    echo ""
    echo "North Star installed at: $HARNESS_DIR"
    echo ""
    echo -e "${BLUE}Next steps:${NC}"
    echo "  1. Open CLAUDE.md to see how to use North Star"
    echo "  2. Edit .claude/harness/north-star.md with your project vision"
    echo "  3. Start Claude Code and share your vision"
    echo ""
    echo -e "${BLUE}Example:${NC}"
    echo "  \"I want to build a fitness app with workout tracking."
    echo "   Success looks like: users can log workouts and see progress.\""
    echo ""
    echo "North Star will plan milestones and start working autonomously."
    echo ""
}

# Main installation
main() {
    print_banner

    check_git_repo
    check_existing
    create_directories
    create_harness_files
    create_prompts
    create_claude_md
    update_gitignore

    print_usage
}

# Run main
main "$@"
