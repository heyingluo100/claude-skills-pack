---
name: auto-optimize
description: >-
  复杂任务迭代优化工作流：范围锁定 → 多方案探索 → 迭代精炼。
  适用于新功能开发、模块重构、架构调整、跨多个 skill 的全局规则/状态协议/打包同步等需要深度思考的任务。
  简单修改（词库编辑、bug 修复、样式微调）不触发。
metadata:
  priority: 3
  pathPatterns:
    - 'src/analyzer/*.js'
    - 'src/components/*.vue'
    - 'src/composables/*.js'
    - '.claude/skills/*/SKILL.md'
    - 'CLAUDE.md'
  promptSignals:
    phrases:
      - "新功能"
      - "新模块"
      - "新组件"
      - "重构"
      - "重写"
      - "重新设计"
      - "架构"
      - "新增检测"
      - "全局调整"
      - "工作流调整"
      - "状态流"
      - "改多个 skill"
      - "重构 skill"
      - "new feature"
      - "new module"
      - "refactor"
      - "rewrite"
      - "redesign"
      - "overhaul"
      - "workflow"
      - "state flow"
      - "skill workflow"
    anyOf:
      - "检测模块"
      - "分析引擎"
      - "annotation engine"
      - "detection pipeline"
      - "composable"
      - "pipeline"
      - "SKILL.md"
      - "skill-map"
      - "manifest"
      - "pack"
      - "sync"
      - "prompts"
      - "CLAUDE.md"
    noneOf:
      - "词库"
      - "加个词"
      - "加到"
      - "typo"
      - "简单"
      - "quick fix"
      - "小改"
      - "只改一句"
    minScore: 7
---

# 迭代优化工作流

本 Skill 在复杂任务时自动激活。激活后，agent 必须按 **program.md** 执行 3 步工作流。

## 工作流概览

```
Step 1 范围锁定 → Step 2 方案探索(仅复杂任务) → Step 3 迭代精炼
```

| 步骤 | 做什么 | 产出 |
|------|--------|------|
| **1. 范围锁定** | 明确目标、影响文件、成功标准、回归守护 | 对话中的结构化块 |
| **2. 方案探索** | 2-3 个实现策略对比选优（仅 MULTI-APPROACH） | 策略描述 + 选择理由 |
| **3. 迭代精炼** | 每轮改一处、跑验证、打分、commit，最多 4 轮 | 可工作的代码 + git 历史 |

## 快速入口

1. 读 **[program.md](program.md)** — 3 步工作流详细说明
2. 读 **[docs/rules.md](docs/rules.md)** — R1-R4 规则
3. 读 **[docs/scoring.md](docs/scoring.md)** — 评分体系

## 执行要点（必须按此格式产出）

完整模板见 `program.md`，此处是给不读 program.md 也能执行的最小集。

### Step 1 产物：范围锁定块

必写字段：**目标 / 影响文件 / 成功标准（每条都要可测试） / 回归守护 / 复杂度判定 / 既有规则冲突检查 / 最初需求偏离检查 / 多场景成功标准**。

复杂度二选一：
- `MULTI-APPROACH` — 新建模块 / 架构调整 / 3+ 文件重构 / 跨多个 skill / 全局状态流、manifest、打包规则、跨 skill 协议变更 / 多种合理实现 → 进 Step 2
- `SINGLE-PASS` — 路径明确、现有模块扩展、单 skill 改写、无架构决策 → 跳 Step 2，直接 Step 3

**多场景成功标准**至少覆盖：正常 / 缺失 / 冲突 / 失败 / 边界 / 后续 / 保护，不适用项写明原因。

### Step 2 产物：方案对比块（仅 MULTI-APPROACH）

生成 2-3 个方案，每个 5-10 行**只写描述、不写代码**，字段：策略 / 优势 / 劣势 / 影响文件。
末尾输出 `选择：方案 X` + 理由（必须引用 Step 1 的成功标准）。

**一致性检查**：所有方案必须解决同一目标、满足同样成功标准、在现有架构内工作。

每个候选方案还必须说明：
- **多场景处理能力**：正常 / 缺失 / 冲突 / 失败 / 边界 / 后续 / 保护各情况下行为是否清晰
- **既有规则冲突检查**：是否违反 CLAUDE.md 现有规则、双轨主链路、状态协议、打包边界、Skill 独立性原则
- **最初需求偏离检查**：是否仍服务用户原始目标，是否因补细节扩大成用户未要求的大改，是否把规则增强误变成新产品/页面/平台

**跨 skill / 全局规则 / 状态协议 / 打包同步 / 架构变化**类方案，选定方案后、进入 Step 3 前，必须把完整实施方案写入：

```text
docs/pending-plans/YYYYMMDD-HHMM-主题.md
```

方案文档必须包含背景目标、影响范围、具体改动、不改内容、风险保护、验收方式、同步/打包/commit 计划。落盘后等待用户确认；确认前不得修改正式文件、打包或提交。

单 skill / 单文件 / 路径明确的中等改动可跳过 pending-plan 落盘，直接走 Step 3 迭代。

### Step 3 产物：迭代小结块

每轮必写：**改动前分数 / 本轮改动（一句话） / 验证结果 / 改动后分数 / 决策**。
决策二选一：分数涨了 `保留`；跌了 `回滚`。
终止条件：成功标准全满足 → 完成；**4 轮**仍未满足 → 报告剩余问题并询问用户（禁止仅凭自评高分终止，违反 R3）。
每轮 commit 格式：`refine(N): 改动描述 [score: X.X → Y.Y]`

## 规则摘要 (R1-R4)

| 规则 | 核心 |
|------|------|
| **R1 可追溯** | 每轮迭代必须有 git commit |
| **R2 不虚报** | 没跑测试不能说"测试通过" |
| **R3 标准优先** | 成功标准全部满足才算完成，自评高分不够 |
| **R4 环境诚实** | 能跑就跑验证，不能跑就说明 |

详见 **[docs/rules.md](docs/rules.md)**。

## 复杂度判定

Step 1 必须输出复杂度判定：

- **MULTI-APPROACH**：新模块开发、架构调整、涉及 3+ 文件的重构、有多种合理实现路径 → 进入 Step 2
- **SINGLE-PASS**：虽然触发了 Skill 但实际不需要多方案对比 → 跳过 Step 2，直接 Step 3

## 跳过机制

用户在当前消息中明确写出以下任意表述即可跳过：

- `跳过优化` / `简单模式` / `skip optimization` / `simple mode`

agent 禁止自行推断跳过。
