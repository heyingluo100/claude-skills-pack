---
name: eval-skill
description: Skill 实证评估与回归复测。用于验证某项 Skill 在同类任务中是否更稳定、更少绕路、更可复测,并用任务集、trace、metrics 和归因报告为下一版优化提供依据。
version: 1.0.0
status: active
---

# /eval-skill — Skill 实证评估

## 定位

`/eval-skill` 验证一项 Skill 在任务中的真实效果,而不是只评价 `SKILL.md` 写得好不好。

负责:

- 为目标 Skill 建立或复用边界清楚的任务集。
- 比较 baseline、with_skill、旧版 Skill 和新版 Skill 的表现。
- 记录 trace 摘要和 metrics。
- 输出可归因的评估报告和回归复测结论。
- 给 `/darwin-skill` 或人工修改提供下一版依据。

不负责:

- 不自动修改被评估 Skill 的 `SKILL.md`。
- 不替代 `/darwin-skill` 的文档评分和优化循环。
- 不替代 `/review` 的 PRD/plan/skill-map 覆盖验收。
- 不替代 `/health` 的全局体系体检。
- 不做长期后台服务、队列、dashboard 或外部 benchmark 平台。

## 触发条件

主动调用为主:

- 用户明确使用 `/eval-skill`。
- 用户要求"评估某个 skill 是否真的有效""做有无 Skill 对照""trace/metrics""回归复测""下一版修改依据"。
- 用户要求比较旧版/新版 Skill、baseline/with_skill 的任务表现。

被动建议触发为辅:

- `/darwin-skill` 已优化核心或高风险 Skill,但缺少实证评估证据。
- `/review` 发现目标 Skill 虽然覆盖需求,但缺少可复测的任务表现材料。
- 新 Skill 准备进入分发包,且属于高频、编排型、安全边界强或容易绕路的能力。

不触发:

- 单个文案、配置或路径调整。
- 只需要 `/review` 检查需求覆盖。
- 只需要 `/health` 检查项目一致性。
- 没有明确目标 Skill,且用户只是在泛泛讨论方法论。

## 输入

可接受自然语言或参数:

```text
/eval-skill create-skill
/eval-skill review --taskset smoke
/eval-skill darwin-skill --compare baseline
/eval-skill pack --regression
评估一下 create-skill 在同类任务里是否更稳定
用任务集复测 review 的触发和执行路径
```

关键输入:

- `skillName`:目标 Skill 名称或目录。
- `taskset`:任务集名称,默认 `smoke`。
- `mode`:`baseline`、`with_skill`、`compare`、`regression`。
- `runMode`:`full_run`、`dry_run`、`manual_trace`。
- `focus`:`trigger`、`path`、`tools`、`safety`、`output`、`regression`。

## 模式选择

未显式指定模式时,按用户目标选择:

| 用户目标 | 默认模式 | 说明 |
|---|---|---|
| 第一次评估某个 Skill | `baseline` | 建立初始任务集和初始表现,不声称改进 |
| 验证当前 Skill 是否有效 | `with_skill` | 记录当前 Skill 参与后的表现 |
| 比较有无 Skill 或旧版/新版 | `compare` | 必须有 baseline;没有则先建立 baseline |
| 看新版有没有退化 | `regression` | 必须复用同一任务集;任务集变化时不能宣称可比 |
| 用户只说"好不好用" | 先澄清目标 Skill | 不做泛泛评分 |

`runMode` 判定:

- 能真实运行任务并记录执行路径时,使用 `full_run`。
- 不能真实禁用/强制启用 Skill,但能根据规则做可解释推演时,使用 `dry_run`。
- 需要用户或外部记录补充 trace 时,使用 `manual_trace`。

`dry_run` 和 `manual_trace` 可以发现问题,但不能单独作为"稳定有效"的结论。

## 输出

默认写入当前项目内:

```text
.claude/skills/eval-skill/artifacts/{target-skill}/
```

建议结构:

```text
.claude/skills/eval-skill/artifacts/{target-skill}/
├── tasksets/
│   └── {taskset}.json
├── runs/
│   └── {YYYYMMDD-HHMM}-{mode}.json
├── metrics/
│   └── {YYYYMMDD-HHMM}.json
└── reports/
    ├── eval-{YYYYMMDD-HHMM}.md
    └── regression-{YYYYMMDD-HHMM}.md
```

如存在 `.skills/context.json` 和 activeProduct,并且评估与当前产品交付相关,可额外写入摘要:

```text
.skills/{product}/docs/eval-{target-skill}-{YYYYMMDD-HHMM}.md
```

