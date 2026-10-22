---
name: pack
description: 管理 claude-skills-pack.zip 的打包规则和执行。当用户提到"打包"、"重打包"、"更新 zip"、"pack"时触发。固化包内结构、源文件来源、敏感文件排除清单、触发时机。
argument-hint: "[status|build|check|clean]"
allowed-tools: Read Write Edit Glob Grep Bash
---

# /pack — Skills 打包管理

## 定位

`/pack` 管理项目打包产物 `claude-skills-pack.zip` 的**规则**和**执行**。

**目标**：让任何人拿到这个 zip，解压到自己机器上就能恢复出完整、可用的 skills 环境。即"**可迁移性**"。

**默认作用域**：只打**项目内**的 skills（即当前项目 `.claude/skills/` 下的本体），外加少量全局配套文件（项目根 `CLAUDE.md`、`~/.claude/design-system.md`、`pack/templates/install-readme.md`）。**不会**去递归用户全局目录 `~/.claude/skills/`。触发 `/pack` 时无需再确认"要打哪些 skill"——范围已由 `packaging.config.json` 写死。

核心职责：
- 固化包内结构约定（哪些文件进包、来源是什么）
- 排除本地运行数据和敏感文件（token / results.tsv / 日志 / 缓存）
- 保留 skill 定义完整（SKILL.md / templates / scripts / test-prompts）
- 执行打包 + 校验产物 + 一致性检查

### 典型衔接场景

| 来源 | 场景 | 用户接下来做什么 |
|------|------|-----------------|
| 改了 CLAUDE.md / SKILL.md / design-system.md | zip 过期 | → `/pack build` |
| commit 前想确认产物是否最新 | 查看新鲜度 | → `/pack status` |
| 担心包里混入敏感文件或丢了关键文件 | 审查包内容 | → `/pack check` |
| 打包失败或 staging 脏了 | 清 staging | → `/pack clean` |
| 想分享给具体用户使用（含本地凭证）| 显式打分享版 | → `/pack build share` |

---

## 打包约束（硬规则，不可绕过）

### 1. 产物命名

- 产物名**永远**叫 `claude-skills-pack.zip`，放项目根目录
- 旧名 `skills-pack-full.zip` 已废弃，发现要改回来
- **share 模式**例外：产物名为 `claude-skills-pack-share.zip`（见下方「模式切换规则」）

### 2. 包内结构

```
claude-skills-pack.zip
├── README.md              ← 来自 .claude/skills/pack/templates/install-readme.md
├── CLAUDE.md              ← 来自项目根 CLAUDE.md
├── project-CLAUDE.md      ← 来自项目根 CLAUDE.md（同一份内容，另存文件名）
├── design-system.md       ← 来自 ~/.claude/design-system.md（全局文件）
└── skills/                ← 来自 .claude/skills/ 递归复制 + 排除清单过滤
```

### 3. 源文件来源表

| zip 里的路径 | 源文件 | 备注 |
|-------------|--------|------|
| `README.md` | `.claude/skills/pack/templates/install-readme.md` | 静态模板 |
| `CLAUDE.md` | 项目根 `CLAUDE.md` | 复制 |
| `project-CLAUDE.md` | 项目根 `CLAUDE.md` | **同源**，内容必须一致 |
| `design-system.md` | `~/.claude/design-system.md` | 全局文件，缺失时报错中止 |
| `skills/*` | `.claude/skills/*` 逐 skill 走白名单（见 4.5）| 白名单 + SKILL.md 引用兜底 + 全局 excludes 兜底 |

### 4. 排除清单（敏感兜底）

按**文件名/目录名**匹配（支持 `*` 通配），命中就删。即使白名单选中也会被这层兜底删掉，作为安全保险：

| 模式 | 为什么排除 |
|------|-----------|
| `*.token-cache.json` | 本地 API token，**敏感** |
| `.git` | 子仓库的 git 目录 |
| `.DS_Store` | macOS 杂项 |
| `results.tsv` | darwin 本地优化历史，每人从 0 开始 |
| `*.bak-*` | 备份文件 |
| `node_modules` | 依赖目录 |
| `*.log` | 本地运行日志 |
| `.pack-staging` | 打包暂存目录（防嵌套） |

