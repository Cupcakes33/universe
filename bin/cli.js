#!/usr/bin/env node

const readline = require('readline');
const fs = require('fs');
const path = require('path');
const os = require('os');

// ─── ANSI Colors ───────────────────────────────────────────
const c = {
  reset: '\x1b[0m',
  bold: '\x1b[1m',
  dim: '\x1b[2m',
  cyan: '\x1b[36m',
  green: '\x1b[32m',
  yellow: '\x1b[33m',
  red: '\x1b[31m',
  magenta: '\x1b[35m',
};

// ─── Paths ─────────────────────────────────────────────────
const TEMPLATES_DIR = path.join(__dirname, '..', 'commands');
const EXECUTE_SH = path.join(__dirname, '..', 'execute.sh');
const GLOBAL_DIR = path.join(os.homedir(), '.claude', 'commands');
const PROJECT_DIR = path.join(process.cwd(), '.claude', 'commands');

// ─── Banner ────────────────────────────────────────────────
function printBanner() {
  console.log('');
  console.log(`${c.bold}${c.cyan}  ┌──────────────────────────────────────────┐${c.reset}`);
  console.log(`${c.bold}${c.cyan}  │          🌌 Universe Installer           │${c.reset}`);
  console.log(`${c.bold}${c.cyan}  │   AI Agent Orchestration for Claude Code  │${c.reset}`);
  console.log(`${c.bold}${c.cyan}  └──────────────────────────────────────────┘${c.reset}`);
  console.log('');
}

// ─── Helpers ───────────────────────────────────────────────
function getCommandFiles() {
  try {
    return fs.readdirSync(TEMPLATES_DIR)
      .filter(f => f.startsWith('universe.') && f.endsWith('.md'))
      .sort();
  } catch {
    console.error(`${c.red}명령어 템플릿 디렉토리를 찾을 수 없습니다: ${TEMPLATES_DIR}${c.reset}`);
    process.exit(1);
  }
}

function ensureDir(dirPath) {
  if (!fs.existsSync(dirPath)) {
    fs.mkdirSync(dirPath, { recursive: true });
  }
}

function copyFile(src, dest, fileName) {
  const destFile = path.join(dest, fileName);
  const exists = fs.existsSync(destFile);

  fs.copyFileSync(src, destFile);

  const status = exists ? `${c.yellow}덮어씀${c.reset}` : `${c.green}새로 생성${c.reset}`;
  console.log(`  ${c.dim}→${c.reset} ${fileName} ${status}`);
}

function installCommands(targetDir, label) {
  const files = getCommandFiles();

  console.log('');
  console.log(`${c.bold}📦 ${label}에 명령어 설치 중...${c.reset}`);
  console.log(`   ${c.dim}${targetDir}${c.reset}`);

  ensureDir(targetDir);

  for (const file of files) {
    copyFile(path.join(TEMPLATES_DIR, file), targetDir, file);
  }

  console.log(`${c.green}   ✅ ${files.length}개 명령어 설치 완료${c.reset}`);
}

function installExecuteSh() {
  const dest = path.join(process.cwd(), 'execute.sh');
  const exists = fs.existsSync(dest);

  console.log('');
  console.log(`${c.bold}📦 execute.sh 설치 중...${c.reset}`);
  console.log(`   ${c.dim}${dest}${c.reset}`);

  fs.copyFileSync(EXECUTE_SH, dest);
  fs.chmodSync(dest, 0o755);

  const status = exists ? `${c.yellow}덮어씀${c.reset}` : `${c.green}새로 생성${c.reset}`;
  console.log(`  ${c.dim}→${c.reset} execute.sh ${status}`);
  console.log(`${c.green}   ✅ execute.sh 설치 완료 (chmod +x)${c.reset}`);
}

