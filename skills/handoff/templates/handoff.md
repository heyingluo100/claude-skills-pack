---
session: {YYYY-MM-DD}
topic: {一句话主题，便于 list 时扫描}
status: {进行中 | 等操作员决策 | 已结束}
product: {activeProduct，无则填 "(无)"}
next_session_load: 仅 Read 此文件即可恢复，禁止读 .skills/archive/conversations/
---

## 当前任务

{一句话说清这个会话在做什么。不是历史，是现在。}

## 已确认的事实

- {带文件路径或具体数值，不要"应该是"、"大概"}
- {例：sync.bat L37 SKILLS 列表只有 11 个，实际 .claude/skills/ 有 18 个}
- {例：cloth-recolor 当前 round1 plan.json 仍是旧版，未应用红圈修正}

## 已完成的步骤

1. {步骤一} → 产物：{绝对路径}
2. {步骤二} → 产物：{绝对路径}

## 待操作员决策（阻塞下一步）

> 如无待决，写"无待决，可继续执行"

1. {阻塞点 1}：{选项 A vs 选项 B}
2. {阻塞点 2}

## 关键决策（含原因）

- **{决策 1}**：{选了什么}。原因：{为什么这样选，引用了哪条规则或哪句对话}
- **{决策 2}**：...

## 下一步要做的事

按顺序列出待办（最多 5 项），每项说明产物。

1. {待办 1} → 预期产物
2. {待办 2}

## 不要做的事

- {刚踩过的坑：例 "不要再用 Read 读 conversation export，改用 Grep"}
- {操作员明确否决的方向：例 "不要在 cloth-recolor 项目里搞局部方案，要走全局"}
- {已废弃的中间方案}

## 引用的事实源

> 列出 handoff 引用了哪些事实文件，方便下个会话快速 Read

- `D:\批量改色\.skills\cloth-recolor\docs\plan.md`
- `E:\skills-chage\CLAUDE.md`
- ...