完整配置见 `packaging.config.json` 的 `excludes` 字段。

### 4.5 Skill 白名单规则（通用打包的核心）

对每个 `.claude/skills/{any}/` 目录，**默认全不收**，命中以下任一规则才进包：

1. **本体 / 约定固定文件**（`alwaysInclude`）
   - `SKILL.md`、`test-prompts.json`

2. **约定固定目录**（`includeDirs`）
   - `references/**`
   - `assets/**`
   - `agents/**`

3. **带例外的约定目录**（`includeDirsExcept`）
   - `scripts/**`，但**排除** `scripts/dev/**`（开发期工具）

4. **SKILL.md 引用兜底**（`referenceFallback`）
   - 扫 SKILL.md，把它引用的相对路径文件也纳入。匹配两种写法：
     - markdown 链接 `[text](path)`
     - 反引号包裹且后缀是 `json|md|html|js|mjs|ts|ps1|sh|py|yaml|yml|png|svg|jpg|jpeg|gif|css|txt|xml|tsv|csv` 之一（如 `` `packaging.config.json` ``）
   - 跳过：绝对 URL、锚点、含 `..` 的路径（禁跨 skill）、以 `.claude/` 开头的项目级长路径
   - 仅 1 层（不递归被引文件里的引用）

完整配置见 `packaging.config.json` 的 `skillsWhitelist` 字段。

**作者约定（重要）**：

- 开发期工具（截图脚本、本地构建器、调试用脚本）放在 `scripts/dev/` 子目录下，**不打包**
- 文档放在 `docs/` 下默认**不打包**；要打包就在 SKILL.md 里 `[link](docs/foo.md)` 引用它
- 配置文件（`*.config.json` 等）放在 skill 根，在 SKILL.md 用反引号写一次（如 `` `foo.config.json` ``）即可被兜底收进

### 5. "保留" vs "排除" 判断原则

| 类型 | 举例 | 处理 |
|------|------|------|
| **skill 本体** | SKILL.md | ✅ 打包（白名单 alwaysInclude） |
| **运行依赖固定目录** | references/、assets/、agents/、scripts/（除 scripts/dev/） | ✅ 打包（白名单 includeDirs） |
| **测试用例** | test-prompts.json | ✅ 打包（装包人也要用） |
| **被 SKILL.md 引用的非约定文件** | docs/foo.md、根 *.config.json | ✅ 打包（引用兜底） |
| **作者展示物料** | README.md、showcase.html、docs/index.html | ❌ 不打包（不在白名单且未被引用） |
| **开发期工具** | scripts/dev/screenshot.mjs、scripts/dev/build.js | ❌ 不打包（白名单 except） |
| **测试运行结果** | results.tsv、*.log | ❌ 排除（excludes 兜底） |
| **本地敏感数据** | *.token-cache.json | ❌ 排除（excludes 兜底） |
| **本地权限配置** | settings.local.json | ❌ 排除（本就不在 skills/ 下，默认不带） |
| **备份/临时** | *.bak-*、.pack-staging、node_modules | ❌ 排除（excludes 兜底） |

### 6. 触发时机（改了就必须重打）

- 项目根 `CLAUDE.md` 有任何变更
- `.claude/skills/**/SKILL.md` 有任何变更
- `.claude/skills/**/references/**` 有任何变更
- `.claude/skills/**/assets/**` 有任何变更
- `.claude/skills/**/agents/**` 有任何变更
- `.claude/skills/**/scripts/**` 有任何变更
- `.claude/skills/**/test-prompts.json` 有任何变更
- `~/.claude/design-system.md` 有任何变更
- `.claude/skills/pack/templates/install-readme.md` 有任何变更

### 7. 模式切换规则（normal vs share）

`/pack build` 有两种模式，**默认 normal，share 必须显式指定**。