function printSuccess(choice) {
  console.log('');
  console.log(`${c.bold}${c.green}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${c.reset}`);
  console.log(`${c.bold}${c.green}  🎉 Universe 설치 완료!${c.reset}`);
  console.log(`${c.bold}${c.green}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${c.reset}`);
  console.log('');
  console.log(`${c.bold}사용법:${c.reset}`);
  console.log(`  ${c.cyan}/universe.1-research project "프로젝트 설명"${c.reset}`);
  console.log(`  ${c.cyan}/universe.1-research feature "기능 설명"${c.reset}`);
  console.log('');
  console.log(`${c.bold}워크플로우:${c.reset}`);
  console.log(`  ${c.dim}1.${c.reset} /universe.1-research  → 도메인 리서치`);
  console.log(`  ${c.dim}2.${c.reset} /universe.2-design    → 설계 (사용자와 1:1)`);
  console.log(`  ${c.dim}3.${c.reset} /universe.3-blueprint → 아키텍처`);
  console.log(`  ${c.dim}4.${c.reset} /universe.4-decompose → Task 분해`);
  console.log(`  ${c.dim}5.${c.reset} ./execute.sh          → 자동 실행`);
  console.log(`  ${c.dim}6.${c.reset} /universe.6-sync      → 문서 동기화`);
  console.log(`  ${c.dim}7.${c.reset} /universe.7-status    → 진행 확인`);
  console.log('');

  if (choice === '1' || choice === '3') {
    console.log(`${c.dim}글로벌 설치: 모든 프로젝트에서 /universe.* 사용 가능${c.reset}`);
  }
  if (choice === '2' || choice === '3') {
    console.log(`${c.dim}프로젝트 설치: 현재 디렉토리에서만 /universe.* 사용 가능${c.reset}`);
  }

  console.log('');
}

// ─── CLI Argument Parsing ──────────────────────────────────
function parseArgs() {
  const args = process.argv.slice(2);

  if (args.includes('--help') || args.includes('-h')) {
    console.log('');
    console.log('사용법: npx create-universe [옵션]');
    console.log('');
    console.log('옵션:');
    console.log('  --global, -g     글로벌 설치 (~/.claude/commands/)');
    console.log('  --project, -p    프로젝트 설치 (./.claude/commands/)');
    console.log('  --both, -b       글로벌 + 프로젝트 둘 다');
    console.log('  --no-execute     execute.sh 복사하지 않음');
    console.log('  --help, -h       도움말');
    console.log('');
    process.exit(0);
  }

  let choice = null;
  let skipExecute = false;

  if (args.includes('--global') || args.includes('-g')) choice = '1';
  if (args.includes('--project') || args.includes('-p')) choice = '2';
  if (args.includes('--both') || args.includes('-b')) choice = '3';
  if (args.includes('--no-execute')) skipExecute = true;

  return { choice, skipExecute };
}

// ─── Interactive Prompt ────────────────────────────────────
function prompt(question) {
  const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout,
  });

  return new Promise((resolve) => {
    rl.question(question, (answer) => {
      rl.close();
      resolve(answer.trim());
    });
  });
}

// ─── Main ──────────────────────────────────────────────────
async function main() {
  printBanner();

  const { choice: argChoice, skipExecute } = parseArgs();
  let choice = argChoice;

  // Interactive mode
  if (!choice) {
    console.log(`${c.bold}설치 경로를 선택해주세요:${c.reset}`);
    console.log('');
    console.log(`  ${c.cyan}1)${c.reset} ${c.bold}글로벌${c.reset}       ${c.dim}~/.claude/commands/${c.reset}`);
    console.log(`     모든 프로젝트에서 /universe.* 명령어를 사용할 수 있습니다`);
    console.log('');
    console.log(`  ${c.cyan}2)${c.reset} ${c.bold}프로젝트${c.reset}     ${c.dim}./.claude/commands/${c.reset}`);
    console.log(`     현재 디렉토리의 프로젝트에서만 사용할 수 있습니다`);
    console.log('');
    console.log(`  ${c.cyan}3)${c.reset} ${c.bold}둘 다${c.reset}`);
    console.log(`     글로벌 + 프로젝트 모두 설치합니다`);
    console.log('');

    choice = await prompt(`${c.bold}선택 (1/2/3): ${c.reset}`);
  }

  if (!['1', '2', '3'].includes(choice)) {
    console.log(`${c.red}잘못된 선택입니다. 1, 2, 3 중 하나를 입력해주세요.${c.reset}`);
    process.exit(1);
  }

  // Install commands
  if (choice === '1' || choice === '3') {
    installCommands(GLOBAL_DIR, '글로벌');
  }
  if (choice === '2' || choice === '3') {
    installCommands(PROJECT_DIR, '프로젝트');
  }

  // Install execute.sh
  if (!skipExecute) {
    installExecuteSh();
  }

  printSuccess(choice);
}

main().catch((err) => {
  console.error(`${c.red}오류 발생: ${err.message}${c.reset}`);
  process.exit(1);
});
