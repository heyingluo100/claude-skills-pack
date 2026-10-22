#!/usr/bin/env node
/**
 * carryover SessionStart hook
 *
 * 检测当前项目是否存在 carryover 任务卡，命中则输出通知供 Claude 主动 load。
 * 无卡时静默退出，不干扰会话启动。
 *
 * 输入：无参数，从进程 cwd 读项目根
 * 输出：命中卡时输出结构化文本到 stdout；无卡时无输出
 * 退出码：始终 0（不因无卡或异常阻塞会话）
 */

const fs = require('fs');
const path = require('path');

const START_TS = Date.now();
const MAX_MS = 200;

function safeExit(code = 0) {
  process.exit(code);
}

function log(msg) {
  process.stdout.write(msg + '\n');
}

function readJsonSafe(filePath) {
  try {
    const raw = fs.readFileSync(filePath, 'utf8');
    return JSON.parse(raw);
  } catch (_) {
    return null;
  }
}

function readFrontmatter(mdPath) {
  try {
    const raw = fs.readFileSync(mdPath, 'utf8');
    const m = raw.match(/^---\r?\n([\s\S]*?)\r?\n---/);
    if (!m) return {};
    const fm = {};
    m[1].split(/\r?\n/).forEach(line => {
      const kv = line.match(/^([a-zA-Z_][\w-]*)\s*:\s*(.*)$/);
      if (kv) fm[kv[1]] = kv[2].trim();
    });
    return fm;
  } catch (_) {
    return {};
  }
}

function listCards(dir) {
  try {
    if (!fs.existsSync(dir)) return [];
    return fs
      .readdirSync(dir)
      .filter(name => name.endsWith('.md') && !name.startsWith('.'))
      .map(name => path.join(dir, name))
      .filter(p => {
        try {
          return fs.statSync(p).isFile();
        } catch (_) {
          return false;
        }
      });
  } catch (_) {
    return [];
  }
}

function pickLatest(cards) {
  if (cards.length === 0) return null;
  return cards.sort().reverse()[0];
}

function daysBetween(dateStr) {
  if (!dateStr) return null;
  const then = new Date(dateStr);
  if (isNaN(then.getTime())) return null;
  return Math.floor((Date.now() - then.getTime()) / (1000 * 60 * 60 * 24));
}

function main() {
  const cwd = process.cwd();
  const skillsRoot = path.join(cwd, '.skills');

  if (!fs.existsSync(skillsRoot)) safeExit(0);

  const ctxPath = path.join(skillsRoot, 'context.json');
  const ctx = readJsonSafe(ctxPath);
  const activeProduct = ctx && ctx.activeProduct;

  const candidates = [];
  if (activeProduct) {
    candidates.push(path.join(skillsRoot, activeProduct, 'carryover'));
  }
  candidates.push(path.join(skillsRoot, 'carryover'));

  let cards = [];
  let hitDir = null;
  for (const dir of candidates) {
    const found = listCards(dir);
    if (found.length > 0) {
      cards = found;
      hitDir = dir;
      break;
    }
  }

  if (Date.now() - START_TS > MAX_MS) safeExit(0);

  const latest = pickLatest(cards);
  if (!latest) safeExit(0);

  const fm = readFrontmatter(latest);
  const status = fm.status || '进行中';
  const task = fm.task || '(未填写)';
  const product = fm.product || activeProduct || '(无)';
  const ageDays = daysBetween(fm.updated_at || fm.created_at || fm.session);

  const lines = [];
  lines.push('[carryover] 检测到任务续接卡');
  lines.push(`路径：${latest}`);
  lines.push(`任务：${task}`);
  lines.push(`Product：${product}`);
  lines.push(`状态：${status}`);
  if (ageDays !== null) {
    const label = ageDays <= 0 ? '今日' : `${ageDays} 天前`;
    lines.push(`最近更新：${label}`);
  }
  lines.push('');
  if (status === '已结束') {
    lines.push('建议：卡状态是"已结束"，不自动 load，询问操作员是开新任务还是回顾这份。');
  } else if (ageDays !== null && ageDays > 7) {
    lines.push('建议：卡超过 7 天未更新，询问操作员是否续做，不自动 load。');
  } else {
    lines.push('建议：Claude 主动 Read 此文件并向操作员汇报 topic + 下一步，等确认后续做。');
  }

  log(lines.join('\n'));
  safeExit(0);
}

try {
  main();
} catch (_) {
  safeExit(0);
}
