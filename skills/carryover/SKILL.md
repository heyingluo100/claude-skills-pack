---
name: carryover
description: 任务级续接卡（半自动）。跟 /dev 生命周期绑定：/dev start 建卡，关键节点主动更新，/dev done+commit 或操作员显式说"完成了/搞定了"后自动软删除到 archive。与 /handoff（会话级，手动）职能互补，单任务场景优先用 carryover。触发词：carryover、结转、续接、任务卡、上次做到哪、接着上个任务、继续这个任务。
argument-hint: "[save|load|list|status]"
allowed-tools: Read Write Edit Glob Grep Bash
version: 1.0.0
status: active
---

# /carryover — 任务级续接卡

## 定位

跟 /dev 生命周期绑定的**单任务续接卡**。半自动模式：Claude 主动建卡、节点更新、任务完成后软删除。

**与 /handoff 的差别**：carryover = 任务级 + 半自动 + 跟 /dev 绑定；handoff = 会话级 + 手动 + 会话边界。单任务场景优先 carryover，多任务混合或纯讨论用 handoff，两者可并存。

## 卡文件

**存放路径**：`.skills/{product}/carryover/{YYYY-MM-DD-HHMMSS}.md`
- 无 activeProduct 时降级到 `.skills/carryover/`
- 软删后移到同目录下的 `archive/` 子目录
- 正常情况主目录只应有 1 张卡（当前任务）

**字数上限**：单卡 ≤ 800 字（超过说明在记流水账）

**模板**：见 `templates/carryover.md`。5 段：任务是什么 / 做到哪 / 关键决策 / 下一步 / 不要做

## 触发行为（4 类）

### 1. 建卡
- `/dev start` → Claude 主动建空卡（骨架 + 时间戳）
- 不走 /dev 的轻量任务默认不建卡（噪声太多），需要时操作员手动 `/carryover save`

### 2. 主动更新（每轮对话最多 1 次）
Claude 在关键节点用 Edit 增量修改对应段落。

**什么算「关键节点」**：

| 情景 | 是关键节点吗 | 更新哪段 |
|------|------------|---------|
| 跑通一个测试 / 完成一个可验证的子步骤 | ✅ 是 | 做到哪 |
| 决定用方案 A 不用 B（影响后续方向） | ✅ 是 | 关键决策 |
| 任务方向调整（如"改为先做后端"） | ✅ 是 | 任务是什么 + 下一步 |
| 操作员说"暂停 / 明天 / 待会儿" | ✅ 是 | 当前进度 + 下一步 |
| 踩坑并绕过（"这条路走不通"） | ✅ 是 | 不要做 |
| 补一行日志 / 改个变量名 / 格式化 | ❌ 否 | 不动 |
| 读了个文件 / 跑了 grep 查东西 | ❌ 否 | 不动 |
| 反复微调同一段代码 | ❌ 否（合并进上一次更新） | 不动 |

**判断原则**：如果不写进去，下个会话的 Claude 会走弯路 → 就是关键节点。否则不是。

### 3. 强制更新（绕过每轮 1 次限制）
- /dev done / abandon 前
- 操作员明说完成或暂停
- context >80%

### 4. 软删除（不询问操作员，但要透明汇报）
- `/dev done` + commit 成功 → mv 到 archive
- 操作员显式说"完成了 / 搞定了 / 做好了 / OK 了 / 没问题了" → mv 到 archive
- `/dev abandon` → mv 到 archive

**执行后必须一句话汇报**（不询问 ≠ 静默）：
> 已把 carryover 卡软删到 `.skills/{product}/carryover/archive/{文件名}.md`，任务标记完成。

**软删除**：不是 rm，是 mv 到 `carryover/archive/`。理由：万一操作员发现任务没真做完，能捞回来。

### 建卡时也要汇报（一句话）
- `/dev start` 或首次 `/carryover save` 时，建完卡后回一句：
> 已建 carryover 卡 `.skills/{product}/carryover/{文件名}.md` 跟踪本任务。

## 自动加载（SessionStart hook）

**脚本**：`scripts/check-cards.js`

**行为**：会话开始时扫 `.skills/{product}/carryover/`（不含 archive），命中最新一份就输出提示（含路径 + task + status）。Claude 看到提示后主动 Read 并向操作员汇报 topic + 下一步，等确认续做。

**边界**：

| 情景 | 处理 |
|------|------|
| 无卡 | 静默退出 |
| 卡 status=已结束 | 汇报存在但不 load，问是开新任务还是回顾 |
| 卡超过 7 天未更新 | 汇报存在但不自动 load |
| 卡 product 与当前 activeProduct 不匹配 | 汇报，让操作员决定 |
| 卡损坏（frontmatter 无法解析） | 汇报，列第二新卡备选 |
| **同秒创建冲突（并发会话）** | 时间戳后缀 `-2`/`-3` 累加，不覆盖 |
| **主目录多张卡并存**（异常） | 保留最新一张，其他 mv 到 archive 并汇报 |
| **hook 脚本执行失败** | 会话正常启动，走无卡流程（不阻塞） |
| **archive 目录不存在** | 软删时自动 mkdir，不失败 |
| **archive 已存在同名文件** | 加时间戳后缀避免覆盖 |
| **status 反复切换** | 允许，最后一次生效 |

**hook 配置**：项目本地 `.claude/settings.local.json` 或全局 `~/.claude/settings.json` 的 SessionStart 数组追加：
```json
{
  "type": "command",
  "command": "node \"<绝对路径>/check-cards.js\"",
  "timeout": 5,
  "async": false
}
```

## 子命令（手动兜底）

半自动是默认路径，以下命令用于兜底或调试：

- `/carryover save` — 强制保存当前任务卡
- `/carryover load [product]` — 手动加载最新卡（一般由 hook 触发）
- `/carryover list [product]` — 列出所有卡（含 archive）
- `/carryover status` — 口头汇报当前卡状态和"如果现在 save 会写什么"

## 硬规则

1. **不进 memory / 不进 handoff**：三者完全隔离，不互写
2. **路径用绝对路径**：卡里所有文件引用必须绝对路径
3. **每个 product 独立目录**：`.skills/{product}/carryover/` 隔离不同 product
4. **archive 不入 pack**：archive 目录不进 zip 分发包

## 与其他 skill 的衔接

- **`/dev`**：强绑定。start 建卡，done+commit 或 abandon 时软删
- **`/handoff`**：互补。一个会话可能同时存在两种卡，SessionStart 优先汇报 carryover 再汇报 handoff
- **`/req` `/plan`**：事实源。卡里引用 PRD/plan 路径，不重复内容
- **memory**：互不写入对方载体

## 会话边界协议

开局/中途/结尾的完整规则详见项目 CLAUDE.md「会话边界协议」章节（事实源）。本 skill 是任务级载体，不在此处复述阈值和措辞，避免双源漂移。