| 维度 | normal（默认）| share（显式 opt-in）|
|------|---------------|---------------------|
| 触发命令 | `/pack build` | `/pack build share` |
| 产物名 | `claude-skills-pack.zip` | `claude-skills-pack-share.zip` |
| 含本地凭证 | ❌ 严格排除 | ✅ 保留（仅 `*.token-cache.json`）|
| git 跟踪 | ✅ 允许（可入库可分发） | ❌ 必须 ignore |
| 适用场景 | 公开分发、提交仓库、对外发布 | 私下分享给具体收件人，附带发起人本地凭证 |
| 安全红线 | 见下方「安全红线」 | 见下方「share 模式独立红线」 |

**share 模式与 normal 的差异**（见 `packaging.config.json` 的 `shareMode` 字段）：
- 仅在 normal 的 excludes 基础上**剔除** `*.token-cache.json` 一条；其它（`results.tsv`、`*.log`、`*.bak-*`、`.git`、`node_modules`、`.DS_Store`、`.pack-staging`）**仍然排除**
- README 顶部自动注入警示横幅，告诉收件人这是含凭证的私享版
- 脚本会自动把 share 产物名追加到当前项目 `.gitignore`，并在 build 后用 `git ls-files` / `git status` 双重校验，发现被 git 跟踪即中止

**任何"隐式触发 share"的路径都禁止**——不能默认带凭证、不能根据"项目里有 token-cache 就自动 share"，必须用户主动喊 `share`。

---

## 前置检查

### 1. 定位项目根

用 `git rev-parse --show-toplevel` 取 git 根目录；失败时用当前工作目录。后续所有相对路径基于项目根。

### 2. 读取 config

读取 `.claude/skills/pack/packaging.config.json`：
- 文件不存在：报错中止，提示检查 pack skill 是否完整
- 格式错误：报错中止

### 3. 确认 design-system.md 可达

`~/.claude/design-system.md` 必须存在才能打包。缺失时中止并提示先把设计规范放到全局目录。

---

## 子命令路由

| 参数 | 执行 |
|------|------|
| `status` | 对比产物时间与源文件时间，判断是否过期 |
| `build` | 执行打包（normal 模式，推荐走脚本） |
| `build share` | 执行打包（**share 模式**，含本地凭证，仅限私享）|
| `check` | 校验当前 zip（文件清单 + 敏感排查 + 一致性） |
| `clean` | 清理 staging |
| 无参数 | 显示状态概要 |

### 自然语言路由

| 操作员可能的表达 | 映射到 |
|---|---|
| "打包"、"重打"、"更新 zip" | → build（normal）|
| "打个分享版"、"打带凭证的包"、"打给 XX 用的包" | → build share |
| "zip 是最新的吗"、"查打包状态" | → status |
| "包里有没有敏感文件"、"校验 zip" | → check |
| "清一下 staging" | → clean |

---

## status — 新鲜度概要

### 执行

1. 读 config
2. 获取 `claude-skills-pack.zip` 的 mtime（不存在标记为"从未打包"）
3. 遍历所有触发文件（config 的 `triggers` 字段），用 `Bash` 取最大 mtime
4. 对比：
   - zip mtime < 最大源 mtime → **过期**
   - zip mtime ≥ 最大源 mtime → **最新**

### 输出

```
[PACK STATUS]

产物：claude-skills-pack.zip
状态：[最新 / 过期 / 从未打包]
产物时间：YYYY-MM-DD HH:MM（或"不存在"）
最新源：YYYY-MM-DD HH:MM（来自 [具体文件]）

[若过期] 触发重打的文件：
  - 文件路径1（比 zip 新 N 分钟）
  - 文件路径2

建议：→ /pack build
```

---

## build — 执行打包

### Skill 元开发轨追加前置检查（仅当 plan.md / skill-map.md 存在）

如果当前是 Skill 元开发轨场景，build 前必须额外通过以下检查：

