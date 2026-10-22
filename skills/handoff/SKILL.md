---
name: handoff
description: 会话交接卡管理（save/load/list/status）。触发词：交接、handoff、会话快爆了、context 不够了、暂停一下、待会儿继续、明天再做、新会话、新开会话续接，以及新会话开头的"继续昨天/上次/之前的工作"、"接着干"、"刚才做到哪了"——这些开局自然语言也是 load 触发点。把当前任务状态压缩成 200-800 字结构化 md，替代直接 Read 完整 conversation export。
argument-hint: "[save|load|list|status]"
allowed-tools: Read Write Edit Glob Grep Bash
version: 1.1.0
status: active
---

# /handoff — 会话交接卡

## 一、定位与职责

**是什么**：跨会话续接的轻量载体。会话快爆 context 时写一份 200-500 字结构化 md，新会话只 Read 这一份就能恢复，不再 Read 几十 KB 的 conversation export。

**解决的核心问题**：
- 用户用 `/export` 产出的完整 txt 当交接载体 → 文件 90% 是终端 UI 噪音、tool 调用结果
- 一份 88 KB 的 export 灌进新会话约占 20 K tokens，刚开局就把上下文吃掉 30%+
- export 没结构、找不到关键决策、看不到操作员当时的待回应事项

**在三层载体中的位置**：

| 载体 | 寿命 | 内容 | 写入方 | 读取方 |
|------|------|------|--------|--------|
| `memory/*.md` | 跨项目永久 | 长期偏好、事实快照 | 操作员对话中触发 | 每次会话开头 |
| `.skills/session.json` | 当前任务 | 机器可读的 /dev 任务断点 | `/dev start\|done\|abandon` | `/dev`（新会话恢复） |
| **`.skills/{product}/handoff/{时间}.md`** | **当前会话** | **人类可读的任务交接卡** | **`/handoff save`** | **`/handoff load` / 新会话开头主动读** |

**不替代**：
- 不替代 PRD / plan / skill-map（那些是事实源）
- 不替代 memory（那是长期事实）
- 不替代 session.json（那是 /dev 机器态）
- 不替代 conversation export（那是档案，但禁止整个 Read）

---

## 二、子命令

### `/handoff save`

把当前会话状态压缩成交接卡，写入 `.skills/{product}/handoff/{YYYY-MM-DD-HHMMSS}.md`。

**触发时机**（任何一条命中即触发提醒，操作员决定是否真写）：
1. context 用量预估超过 60%
2. 操作员说"暂停 / 待会儿继续 / 先停一下 / 准备休息 / 明天再做"
3. 操作员说"导出 / export / 交接 / 新会话"
4. 即将执行 `/export` 之前（替代或补充）
5. 跨多次工具调用的长任务做完一个阶段时

**模板字段**（详见 `templates/handoff.md`）：
- frontmatter：session 日期、topic、status、next_session_load 指令
- 当前任务（一句话）
- 已确认的事实（带文件路径/具体数值）
- 已完成的步骤（带产物路径）
- 待操作员决策（阻塞下一步的问题）
- 关键决策（含原因）
- 下一步要做的事
- **不要做的事**（避免下次重复犯错）

**字数硬约束**：
- 单份 ≤ 800 字（约 3 KB）
- 超过就说明在写过程，不是交接 → 让我精简

### `/handoff load [product]`

新会话开头主动读取最近一份 handoff，恢复任务上下文。

**触发时机**（新会话开头的自然语言，任何一条命中即应主动 load，无需等操作员显式说 `/handoff load`）：
- "继续昨天/上次/之前的工作"
- "接着干"、"接上"
- "刚才/昨天做到哪了"
- "我们之前讨论了什么"
- 操作员明确说 `/handoff load` 或 "加载交接卡"

**执行流程**：
1. 读 `.skills/context.json` 拿 activeProduct（如果有）
2. Glob `.skills/{product}/handoff/*.md`，按文件名时间倒序
3. Read 最新的那份
4. 一句话向操作员汇报："已加载 {时间} 的交接卡，当前状态：{topic}，下一步要做：{next}。要继续吗？"
5. 等操作员确认才继续

**不要做**：
- 不要自动加载多份 handoff（只读最新一份）
- 不要去 Read `.skills/archive/conversations/` 下的 export txt
- 不要忽略 frontmatter 的 status 字段（如果是 `已结束`，要问是不是开新任务）

### `/handoff list [product]`

