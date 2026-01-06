#!/usr/bin/env node

const fs = require('fs');
const path = require('path');

const HARNESS_DIR = '.claude/harness';
const TEMPLATES_DIR = path.join(__dirname, '..', 'templates');

// Colors
const colors = {
  green: (s) => `\x1b[32m${s}\x1b[0m`,
  yellow: (s) => `\x1b[33m${s}\x1b[0m`,
  blue: (s) => `\x1b[34m${s}\x1b[0m`,
  red: (s) => `\x1b[31m${s}\x1b[0m`,
  dim: (s) => `\x1b[2m${s}\x1b[0m`,
};

const log = {
  info: (msg) => console.log(`${colors.green('✓')} ${msg}`),
  warn: (msg) => console.log(`${colors.yellow('!')} ${msg}`),
  error: (msg) => console.log(`${colors.red('✗')} ${msg}`),
};

function printBanner() {
  console.log('');
  console.log(colors.blue('╔═══════════════════════════════════════════════════════════╗'));
  console.log(colors.blue('║') + '     ' + colors.green('Claude North Star') + '                      ' + colors.blue('║'));
  console.log(colors.blue('║') + '     Transform CLI agents into autonomous partners        ' + colors.blue('║'));
  console.log(colors.blue('╚═══════════════════════════════════════════════════════════╝'));
  console.log('');
}

function printHelp() {
  console.log(`
${colors.blue('Usage:')} npx claude-northstar <command>

  ${colors.blue('Commands:')}
  init        Install North Star in current directory
  uninstall   Remove North Star from current directory
  status      Check North Star installation status

${colors.blue('Examples:')}
  npx claude-northstar init          # Install in current project
  npx claude-northstar uninstall     # Remove harness

${colors.blue('More info:')} https://github.com/nisarg38/claude-northstar
`);
}

function copyDir(src, dest) {
  fs.mkdirSync(dest, { recursive: true });
  const entries = fs.readdirSync(src, { withFileTypes: true });

  for (const entry of entries) {
    const srcPath = path.join(src, entry.name);
    const destPath = path.join(dest, entry.name);

    if (entry.isDirectory()) {
      copyDir(srcPath, destPath);
    } else {
      fs.copyFileSync(srcPath, destPath);
    }
  }
}

function init() {
  printBanner();

  // Check if already installed
  if (fs.existsSync(HARNESS_DIR)) {
    log.warn(`North Star already installed at ${HARNESS_DIR}`);
    console.log('');
    console.log('To reinstall, run: npx claude-northstar uninstall && npx claude-northstar init');
    return;
  }

  // Check for git repo (optional)
  if (!fs.existsSync('.git')) {
    log.warn('Not a git repository. North Star works best with version control.');
  }

  // Create harness directory and copy templates
  log.info('Creating North Star directory...');
  copyDir(TEMPLATES_DIR, HARNESS_DIR);

  // Handle CLAUDE.md
  updateClaudeMd();

  // Print success
  console.log('');
  console.log(colors.green('Installation complete!'));
  console.log('');
  console.log(`North Star installed at: ${colors.blue(HARNESS_DIR)}`);
  console.log('');
  console.log(colors.blue('Next steps:'));
  console.log('  1. Start Claude Code in this directory');
  console.log('  2. Share your vision: "I want to build [your idea]"');
  console.log('  3. North Star will capture it and work autonomously');
  console.log('');
  console.log(colors.dim('Or say "continue" to resume from where you left off.'));
  console.log('');
}