1. **验收门禁**：进入打包的 skill 已达到 `reviewed` 状态。如用户明确接受未验收草稿包，必须在输出中标记风险
2. **manifest 一致**（若使用打包清单）：清单 includeSkills/excludeSkills 与 `.claude/skills/` 实际目录一致，无 include/exclude 冲突
3. **不绕过 review**：不能用打包掩盖未完成的 review、敏感文件风险或旧项目取源
4. **多场景处理已覆盖**：正常打包、缺失文件、清单冲突、zip 校验失败、敏感文件风险、未验收条目、用户未要求打包都有明确处理
5. **最初需求偏离检查**：当前动作确实是用户要求的打包/重打包/更新 zip，而不是把普通讨论或未确认方案提前打包

研发产品轨场景不强制以上检查，沿用本文件原有 build 流程。

### 推荐方式：调用脚本

- Windows（PowerShell）：
  - normal：`powershell -ExecutionPolicy Bypass -File .claude\skills\pack\scripts\pack.ps1`
  - share： `powershell -ExecutionPolicy Bypass -File .claude\skills\pack\scripts\pack.ps1 -Mode share`
- macOS / Linux：脚本暂未提供，按下方"手动方式"走

脚本内部流程：
1. 清 `.pack-staging/build/`
2. 按 config `sources` 复制源文件到 staging
3. 递归遍历 staging，按 `excludes` 清单删除命中项
4. 用 `Compress-Archive` 生成 zip 到项目根
5. 输出摘要 + 提示跑 `/pack check`

### 手动方式（脚本不可用或跨平台）

按顺序执行（PowerShell 示例，bash 类比）：

```powershell
# 1. 清 staging
Remove-Item -Recurse -Force .pack-staging\build\* -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path .pack-staging\build | Out-Null

# 2. 复制源
Copy-Item .claude\skills\pack\templates\install-readme.md .pack-staging\build\README.md
Copy-Item CLAUDE.md .pack-staging\build\CLAUDE.md
Copy-Item CLAUDE.md .pack-staging\build\project-CLAUDE.md
Copy-Item $env:USERPROFILE\.claude\design-system.md .pack-staging\build\design-system.md
Copy-Item .claude\skills .pack-staging\build\skills -Recurse

# 3. 应用排除清单（逐项删除）
$excludes = @("*.token-cache.json",".git",".DS_Store","results.tsv","*.bak-*","node_modules","*.log",".pack-staging")
foreach ($pat in $excludes) {
    Get-ChildItem -Path .pack-staging\build -Recurse -Force | Where-Object { $_.Name -like $pat } | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
}

# 4. 打包
Remove-Item claude-skills-pack.zip -Force -ErrorAction SilentlyContinue
Compress-Archive -Path .pack-staging\build\* -DestinationPath claude-skills-pack.zip -CompressionLevel Optimal

# 5. 跑 check 校验
```

### 输出

```
[PACK BUILD]

项目根：<path>
清理 staging ... ✓
复制源文件（5 项）... ✓
应用排除清单（N 条规则，过滤 M 个文件）... ✓
生成 zip ... ✓

产物：claude-skills-pack.zip
大小：X.X MB
文件数：N 个

→ 建议立即执行 /pack check 校验
```

---

## check — 校验

### 检查项

1. **产物存在**：`claude-skills-pack.zip` 在项目根
2. **顶层文件清单**：`README.md` / `CLAUDE.md` / `project-CLAUDE.md` / `design-system.md` / `skills/` 都在
3. **Skill 完整性**：对比 zip 里 `skills/` 下的目录数和项目 `.claude/skills/` 下的目录数，数量一致
4. **CLAUDE.md 一致性**：`CLAUDE.md` 和 `project-CLAUDE.md` 内容**完全相同**（通过 hash 或 diff）
5. **敏感排查**：zip 里**不得**出现任何匹配排除清单的文件（`*.token-cache.json` / `.git/` / `results.tsv` / `*.bak-*` / `*.log`）
6. **大小合理性**：zip < `constraints.maxSizeMB`（默认 50MB）

### 执行

