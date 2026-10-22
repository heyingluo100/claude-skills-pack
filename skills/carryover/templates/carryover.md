---
session: {YYYY-MM-DD}
task: {任务一句话主题}
product: {activeProduct，无则填 "(无)"}
req_id: {REQ-ID，如有；无则删除本字段}
status: {进行中 | 等操作员决策 | 已结束}
created_at: {YYYY-MM-DD HH:MM:SS}
updated_at: {YYYY-MM-DD HH:MM:SS}
next_session_load: 仅 Read 此文件即可恢复，禁止读 .skills/archive/conversations/
---

## 任务是什么

{一句话说清任务目标 + product + REQ-ID（如有）。不是历史，是当前正在做的这一件事。}

例：修复 cloth-recolor 项目 red-circle 检测漏识别问题（REQ-042，product=cloth-recolor）

## 做到哪

### 已完成
1. {步骤 1} → 产物：{绝对路径}
2. {步骤 2} → 产物：{绝对路径}

### 当前进度
{正在做什么，做到哪一步}

## 关键决策

- **{决策 1}**：选了 {方案 A}。原因：{为什么这样选}。事实源：{PRD/plan 绝对路径}
- **{决策 2}**：...

## 下一步

按顺序列出待办（最多 5 项），每项说明产物。

1. {待办 1} → 预期产物：{路径 / 描述}
2. {待办 2}

### 待操作员决策（如有）

> 如无待决，删除本小节

1. {阻塞点 1}：{选项 A vs 选项 B}
2. {阻塞点 2}

## 不要做

- {踩过的坑：例 "不要用 rgb 阈值判断，改用 hsv"}
- {操作员明确否决的方向：例 "不要在 cloth-recolor 项目里搞局部方案"}
- {已废弃的中间方案}