列出指定 product（或当前 activeProduct）的所有 handoff 卡，按时间倒序，每条显示 topic + status。

### `/handoff status`

不写文件，只口头汇报"如果现在 save，handoff 卡会写什么"。用于让操作员预览。

---

## 三、写卡硬规则

### 规则 1：不进 memory

handoff 是任务断点（临时状态），memory 是长期事实。混在一起会导致：
- memory 膨胀（每次任务都产出一条）
- 污染未来会话（旧任务残留干扰新任务判断）

### 规则 2：不复用 export txt

写卡时禁止 `Read` conversation export，必须从当前对话上下文直接提炼。export 是档案，不是数据源。

### 规则 3：必须写「待操作员决策」段

哪怕这段是空的也要写明"无待决"。这是为了让下个会话的我一眼看到是否被阻塞。

### 规则 4：必须写「不要做的事」段

特别是：
- 刚踩过的坑（避免下次重复）
- 操作员明确否决的方向
- 已废弃的中间方案

### 规则 5：路径用绝对路径

handoff 里所有文件引用必须是绝对路径，因为下个会话的工作目录可能不同。

### 规则 6：每个 product 独立目录

`.skills/{product}/handoff/` 隔离不同 product 的交接卡，避免串台。
无 activeProduct 时降级到 `.skills/handoff/` 全局目录。

---

## 四、会话边界协议

会话边界的开局/中途/结尾动作 + 60%/80% 阈值规则**详见项目 CLAUDE.md「会话边界协议」章节**（事实源）。

本 skill 是该协议的执行载体：
- 「开局动作」 → 触发本 skill 的 `/handoff load`
- 「中途动作 60%/80% 阈值」 → 触发本 skill 的 `/handoff save` 提醒
- 「结尾动作」 → 触发本 skill 的 `/handoff save` + status 标记

**不在此处复述 CLAUDE.md 的具体阈值和措辞**，避免双源漂移。如果两处冲突，以 CLAUDE.md 为准。

---

## 五、与其他 skill 的衔接

| 衔接 skill | 关系 |
|-----------|------|
| `/dev` | 互补。dev 写机器态 session.json，handoff 写人类态。两者同时存在不冲突。 |
| `/review` | review 完成后可顺手 `/handoff save` 标记阶段交接 |
| `/req` `/plan` | 这些 skill 产出的 PRD / plan.md 是事实源，handoff 引用即可，不重复内容 |
| `/pack` | handoff 目录不进 zip 分发包（同 .skills/ 规则） |
| `memory` | 互不写入对方载体。handoff 里出现的长期偏好可手动提到 memory，反之不行 |

---

## 六、目录约定

```
.skills/
├── {product}/
│   ├── handoff/                  ← 当前任务的交接卡（多份按时间）
│   │   ├── 2026-06-24-143020.md
│   │   ├── 2026-06-24-180530.md
│   │   └── README.md             ← 可选，说明这个 product 的卡如何使用
│   ├── docs/                     ← PRD / plan / features（事实源，不动）
│   └── ...
├── handoff/                      ← 无 activeProduct 时的全局降级目录
└── archive/
    └── conversations/            ← 旧版 export txt 归档区（默认不读）
        └── README.md
```

---

## 七、错误处理

| 场景 | 处理 |
|------|------|
| `/handoff load` 时 handoff 目录为空 | 汇报"没有现成交接卡"，建议直接说当前要做什么 |
| handoff 文件 >800 字 | 警告操作员"卡太厚了，要不要让我重写一份精简版？" |
| 找不到 activeProduct | 降级用 `.skills/handoff/` 全局目录，并提醒"建议先 `/req switch` 切到具体 product" |
| save 时操作员还在等问题答复 | "待操作员决策"段必须显式列出待回应问题 |
| **同分钟内多次 save 文件名冲突** | 时间戳精确到秒（`HHMMSS`），仍冲突则后缀 `-2`、`-3` 累加；不要覆盖前一份 |
| **load 时最新卡 Read 失败/解析报错** | 不要 silently 跳过；汇报"最新卡 {路径} 损坏"+ 列出第二新的卡，让操作员选 |
| **load 时最新卡 status=已结束** | 不直接续做；汇报"最新卡已标记结束（{topic}）"+ 询问"是开新任务还是回顾这份？" |
| **save 时检测到本会话已存在 handoff（同 session）** | 默认增量更新最新那份（追加新决策、改 status），不每次新建；除非操作员明确说"另存一份" |

---

## 八、模板

参见 `templates/handoff.md`。