用 `unzip -l claude-skills-pack.zip` 列出包内容，逐项比对。

### 输出（通过）

```
[PACK CHECK]

产物：claude-skills-pack.zip
✓ 产物存在
✓ 顶层文件清单完整
✓ Skill 数量一致（N 个）
✓ CLAUDE.md 与 project-CLAUDE.md 内容一致
✓ 敏感文件排查通过
✓ 产物大小：X.X MB（上限 50MB）

→ 校验通过
```

### Skill 元开发轨追加：skill-map 状态推进（仅当 skill-map.md 存在）

check 通过后，如存在 `.skills/{product}/docs/skill-map.md`，可同步推进产品状态：

- 对状态为 `reviewed` 的条目，且 skill 同时存在于打包清单和 zip 中时，标记为 `packed`
- 状态为 `optimized` 但尚未经过 `/review` 的条目**不得**推进为 `packed`，应先完成验收
- 未进入打包清单的 skill 只输出"未纳入分发清单"，不得自动加入包
- 不回退已是 `packed` 的条目
- 更新前必须展示影响预览并等用户确认

研发产品轨场景不涉及此步。

### 输出（失败示例）

```
[PACK CHECK]

✗ 敏感文件排查不通过：
  - skills/darwin-skill/results.tsv

这些文件不该出现在产物中。请：
  1. 检查 packaging.config.json 的 excludes 配置
  2. 重新执行 /pack build
  3. 不要手动从 zip 里删文件（会漂移）
```

---

## clean — 清理 staging

删除 `.pack-staging/build/` 下所有内容。staging 目录本身保留。

---

## 无参数时（`/pack`）

```
[PACK]

产物：claude-skills-pack.zip
状态：[最新 / 过期 / 从未打包]

命令：
  /pack status      — 查看产物新鲜度
  /pack build       — 执行打包（normal：清 staging → 复制 → 排除 → 压缩 → 校验）
  /pack build share — 执行打包（share：含本地凭证，自动加 gitignore，禁 commit/push）
  /pack check       — 校验当前 zip 内容（不重打）
  /pack clean       — 清理 staging 目录

核心约束：
  - 产物名固定 claude-skills-pack.zip（normal）/ claude-skills-pack-share.zip（share）
  - CLAUDE.md 和 project-CLAUDE.md 内容必须一致（都来自项目根 CLAUDE.md）
  - 测试用例（test-prompts.json）打包，测试结果（results.tsv）和 token 缓存（normal 模式）必须排除
  - 目标：解压后可直接使用，即"可迁移性"

详细约束：.claude/skills/pack/packaging.config.json
```

---

## 安全红线

### normal 模式红线（默认）

- **绝不**把 token 缓存、.git/ 目录、本地私有数据打进包。每次 `check` 都要验证，发现即阻断
- **绝不**跳过排除清单。操作员说"这次就留着"也要拒绝，安全优先
- **绝不**改产物命名。约定俗成的名字不能变，影响下游使用者的安装脚本
- **绝不**手动从 zip 里删文件后交付。要删就改 config + 重打包，保证产物和配置一致

### share 模式独立红线（显式 opt-in 时）

share 模式是**例外通道**，仅允许在以下硬约束下使用：

- **绝不 commit**：产物必须先在 `.gitignore` 内才允许生成；脚本会自动追加并用 `git ls-files` / `git status` 双重校验，发现被跟踪即中止
- **绝不 push**：含本地凭证的包不得推送到任何远程仓库
- **绝不二次分发**：只能交付给指定收件人，凭证泄露责任归发起人
- **绝不扩大保留范围**：share 模式只允许保留 `*.token-cache.json` 这一类授权数据，其它"被排除的文件"（`results.tsv`、`*.log`、`*.bak-*` 等）仍然排除；操作员说"顺便把日志也带上"应拒绝
- **绝不复用产物名**：share 模式产物名 `claude-skills-pack-share.zip` 不得与 normal 模式同名

任何想"放松 share 模式约束"的请求，按 normal 模式红线第 2 条处理——拒绝。