不得写入 `C:\`、`C:\tmp`、`C:\temp`、桌面、下载目录、全局安装目录或其他项目外路径。

## 执行流程

### 第 0 步:范围摸底

1. 扫描 `.claude/skills/*/SKILL.md`,确认目标 Skill 是否存在。
2. 读取目标 `SKILL.md`,理解它的定位、触发条件、输入输出、流程和边界。
3. 检查 `.claude/skills/{target}/test-prompts.json` 是否存在。
4. 检查是否存在 `.claude/skills/eval-skill/artifacts/{target}/tasksets/{taskset}.json`。
5. 如存在 `.skills/context.json`,读取 activeProduct;缺失时不阻塞。
6. 输出评估范围:目标 Skill、任务集、模式、运行方式、写入路径。

### 第 1 步:建立任务集

如果已有任务集:

- 读取并检查是否仍匹配目标 Skill 当前用途。
- 如不匹配,标记为过期,提出更新建议,等用户确认后再改任务集。

如果没有任务集:

- 优先从 `.claude/skills/{target}/test-prompts.json` 转换。
- 若没有测试 prompt,则基于目标 `SKILL.md` 设计 3-8 个任务。
- 至少覆盖 happy path、轻微歧义、失败/缺失、边界或安全场景。
- 展示任务集摘要,等用户确认后写入。

任务集写入前必须展示:

- 任务数量、覆盖场景和难度分布。
- 每个任务的 `must` 与 `must_not`。
- 哪些任务用于 baseline,哪些任务用于 regression。
- 是否来自 `test-prompts.json` 转换,或由本次新生成。

任务集格式:

```json
{
  "skill": "create-skill",
  "taskset": "smoke",
  "version": "v1",
  "tasks": [
    {
      "id": "TASK-001",
      "prompt": "创建一个轻量单 skill,用于整理会议纪要",
      "expected": {
        "must": ["读取本地规则", "生成 SKILL.md", "写入项目内路径"],
        "must_not": ["写入 C:\\\\", "跳过确认规则"]
      },
      "focus": ["trigger", "path", "safety"],
      "difficulty": "normal"
    }
  ]
}
```

### 第 2 步:选择对照方式

按目标选择一种或多种:

| 模式 | 用途 |
|---|---|
| `baseline` | 记录无 Skill 或旧行为的初始表现 |
| `with_skill` | 记录当前 Skill 参与后的表现 |
| `compare` | 对比 baseline 与 with_skill |
| `regression` | 用同一任务集复测新版是否稳定 |

如果当前环境无法真实禁用或强制启用 Skill,必须标注限制,并使用 `dry_run` 或 `manual_trace`,不能虚报为完整实测。

对照开始前必须输出:

```text
[EVAL-SKILL] 评估计划
目标 Skill:...
任务集:...
模式:baseline / with_skill / compare / regression
运行方式:full_run / dry_run / manual_trace
写入路径:...
可比性限制:...
```

用户已明确要求执行评估时可以继续;如果计划包含新增任务集、覆盖既有任务集、写入产品级 `.skills/{product}/docs/` 摘要,必须先等用户确认。

### 第 3 步:记录 trace 摘要

每个任务都要记录最小可用 trace:

```json
{
  "task_id": "TASK-001",
  "mode": "with_skill",
  "run_mode": "dry_run",
  "triggered_skill": true,
  "steps": 7,
  "tool_calls": 4,
  "file_edits": 1,
  "fallbacks": 0,
  "errors": 0,
  "risky_actions": [],
  "detours": [
    {
      "type": "unneeded_scan",
      "evidence": "scanned unrelated docs"
    }
  ],
  "result": "pass",
  "notes": "路径和确认规则符合预期"
}
```

trace 只记录执行路径证据,不记录 token、密钥、登录缓存、隐私数据或完整敏感输出。

### 第 4 步:统计 metrics

至少统计:

- `trigger_rate`:应触发时实际触发比例。
- `completion_rate`:任务完成比例。
- `quality_pass_rate`:输出满足 expected.must 的比例。
- `detour_rate`:出现明显绕路的比例。
- `fallback_rate`:出现 fallback 的比例。
- `risky_action_rate`:出现危险动作的比例。
- `regression_pass_rate`:回归任务通过比例。

示例:

```json
{
  "skill": "create-skill",
  "taskset": "smoke",
  "runs": 10,
  "trigger_rate": 0.9,
  "completion_rate": 0.8,
  "quality_pass_rate": 0.8,
  "detour_rate": 0.2,
  "fallback_rate": 0.1,
  "risky_action_rate": 0,
  "regression_pass_rate": 0.8
}
```

### 第 4.5 步:判定结论

按以下规则给出结论,不能只凭主观印象:

| 结论 | 条件 |
|---|---|
| `通过` | `completion_rate`、`quality_pass_rate` 均不低于 0.8,`risky_action_rate` 为 0,且关键任务无阻断失败 |
| `退化` | 新版相比 baseline 或上一轮在完成率、质量通过率、绕路率、安全风险任一关键指标明显变差 |
| `不确定` | 任务数不足、只有 `dry_run/manual_trace`、缺 baseline、任务集变化或证据不足 |
| `阻断` | 目标 Skill 不存在、任务集不可判定、写入路径不安全或发现敏感信息风险 |

`compare` 模式必须同时说明:

- 哪些指标改善。
- 哪些指标持平。
- 哪些指标退化。
- 是否达到"更稳定、更少绕路、更可复测"的目标。

`regression` 模式必须说明任务集是否完全一致;不一致时只能输出"不可比"或"不确定"。

### 第 5 步:归因分析

按问题类型归因:

| 类型 | 判断 |
|---|---|
| 入口问题 | name、description、关键词或触发说明导致 Skill 未进入上下文 |
| 边界问题 | Skill 职责太宽、太窄或与其他 Skill 重叠 |
| 执行问题 | 流程、步骤、脚本、命令发现或确认点导致绕路或失败 |
| 观测问题 | 缺少可记录证据,无法解释成功或失败 |
| 安全问题 | 危险命令、敏感路径、项目外写入或未确认覆盖 |
| 稳定性问题 | 同任务集复测结果波动大或新版退化 |
| 任务集问题 | 任务样本不代表真实场景,或 expected 不可判定 |

每条结论必须指向证据:

```text
依据:TASK-003 / runs/20260615-1030-with_skill.json / detour_rate=0.4
```

### 第 6 步:输出报告

报告写入:

```text
.claude/skills/eval-skill/artifacts/{target}/reports/eval-{YYYYMMDD-HHMM}.md
```

报告结构:

```markdown
# Skill 评估报告:{target}

## 总览
- 任务集:
- 模式:
- 运行方式:
- 结论:通过 / 退化 / 不确定

## 指标
| 指标 | 数值 | 判断 |
|---|---:|---|

## 任务结果
| 任务 | baseline | with_skill | 结论 | 证据 |
|---|---|---|---|---|

## 归因
- ...

## 下一版修改依据
- 建议修改:
- 证据:
- 建议转入:
```

### 第 7 步:转入后续流程

根据结论建议流转:

- 文档触发或流程问题:转 `/darwin-skill`。
- 需求边界或 skill 拆分问题:转 `/plan`。
- 交付覆盖问题:转 `/review`。
- 分发边界问题:转 `/pack`。
- 体系一致性问题:转 `/health`。

`/eval-skill` 不直接推进 `skill-map.md` 的 `created/optimized/reviewed/packed` 状态。

## 规则与约束

- 每次评估默认只针对一个目标 Skill,避免归因混乱。
- 不把一次成功当成稳定结论。
- 不在缺少任务集或对照时声称"Skill 有效"。
- 不在任务集变化时声称新版优于旧版。
- `dry_run`、`manual_trace` 和 `full_run` 必须明确标注。
- 不自动修改目标 Skill;修改交给 `/darwin-skill` 或用户确认后的专门改动。
- 不引入未确认的新依赖。
- 不读取或输出密钥、token、登录缓存、`.env`、credentials、`~/.ssh/`。
- artifacts 默认是评估产物,不应进入 zip;若打包规则不排除,必须提示 `/pack` 检查。

## 错误处理

| 场景 | 处理 |
|---|---|
| 目标 Skill 不存在 | 终止,提示先 `/create-skill` 或确认名称 |
| 同名 Skill 多个 | 停止,让用户确认目标路径 |
| 缺任务集 | 从 `test-prompts.json` 转换或生成待确认任务集 |
| 缺 `test-prompts.json` | 基于目标 `SKILL.md` 生成初版任务集,但需用户确认 |
| 缺 activeProduct | 不阻塞,只写入 `.claude/skills/eval-skill/artifacts/{target}/...` |
| 无法真实对照 | 降级为 `dry_run` 或 `manual_trace` 并标注限制 |
| 工具或联网失败 | 记录失败 trace,不虚报完整实测 |
| 报告写入失败 | 停止并说明具体路径和错误 |
| 发现安全风险 | 报告风险,建议转 `/darwin-skill` 或人工修正 |

## 与其他 Skill 的协作

- 上游:`/create-skill`、`/darwin-skill`。
- 下游:`/darwin-skill`、`/plan`、`/review`、`/pack`、`/health`。
- 读取:
  - `.claude/skills/{target}/SKILL.md`
  - `.claude/skills/{target}/test-prompts.json`
  - `.claude/skills/eval-skill/artifacts/{target}/tasksets/*.json`
  - `.skills/context.json`(如存在)
- 写入:
  - `.claude/skills/eval-skill/artifacts/{target}/...`
  - `.skills/{product}/docs/eval-{target}-{timestamp}.md`(仅当存在 activeProduct 且与产品交付相关)

## 多场景处理摘要

- 正常情况:目标 Skill、任务集和对照模式明确,输出 trace、metrics 和报告。
- 缺失情况:缺任务集则生成待确认任务集;缺 activeProduct 不阻塞。
- 冲突情况:同名或任务集过期时停止或要求确认。
- 失败情况:自动运行失败保留失败 trace,不能虚报通过。
- 边界情况:不替代 `/darwin-skill`、`/review`、`/health`,不做 dashboard。
- 后续情况:按归因建议流转到对应 skill。
- 保护情况:不写项目外路径,不记录敏感信息,不自动修改目标 Skill。