function updateClaudeMd() {
  const claudeMd = 'CLAUDE.md';
  const harnessInstructions = `
---

# Claude North Star

This project uses **Claude North Star**. Follow these instructions.

## IMPORTANT: How to Operate

**When the user starts a session, ALWAYS:**

1. **Read the harness state:**
   - \`.claude/harness/north-star.md\` - The vision
   - \`.claude/harness/project-state.json\` - Current progress
   - \`.claude/harness/decisions.md\` - Past decisions

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

\`\`\`
ANALYZE state → PLAN next steps → EXECUTE work → EVALUATE progress → REPEAT
\`\`\`

## Sub-Agents (via Task tool)

| Need | Agent | Prompt |
|------|-------|--------|
| Research | Product Researcher | \`.claude/harness/prompts/product-researcher.md\` |
| Architecture | Strategist | \`.claude/harness/prompts/strategist.md\` |
| Implementation | Developer | \`.claude/harness/prompts/developer.md\` |
| Testing | QA | \`.claude/harness/prompts/qa.md\` |
| Review | Reviewer | \`.claude/harness/prompts/reviewer.md\` |

## When to Ask User

**ASK:** Major decisions, ambiguous requirements, milestone reviews, unresolvable blockers
**DON'T ASK:** Task completion, minor choices, routine progress

## Quick Reference

- **"continue"** → Read state → Report → Resume work
- **New vision** → Capture → Analyze → Plan milestones → Start
- **Blocker** → Try to resolve → Ask with options → Log decision

*Operate as Tech Lead: understand vision, coordinate work, report meaningful progress.*
`;

  if (fs.existsSync(claudeMd)) {
    const content = fs.readFileSync(claudeMd, 'utf8');
    if (content.includes('Claude North Star')) {
      log.warn('CLAUDE.md already contains North Star section');
    } else {
      log.info('Appending harness instructions to existing CLAUDE.md...');
      fs.appendFileSync(claudeMd, harnessInstructions);
      log.info('Your existing CLAUDE.md content is preserved');
    }
  } else {
    log.info('Creating CLAUDE.md...');
    const newContent = `# Project Context for Claude Code

<!-- Add your project-specific context here:
- Tech stack
- Architecture overview
- Coding conventions
- Build/test commands
-->
${harnessInstructions}`;
    fs.writeFileSync(claudeMd, newContent);
  }
}

function uninstall() {
  printBanner();

  if (!fs.existsSync(HARNESS_DIR)) {
    log.error(`North Star not found at ${HARNESS_DIR}`);
    return;
  }

  log.info(`Removing ${HARNESS_DIR}...`);
  fs.rmSync(HARNESS_DIR, { recursive: true, force: true });

  // Clean up empty .claude dir
  if (fs.existsSync('.claude') && fs.readdirSync('.claude').length === 0) {
    fs.rmdirSync('.claude');
  }

  console.log('');
  console.log(colors.green('North Star uninstalled.'));
  console.log('');
  console.log(colors.dim('Note: CLAUDE.md was not modified. Remove North Star section manually if desired.'));
  console.log('');
}

function status() {
  printBanner();

  const installed = fs.existsSync(HARNESS_DIR);

  if (installed) {
    console.log(`Status: ${colors.green('Installed')}`);
    console.log(`Location: ${HARNESS_DIR}`);
    console.log('');

    // Check state
    const northStar = path.join(HARNESS_DIR, 'north-star.md');
    const projectState = path.join(HARNESS_DIR, 'project-state.json');

    if (fs.existsSync(northStar)) {
      const content = fs.readFileSync(northStar, 'utf8');
      const hasVision = !content.includes('<!-- What are you building?');
      console.log(`Vision: ${hasVision ? colors.green('Defined') : colors.yellow('Not set')}`);
    }

    if (fs.existsSync(projectState)) {
      try {
        const state = JSON.parse(fs.readFileSync(projectState, 'utf8'));
        const milestones = state.milestones?.length || 0;
        const completed = state.milestones?.filter(m => m.status === 'done').length || 0;
        console.log(`Milestones: ${completed}/${milestones} completed`);
      } catch (e) {
        // Ignore parse errors
      }
    }
  } else {
    console.log(`Status: ${colors.yellow('Not installed')}`);
    console.log('');
    console.log(`Run ${colors.blue('npx claude-northstar init')} to install.`);
  }
  console.log('');
}

// Main
const args = process.argv.slice(2);
const command = args[0];

switch (command) {
  case 'init':
  case undefined:
    init();
    break;
  case 'uninstall':
  case 'remove':
    uninstall();
    break;
  case 'status':
    status();
    break;
  case '--help':
  case '-h':
  case 'help':
    printHelp();
    break;
  default:
    log.error(`Unknown command: ${command}`);
    printHelp();
    process.exit(1);
}
