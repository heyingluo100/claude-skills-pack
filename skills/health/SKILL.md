---
name: health
description: 项目全局体检。当用户提到"项目体检"、"全局扫描"、"检查项目"、"health"、"项目有没有问题"时触发。自动识别项目类型（Vue 前端 / Skills 定义 / 通用），加载对应维度集扫描，覆盖逻辑漏洞、闭环完成度、安全风险、性能容错、需求一致性等。
argument-hint: "[scan|report|history]"
allowed-tools: Read Write Edit Glob Grep Bash(git *) Bash(npm *) Bash(node *)
---

# /health — 项目全局体检

## 定位

`/health` 是一个**手动触发**的全局扫描工具，按项目类型加载对应维度集做全面体检。不自动触发，不修改任何文档或代码——只输出诊断报告，修复由操作员决定。

与其他 Skill 的区别：
- `/lint check`：只检查代码规范
- `/review check`：只对照 PRD 验收标准
- `/dev done`：只检查当前任务
- **`/health`：全项目、全维度、按项目类型适配的扫描**

## 共通规则

1. **手动触发**：不会自动执行，必须操作员主动调用
2. **二次确认**：触发后先展示扫描范围，操作员确认后才开始扫描
3. **扫描只读**：scan 过程不修改任何文件，发现问题只记录
4. **修复需确认**：fix 每个修复项都需操作员确认后才执行
5. **中文输出**：所有报告用中文

## 前置检查

1. 读取 `.skills/context.json` 获取当前产品
   - **不存在时**：仍可扫描代码，但跳过"代码-需求一致性"维度（无 PRD 可对比），提醒操作员
2. 扫描项目根目录，确认有代码文件存在
   - **空项目**：输出"当前项目无代码文件，无需扫描"并终止
3. **项目类型识别**（决定加载哪组维度集）：

   按以下顺序检查，命中即停：

   | 识别特征 | 项目类型 | 维度集 |
   |---------|---------|-------|
   | `.claude/skills/*/SKILL.md` 存在（≥1 个 Skill 定义） | **Skills 定义项目** | 加载 Skills 8 维度 |
   | `package.json` 存在且 `src/**/*.vue` 有文件 | **Vue 前端项目** | 加载 Vue 8 维度 |
   | `package.json` 存在但无 .vue 文件 | **Node 通用项目** | 加载通用 4 维度 |
   | `pyproject.toml` 或 `requirements.txt` 存在 | **Python 项目** | 加载通用 4 维度（声明暂不支持深度扫描） |
   | 以上都不满足 | **未知类型** | 加载通用 4 维度 |

   识别结果在扫描预览中明示：
   ```
   项目类型：[Vue 前端 / Skills 定义 / Node 通用 / Python / 未知]
   维度集：[Vue 8 维 / Skills 8 维 / 通用 4 维]
   ```

   **操作员覆盖**：`/health scan --as [vue|skills|generic]` 强制用指定维度集，不走自动识别。

---

## 子命令路由

| 参数 | 执行 |
|------|------|
| `scan` | → 执行全局体检（默认） |
| `scan --dim [N]` | → 只扫描指定维度（1-8） |
| `fix` | → 修复上次扫描发现的问题 |
| `fix [HEALTH-ID]` | → 修复指定问题 |
| `report` | → 查看最近一次扫描报告 |
| `history` | → 查看历史扫描记录摘要 |
| 无参数 | → 等同于 scan |

### 自然语言路由

当操作员使用自然语言而非精确命令时，按以下规则映射：

| 操作员可能的表达 | 映射到 |
|---|---|
| "项目有没有问题"、"帮我检查一下项目"、"全局扫描" | → scan |
| "修一下刚才扫描出来的问题"、"帮我修复" | → fix |
| "上次扫描结果"、"看看体检报告" | → report |
| "扫描过几次了"、"历史体检记录" | → history |

---

## scan — 全局体检

### 第1步：扫描范围确认

触发后先输出扫描预览，等操作员确认：

```
[HEALTH] 项目体检 — 扫描范围确认

当前产品：[产品名 / 未设置]
项目类型：[Vue 前端 / Skills 定义 / Node 通用 / Python / 未知]
扫描范围：项目全部代码（按对应维度集）
代码文件数：约 N 个
PRD 状态：[已定稿 v1.X / 未找到 — 跳过维度"代码-需求一致性"]

将从以下维度进行扫描（根据项目类型自动选择）：

[若 Vue 前端] 8 维度：
  1. 逻辑漏洞 / 2. 闭环完成度 / 3. 状态流转 / 4. 使用便利性
  5. 代码-需求一致性 / 6. 代码结构健康度 / 7. 安全风险 / 8. 性能与容错

[若 Skills 定义项目] 8 维度：
  S1. SKILL.md frontmatter 合规
  S2. 目录结构合规（官方四件套对齐）
  S3. 跨 Skill 协议一致性
  S4. 全局同步一致性
  S5. 文档引用完整性
  S6. 安全与敏感
  S7. 编排与单体边界
  S8. 实现承载同步

[若 Node 通用 / Python / 未知] 通用 4 维度：
  G1. 异常路径未处理 / G2. 资源未释放
  G3. 代码-需求一致性 / G4. 日志泄漏敏感信息

预计耗时：视项目规模而定

→ 确认开始扫描？
```

**操作员确认后才执行扫描。**

**`--dim` 参数处理**：如果操作员带了 `--dim N` 参数（N 为当前维度集内的编号，如 Vue 用 1-8，Skills 用 S1-S6，通用用 G1-G4），只扫描对应维度。扫描预览中只显示该维度，输出报告标题标注"单维度扫描（维度N）"。

**`--as` 参数**：`/health scan --as [vue|skills|generic]` 强制指定维度集，覆盖自动识别。

### 第2步：逐维度扫描

> **扫描什么维度由第1步的项目类型识别决定**。Vue 前端走维度 1-8，Skills 定义项目走 S1-S6，其他类型走 G1-G4。

---

### 【Vue 前端 8 维度】（维度 1-8）

#### 维度1：逻辑漏洞检查

扫描代码中的逻辑缺陷：

| 检查项 | 怎么查（具体工具调用） |
|-------|--------|
| 异常路径未处理 | `Grep` 搜索 `async.*{` 函数体内是否有 `try`；`Grep` 搜索 `if (` 后是否有对应 `else` |
| 空值/边界未判断 | `Grep` 搜索 `.value` 使用处，检查前方是否有 `if (!xxx)` 或 `?.` 可选链 |
| 异步错误未捕获 | `Grep` 搜索 `await ` 关键词，检查所在函数是否被 `try-catch` 包裹 |
| 条件逻辑不完整 | `Grep` 搜索 `switch (` 检查是否有 `default:`；搜索 `if.*else if` 链是否有最终 `else` |
| 资源未释放 | `Grep` 搜索 `addEventListener` 计数，对比 `removeEventListener` 计数；搜索 `setInterval`/`setTimeout` 对比 `clearInterval`/`clearTimeout` |

#### 维度2：闭环完成度检查

检查功能是否从头到尾走通：

| 检查项 | 怎么查（具体工具调用） |
|-------|--------|
| CRUD 闭环 | `Grep` 搜索 `create`/`add`/`post` 相关函数，检查同模块是否有 `delete`/`remove`/`update` |
| 操作反馈闭环 | `Grep` 搜索 `isLoading.value = true`，检查同函数内是否有 `= false`（含 finally 块） |
| 导航闭环 | `Grep` 搜索 `router.push`，检查目标页面是否有返回导航；`Glob` 扫描所有页面组件，检查是否有孤立页面 |
| 数据流闭环 | `Read` 逐个 API 模块，检查每个请求函数是否被组件调用；`Grep` 搜索 `emit(` 检查父组件是否有对应 `@` 监听 |
| 错误恢复闭环 | `Grep` 搜索 `catch` 块内容，检查是否只有 `console.error` 而无用户可见的恢复操作 |

#### 维度3：状态流转检查

检查数据和 UI 的状态是否正确：

| 检查项 | 怎么查（具体工具调用） |
|-------|--------|
| 死状态 | `Grep` 搜索所有 `ref(` 定义，检查变量名是否在 `<template>` 或其他函数中被引用 |
| 不可达状态 | `Grep` 搜索状态赋值语句（`xxx.value = `），检查每个赋值是否有触发路径（事件/生命周期/watch） |
| 状态-UI 不同步 | `Read` 组件文件，对比 `<script>` 中的 ref 变量和 `<template>` 中的绑定，找出未绑定的 ref |
| 竞态条件 | `Grep` 搜索同一组件中多个 `await`，检查是否共享同一个状态变量且无锁/取消机制 |
| 初始状态缺失 | `Read` 组件的 `onMounted`/`onBeforeMount` 钩子和 `ref()` 初始值，检查是否有 ref 初始为 `null`/`undefined` 且 mounted 中无赋值逻辑 |

#### 维度4：使用便利性检查

检查用户体验层面的问题：

| 检查项 | 怎么查（具体工具调用） |
|-------|--------|
| 操作路径过长 | `Read` 页面组件，追踪用户完成核心操作的点击链路（按钮 → 路由 → 表单 → 提交），超过 3 步标记 |
| 缺少快捷操作 | `Grep` 搜索 `@keydown`/`@keyup`/`v-shortkey`，检查高频操作（搜索、保存、新建）是否有键盘快捷键 |
| 错误提示不明确 | `Grep` 搜索 `catch` 块和错误提示文本，检查是否只有"操作失败"而无具体原因和恢复建议 |
| 缺少确认/撤销 | `Grep` 搜索 `delete`/`remove`/`destroy` 相关函数调用处，检查前方是否有 `confirm` 或确认弹窗 |
| 响应式缺失 | `Grep` 搜索 CSS 中是否有 `@media` 或 Tailwind 响应式前缀（`sm:`/`md:`/`lg:`），无则标记 |
| 无障碍缺失 | `Grep` 搜索 `<button`/`<a`/`<input` 标签，检查是否有 `aria-label`/`aria-describedby`/`role` 属性 |

#### 维度5：代码-需求一致性检查

对照 PRD 和功能书检查实现：

| 检查项 | 怎么查（具体工具调用） |
|-------|--------|
| 需求未实现 | `Read` PRD 提取 REQ 编号列表，逐个用 `Grep` 搜索代码中是否有对应实现（函数名/组件名/路由） |
| 实现偏离需求 | `Read` PRD 验收标准，`Read` 对应代码文件，逐条对比行为是否一致 |
| 超出需求范围 | `Glob` 扫描所有组件/页面/API，与 PRD 功能列表对比，找出 PRD 中未定义的功能 |
| 验收标准未满足 | `Read` PRD 中每个 REQ 的 AC 列表，逐条标记"已满足/未满足/无法判断" |

**执行方式**：
1. `Read` `.skills/{product}/docs/02-prd.md` 和 `03-features.md`
2. 提取所有 REQ 编号和验收标准
3. 通过 `Read` `tracemap.json`（如存在）找到映射；不存在时用 `Grep` 搜索 REQ 编号或功能关键词定位代码
4. 逐条对比

#### 维度6：代码结构健康度检查

检查代码的架构质量，发现耦合、重复、膨胀等结构性问题：

| 检查项 | 怎么查（具体工具调用） |
|-------|--------|
| 重复代码 | `Grep` 搜索相同函数名在多个文件中出现（如 `nanoBananaCall`、`imageUrlToBase64`），对比函数体是否相似（≥15 行） |
| 跨模块耦合 | `Grep` 搜索 `composables/` 目录下文件的 import 语句，检查是否直接引用其他 composable 的内部函数（应通过 service 层中转） |
| 全局单例滥用 | `Read` composable 文件，检查 `ref()`/`reactive()` 是否定义在导出函数外部（模块顶层），导致多组件共享同一状态实例 |
| 错误静默吞没 | `Grep` 搜索 `catch` 块，检查是否只有 `console.warn`/`console.log` 而无用户可见的错误反馈（toast/状态更新） |
| 上帝组件 | `Read` 各 `.vue` 文件的 `<script setup>` 部分，标记 script 超过 300 行或 import 超过 8 个模块的组件 |
| API 调用分散 | `Grep` 搜索 `fetch(`/`axios` 调用位置，检查是否散落在 composable/组件中而非集中在 `services/` 层 |

**执行方式**：
1. `Glob` 扫描 `src/composables/`、`src/services/`、`src/components/` 获取文件列表
2. `Grep` 搜索高频工具函数名（如 `fetch(`、`async function`），定位重复实现
3. `Read` 疑似问题文件，确认是否为真正的重复/耦合
4. 对每个问题给出具体的重构建议（提取到哪里、怎么拆）

#### 维度7：安全风险扫描

扫描代码中的安全隐患（Grep 静态扫描为主）：

| 检查项 | 怎么查（具体工具调用） |
|-------|--------|
| XSS 注入点 | `Grep` 搜索 `v-html`，`Read` 使用处检查值是否经过 sanitize（如 DOMPurify）；`Grep` 搜索 `innerHTML` 赋值是否使用用户输入 |
| 危险函数 | `Grep` 搜索 `eval(`、`new Function(`、`document.write(`，标记所有使用位置 |
| 前端路由守卫 | `Grep` 搜索 `router.beforeEach`，`Read` 路由配置提取需鉴权的页面列表，对比守卫是否覆盖所有鉴权页面 |
| CORS 配置 | `Grep` 搜索 `Access-Control-Allow-Origin` 和 `cors(` 配置，检查是否为 `*` 通配（应限制为具体域名） |
| Cookie 安全 | `Grep` 搜索 `Set-Cookie`/`cookie` 相关代码，检查是否设置 `httpOnly`/`secure`/`sameSite` 属性 |
| 频率限制 | `Grep` 搜索敏感接口（登录/注册/支付/密码重置）的路由定义，检查是否有 rate limit 中间件 |
| 敏感信息泄露 | `Grep` 搜索 `console.log`/`console.debug`/`console.info`，检查输出内容是否包含 token/password/secret/key 等敏感字段 |
| 依赖安全 | `Bash` 执行 `npm audit`（如有 package.json），检查已知漏洞；`Bash` 执行 `pip audit`（如有 requirements.txt） |

**执行方式**：
1. `Grep` 搜索各安全关键词，定位可疑代码
2. `Read` 可疑文件的上下文，确认是否为真正的安全问题
3. 对每个问题标注严重级别和修复建议

#### 维度8：性能与容错

检查代码中的性能隐患和容错缺失：

| 检查项 | 怎么查（具体工具调用） |
|-------|--------|
| 组件层级膨胀 | `Read` 页面组件，追踪组件嵌套层级（A→B→C→D→E），超过 5 层标记为中等问题 |
| 未清理资源 | `Grep` 搜索 `addEventListener` 计数，对比 `removeEventListener` 计数；搜索 `setInterval`/`setTimeout` 对比 `clearInterval`/`clearTimeout`；搜索 `watch(` 是否在 `onUnmounted` 中有 `stop` |
| 未使用 ref | `Grep` 搜索 `ref(` 定义的变量名，检查该变量是否在 `<template>` 或其他函数中被引用 |
| 图片未优化 | `Grep` 搜索 `<img` 标签，检查是否有 `loading="lazy"` 属性；`Glob` 扫描 `public/` 下图片文件，标记大于 500KB 的未压缩图片 |
| 大列表无分页 | `Grep` 搜索 `v-for` 使用处，`Read` 数据源定义，检查是否有分页逻辑或虚拟滚动组件（如 `virtual-list`/`RecycleScroller`） |
| API 无超时 | `Grep` 搜索 `fetch(`/`axios.` 调用，检查是否配置 `timeout`/`signal`（AbortController） |
| 无限重试 | `Grep` 搜索 `retry`/`重试` 相关逻辑，检查是否有最大次数限制和指数退避策略 |
| 内存泄漏风险 | `Grep` 搜索模块顶层的 `ref(`/`reactive(`（composable 导出函数外部定义），标记全局单例导致的多组件共享状态风险 |

**执行方式**：
1. `Glob` 扫描 `src/` 下所有 `.vue`/`.js` 文件获取文件列表
2. `Grep` 批量搜索性能关键词
3. `Read` 疑似问题文件，确认是否为真正的性能/容错问题
4. 对每个问题给出具体的优化建议（使用什么方案、改到哪里）

---

### 【Skills 定义项目 6 维度】（维度 S1-S6）

> 适用场景：项目根目录有 `.claude/skills/*/SKILL.md`（skill 定义本身就是项目核心产物）。不扫描 Vue 代码。

#### 维度S1：SKILL.md frontmatter 合规

检查每个 SKILL.md 的 YAML frontmatter 是否符合官方规范：

| 检查项 | 怎么查 |
|-------|--------|
| 必填字段齐全 | `Read` 每个 SKILL.md 前 10 行，确认 `name` 和 `description` 存在 |
| name 格式 | 检查 name 是 kebab-case、全小写、与文件夹名一致 |
| description 长度 | 检查 ≤ 1024 字符，且包含"做什么 + 何时用"（至少有触发词或场景描述） |
| version/status 可选 | 有则检查格式（version 遵循 semver，status ∈ {active, draft, deprecated}） |
| 文件名大写 | 文件名必须是 `SKILL.md`（不是 `skill.md` 或 `xxx.skill.md`） |

**执行方式**：
1. `Glob` 扫描 `.claude/skills/*/SKILL.md`
2. `Read` 每个文件前 10 行读 frontmatter
3. 字段缺失 / 格式错误 → 标记严重；长度超限 → 标记中等

#### 维度S2：目录结构合规（官方四件套对齐）

检查每个 skill 目录是否符合 Anthropic 官方标准：

| 检查项 | 怎么查 |
|-------|--------|
| 禁止目录存在 | `Glob` 检查 `.claude/skills/*/input/`、`*/output/`、`*/templates/`、`*/tests/`、`*/examples/` 是否存在 → 存在则标记严重（应移除或重命名） |
| 子目录命名规范 | 允许的子目录只能是 `scripts/`、`references/`、`assets/`、`agents/`；其他命名标记严重 |
| SKILL.md 内部路径合规 | `Grep` 每个 SKILL.md 中是否出现 `.claude/skills/{同名 skill}/` 或 `.codex/skills/{同名 skill}/` 绝对前缀 → 命中即标记严重（应改成 skill 内部相对形式） |
| 工具型 skill 完整性 | SKILL.md 提到"执行脚本"/"调用 run.py"等 → 检查 `scripts/` 是否存在，入口文件（run.py/run.js/main.sh）是否存在 |
| 正文长度 | `Read` 每个 SKILL.md 并计算字符数，> 5000 字且无 `references/` → 标记中等（建议拆分） |

**执行方式**：
1. `Glob` 每个 skill 目录下的所有子目录
2. `Read` SKILL.md 正文判断字符数和是否提到脚本
3. 组合判断合规性

#### 维度S3：跨 Skill 协议一致性

检查 CLAUDE.md 声明的共享文件协议和各 Skill 实际读写是否对得上：

| 检查项 | 怎么查 |
|-------|--------|
| 共享文件声明完整 | `Read` CLAUDE.md 的"跨 Skill 数据协议"表，列出所有共享文件 |
| 写入方一致 | 对每个共享文件，`Grep` 各 SKILL.md 中 `Write` / `Edit` 提及该路径的，对比 CLAUDE.md 声明的"写入方"是否匹配 |
| 读取方一致 | 对每个共享文件，`Grep` 各 SKILL.md 中 `Read` 提及该路径的，对比"读取方"列 |
| 未声明但被读写 | 扫描各 SKILL.md 中所有 `.skills/` 路径引用，对比 CLAUDE.md 声明列表，找出遗漏 |

**执行方式**：
1. `Read` CLAUDE.md 的跨 Skill 协议章节
2. `Grep` `.skills/` 路径在所有 SKILL.md 中的引用
3. 对比一致性，输出差异清单

#### 维度S4：全局同步一致性

项目 `.claude/skills/` 与全局 `~/.claude/skills/`（或 `C:\Users\<user>\.claude\skills\`）是否同步：

| 检查项 | 怎么查 |
|-------|--------|
| skill 清单一致 | `Glob` 项目 `.claude/skills/*/SKILL.md` vs 全局同位置，对比 skill 名称集合 |
| 版本号一致 | 对每对同名 skill，`Read` frontmatter 的 version 字段，不一致标记中等 |
| 打包产物新鲜度 | `Bash` 检查 `claude-skills-pack.zip` 修改时间 vs 最新 SKILL.md 修改时间，zip 更旧则标记中等（详细规则见 `/pack` skill） |

**执行方式**：
1. `Glob` 两个目录下的 SKILL.md
2. `Read` 对比 version
3. `Bash` 比较文件时间戳

**注意**：若全局目录不可访问（权限/路径不存在），仅提示不报错。

#### 维度S5：文档引用完整性

`CLAUDE.md` 和 `OUTLINE.md` 中引用的 Skill 是否都真实存在：

| 检查项 | 怎么查 |
|-------|--------|
| 幽灵 Skill | `Grep` CLAUDE.md / OUTLINE.md 中所有 `/[skill-name]` 引用，对比 `.claude/skills/` 下实际目录清单，引用但不存在 → 标记严重 |
| 孤儿 Skill | 反向：实际存在但 CLAUDE.md 未提及 → 标记中等（可能漏登记） |
| 触发关键词缺失 | 每个 SKILL.md 的 description 是否包含"触发"相关词（方便 Claude 识别调用时机） |

**执行方式**：
1. `Grep` `/[a-z-]+` 模式匹配命令引用
2. `Glob` skill 目录清单
3. 求差集

#### 维度S6：安全与敏感

Skills 项目独有的安全检查项：

| 检查项 | 怎么查 |
|-------|--------|
| .gitignore 覆盖 `.skills/` | `Read` `.gitignore`，确认有 `.skills/` 或等效规则 |
| settings.local.json 处理 | `Read` `.gitignore`，确认 `.claude/settings.local.json` 被忽略 |
| SKILL.md 中的硬编码密钥 | `Grep` 所有 SKILL.md 中的 `sk-`、`api_key=`、`password=`、`token=` 等模式 |
| 危险 Bash 命令 | `Grep` SKILL.md 中的 `rm -rf`、`chmod 777`、`curl | bash` 等未经保护的命令 |
| 敏感文件读取 | `Grep` SKILL.md 中提到 `.env` / `credentials` / `~/.ssh/` 等敏感路径的读取操作 |

**执行方式**：
1. `Read` .gitignore + 所有 SKILL.md
2. `Grep` 关键词匹配
3. 每项违规标记严重或中等

#### 维度S7：编排与单体边界

防止把复杂需求压成单个超大 SKILL.md，并检查多 skill 协作的编排方式是否清晰：

| 检查项 | 怎么查 |
|-------|--------|
| 流程长度 | `Read` 每个 SKILL.md 的"执行流程"章节，统计步骤数；超过 10 步标记为中等问题 |
| 职责混杂信号 | `Grep` 单个 SKILL.md 中是否同时包含"分析/识别"和"生成/执行"、"评估"和"修改"等独立能力关键词 |
| 中间产物缺失 | `Read` 流程描述，发现产生中间产物（候选方案、评分、报告）但没有用户确认点 → 标记中等 |
| 多状态阶段 | `Grep` SKILL.md 中是否同时引用 ≥3 个状态文件（如同时读写 plan.md / skill-map.md / review-{date}.md） |
| 主 skill 复制业务 | 检查标注为"编排型"的 skill，正文是否复制子 skill 的具体业务逻辑（应只做顺序/确认/状态衔接） |
| 编排方式声明 | 元开发轨场景下，多 skill 工作流是否在 plan.md 明确声明编排策略（主 skill / scripts 串接 / plan.md 编排表） |

**执行方式**：
1. `Glob` 所有 SKILL.md
2. `Read` 各 skill 流程章节，统计步骤、检测能力信号
3. 命中 ≥2 项信号 → 提示"疑似复杂需求被压成单体，建议回 /plan 拆分"

#### 维度S8：实现承载同步

检查系统/页面/API/CLI/脚本/数据处理/报告产物是否同步回 PRD、plan、skill-map、SKILL.md：

| 检查项 | 怎么查 |
|-------|--------|
| 承载有 REQ 追踪 | `Glob` 项目内已交付的页面/API/CLI 入口（`docs/visualize/*.html`、`scripts/*.ps1`、`src/api/`），抽样验证是否能在 PRD 找到对应 REQ |
| 字段/接口同步 | `Read` PRD/features 与实际接口/页面字段对比，发现实现新增字段而 PRD 未更新 → 标记中等 |
| 报告结构同步 | `Read` 已存在的报告产物（review-{date}.md、health/report-*.md），对比 SKILL.md 中声明的报告结构 |
| 不恢复旧链路 | `Grep` 当前规则文件，检查是否错误地把 dev/lint/guard/scaffold/ui 复活为元开发轨分发 skill（这些 skill 在研发产品轨保留，但不应进入元开发轨主链路） |
| 工程验收证据 | 对每类承载，确认有对应类型的验收证据：页面无白屏、API 契约和错误响应、CLI/脚本参数和退出码、数据样例、报告结构和证据追溯 |

**执行方式**：
1. 仅在存在 `.skills/{product}/docs/plan.md` 或 `skill-map.md` 时执行
2. `Glob` 实际承载产物所在目录
3. `Read` 产物 + PRD + plan，逐条对比
4. 缺乏同步 → 标记中等；旧链路复活到元开发轨主链路 → 标记严重

---

### 【通用 4 维度】（维度 G1-G4）

> 适用场景：未识别为 Vue 或 Skills 项目时（Node 通用 / Python / 未知类型）。扫描精简，避免误报。

#### 维度G1：异常路径未处理

| 检查项 | 怎么查 |
|-------|--------|
| async 无 try-catch | `Grep` `async function` / `async () =>`，检查函数体是否含 `try` 或被外层 try 包裹 |
| Promise 无 catch | `Grep` `.then(` 链结尾是否有 `.catch(` |
| Python 裸异常 | `Grep` `.py` 文件中 `try:` 后是否有对应 `except:`（避免空 except 吞异常） |

#### 维度G2：资源未释放

| 检查项 | 怎么查 |
|-------|--------|
| 文件句柄 | `Grep` `open(` / `fs.open` 调用是否配 `close` 或 `with` 上下文管理器 |
| 定时器 | `Grep` `setInterval` vs `clearInterval`、`setTimeout` vs `clearTimeout` 计数差异 |
| 事件监听器 | `Grep` `addEventListener` vs `removeEventListener` 计数差异 |

#### 维度G3：代码-需求一致性

仅在存在 `.skills/{product}/docs/02-prd.md` 时执行，否则跳过：

| 检查项 | 怎么查 |
|-------|--------|
| REQ 未实现 | `Read` PRD 提取 REQ 编号，逐个 `Grep` 代码中的函数名/类名/路由 |
| 实现偏离 AC | 对实现的 REQ，`Read` AC 列表 + 实现代码，逐条对比 |

#### 维度G4：日志泄漏敏感信息

| 检查项 | 怎么查 |
|-------|--------|
| console/print 敏感字段 | `Grep` `console.log` / `print(` 调用，参数中是否包含 `token`/`password`/`secret`/`apiKey` 等变量名 |
| 错误栈暴露 | `Grep` `res.send(err)` / `return err.stack` 等把错误原文返给前端的模式 |

---

### 第3步：生成报告

扫描完成后，根据问题数量决定输出方式：

- **≤ 15 个问题**：直接输出到对话中
- **> 15 个问题**：写入 `.skills/{product}/docs/health-report.md`，对话中输出摘要

> **报告输出的维度标签随活跃维度集变化**：Vue 项目用 1-8，Skills 项目用 S1-S6，通用项目用 G1-G4。下面先给 Vue 版示例，之后附 Skills 和通用版模板。

#### 对话输出格式 — Vue 8 维（简洁版）

```
[HEALTH] 项目体检报告 — [产品名]

扫描时间：YYYY-MM-DD HH:MM
项目类型：Vue 前端
代码文件：N 个
PRD 版本：vX.X

━━━ 扫描结果 ━━━

1. 逻辑漏洞：X 项
   🔴 [严重] src/api/user.js:23 — async 函数未捕获异常
   🟡 [中等] src/components/Form.vue:45 — 表单提交只处理了成功

2. 闭环完成度：X 项
   🔴 [严重] 用户管理有创建无删除
   🟡 [中等] 文件上传无进度反馈

3. 状态流转：X 项
   🟡 [中等] src/composables/useAuth.js — isLoading 设置后未重置

4. 使用便利性：X 项
   🟡 [中等] 删除操作无二次确认
   🟢 [建议] 搜索功能缺少快捷键

5. 代码-需求一致性：X 项
   🔴 [严重] REQ-B-003 数据导出 — 未实现
   🟡 [中等] REQ-A-002 登录 — 缺少"记住密码"功能

6. 代码结构健康度：X 项
   🟡 [中等] src/composables/useData.js 与 useList.js 有重复逻辑

7. 安全风险：X 项
   🔴 [严重] src/components/Content.vue:15 — v-html 未经 sanitize
   🔴 [严重] 路由守卫未覆盖 /admin 页面
   🟡 [中等] console.log 输出包含 token 信息

8. 性能与容错：X 项
   🔴 [严重] 3 个 API 调用无 timeout 设置
   🟡 [中等] addEventListener 未在 onUnmounted 中清理
   🟢 [建议] 用户列表无虚拟滚动（数据量大时可能卡顿）

━━━ 统计 ━━━

总问题数：N 项
  🔴 严重：X 项（必须修复）
  🟡 中等：Y 项（建议修复）
  🟢 建议：Z 项（可选优化）

项目健康度：[优秀 ≥90% / 良好 ≥75% / 一般 ≥60% / 需关注 <60%]
```

#### 对话输出格式 — Skills 8 维（简洁版）

```
[HEALTH] 项目体检报告 — [产品名 / 未设置]

扫描时间：YYYY-MM-DD HH:MM
项目类型：Skills 定义项目
Skill 数量：N 个
PRD 状态：[已定稿 / 未找到 — 跳过 REQ 对比]

━━━ 扫描结果 ━━━

S1. SKILL.md frontmatter 合规：X 项
   🔴 [严重] .claude/skills/xxx/SKILL.md — 缺少 name 字段
   🟡 [中等] description 超过 1024 字符

S2. 目录结构合规：X 项
   🔴 [严重] xxx/templates/ 存在（应重命名为 references/ 或 assets/）

S3. 跨 Skill 协议一致性：X 项
   🟡 [中等] CLAUDE.md 声明 foo 由 /req 写入，但 /plan 也在写

S4. 全局同步一致性：X 项
   🟡 [中等] skills-pack-full.zip 比最新 SKILL.md 更旧

S5. 文档引用完整性：X 项
   🔴 [严重] CLAUDE.md 提到 /bar 但 .claude/skills/ 下不存在

S6. 安全与敏感：X 项
   🔴 [严重] .gitignore 未覆盖 .skills/
   🟡 [中等] SKILL.md 中出现疑似 api_key 硬编码

S7. 编排与单体边界：X 项
   🟡 [中等] xxx/SKILL.md 流程超过 10 步且包含分析+生成两类能力
   🟢 [建议] 多 skill 工作流缺少编排方式声明

S8. 实现承载同步：X 项
   🔴 [严重] dev/lint/guard 被错误标记为元开发轨主链路 skill
   🟡 [中等] docs/visualize/foo.html 存在但 PRD 未追踪

━━━ 统计 ━━━

总问题数：N 项
  🔴 严重：X 项 / 🟡 中等：Y 项 / 🟢 建议：Z 项

项目健康度：[优秀 ≥90% / 良好 ≥75% / 一般 ≥60% / 需关注 <60%]
```

#### 对话输出格式 — 通用 4 维（简洁版）

```
[HEALTH] 项目体检报告 — [产品名 / 未设置]

扫描时间：YYYY-MM-DD HH:MM
项目类型：[Node 通用 / Python / 未知]
代码文件：N 个
PRD 状态：[已定稿 / 未找到]

━━━ 扫描结果 ━━━

G1. 异常路径未处理：X 项
   🔴 [严重] src/xxx.js:23 — async 函数未包裹 try-catch

G2. 资源未释放：X 项
   🟡 [中等] setInterval 未配对 clearInterval

G3. 代码-需求一致性：X 项（无 PRD 则整维度跳过）
   🔴 [严重] REQ-B-003 未实现

G4. 日志泄漏敏感信息：X 项
   🟡 [中等] console.log 输出包含 token

━━━ 统计 ━━━

总问题数：N 项
  🔴 严重：X 项 / 🟡 中等：Y 项 / 🟢 建议：Z 项

项目健康度：[优秀 ≥90% / 良好 ≥75% / 一般 ≥60% / 需关注 <60%]
```

#### 文件输出格式（详细版）

写入 `.skills/{product}/docs/health-report.md` 时，每个问题额外包含：
- 问题详细描述
- 影响范围
- 建议修复方式
- 关联的 REQ 编号（如有）

### 第4步：写入待办

扫描发现的 🔴 严重问题自动追加到 `05-todo.md` 的健康扫描章节：

```markdown
### [YYYY-MM-DD] /health 全局体检

🔴 [HEALTH-001] src/api/user.js:23 — async 函数未捕获异常
🔴 [HEALTH-002] 用户管理有创建无删除
🔴 [HEALTH-003] REQ-B-003 数据导出 — 未实现
```

🟡 和 🟢 级别只记录在报告中，不写入待办（避免待办膨胀）。

---

## fix — 修复问题

### 前置条件

必须先执行过 `/health scan`，有扫描报告才能修复。如果没有报告，提示先执行 scan。

### 第1步：列出可修复项

读取最近一次扫描报告，将问题分为三类：

```
[HEALTH FIX] 修复清单

可自动修复（N 项）：
  🔧 [HEALTH-001] src/api/user.js:23 — async 函数未捕获异常
     修复方式：补充 try-catch 包裹
  🔧 [HEALTH-003] src/composables/useAuth.js — isLoading 未重置
     修复方式：在 finally 块中重置
  🔧 [HEALTH-005] 删除操作无二次确认
     修复方式：补充 confirm 弹窗

需操作员决定（M 项）：
  📋 [HEALTH-002] 用户管理有创建无删除
     → 需确认：是否补充删除功能？建议走 /dev start
  📋 [HEALTH-006] REQ-B-003 数据导出未实现
     → 需确认：是否现在实现？建议走 /dev start REQ-B-003

无法自动修复（K 项）：
  ⚠ [HEALTH-004] 架构层循环依赖
     → 建议走 /dev refactor

请选择要修复的项（输入编号，多个用逗号分隔，或输入 "all" 修复所有可自动修复项）：
```

### 第2步：逐个修复

操作员选择后，按顺序逐个修复：

1. **展示修复预览**（每个问题修复前都要确认）：

```
[HEALTH FIX] 修复预览 — HEALTH-001

文件：src/api/user.js:23
问题：async 函数 fetchUser 未捕获异常
修复：包裹 try-catch，catch 中输出错误并重新抛出

修改前：
  const data = await api.get('/user')

修改后：
  try {
    const data = await api.get('/user')
  } catch (error) {
    console.error('fetchUser 失败:', error)
    throw error
  }

→ 确认修复？
```

2. **操作员确认后执行修改**
3. **修改后立即验证**：检查语法是否正确，如果修改导致错误则回滚并标记"修复失败"

### 第3步：修复报告

所有选中的问题处理完后，输出修复报告：

```
[HEALTH FIX] 修复报告

已修复（X 项）：
  ✓ [HEALTH-001] async 函数未捕获异常
  ✓ [HEALTH-005] 删除操作无二次确认

修复失败（Y 项）：
  ✗ [HEALTH-003] isLoading 未重置 — 原因：修改后语法错误，已回滚

已转交其他 Skill（Z 项）：
  → [HEALTH-002] 用户管理补充删除 — 建议执行 /dev start
  → [HEALTH-006] REQ-B-003 数据导出 — 建议执行 /dev start REQ-B-003
  → [HEALTH-004] 循环依赖 — 建议执行 /dev refactor

统计：修复 X 项 | 失败 Y 项 | 转交 Z 项
```

### 第4步：局部重新扫描

修复完成后，自动对修复涉及的文件重新扫描受影响的维度，验证修复是否生效：

```
[HEALTH] 修复后验证

重新扫描：3 个文件 × 2 个维度
  ✓ [HEALTH-001] 已修复，验证通过
  ✓ [HEALTH-005] 已修复，验证通过

修复有效率：100%
```

### 第5步：全局回归验证

修复验证通过后，执行全局回归检查，确认已有功能没被破坏：

1. **编译/启动检查**：
   - 如果项目有 `package.json` → 执行 `npm run build`（或对应构建命令），检查是否有编译错误
   - 如果有 dev server 配置 → 检查启动是否报错（不长期运行，只检查启动阶段）

2. **已完成功能回归**：
   - `Read` `.skills/{product}/docs/05-todo.md`，提取所有状态为"已完成"和"已验收"的任务
   - `Read` `.skills/{product}/docs/03-features.md`，提取所有状态为"已实现"和"已验收"的功能
   - 对比本次 fix 修改的文件列表，检查是否涉及这些已完成功能的代码
   - 如果涉及 → 对受影响的功能逐个检查关键逻辑是否仍完整（`Read` 文件确认核心函数/组件未被误改）

3. **tracemap 交叉验证**：
   - `Read` `.skills/tracemap/{product}.json`（如存在），找出本次修改文件关联的所有 REQ
   - 对这些 REQ 的验收标准做快速检查

4. **回归结果输出**：

```
[HEALTH] 全局回归验证

编译检查：✓ 无错误
已完成功能回归：检查 N 个功能
  ✓ REQ-A-001 用户登录 — 未受影响
  ✓ REQ-A-002 用户注册 — 未受影响
  ⚠ REQ-A-003 用户搜索 — 涉及修改文件，已验证核心逻辑完整

回归通过：所有已有功能正常
```

5. **发现回归问题时**：
   - 立即输出受影响的功能和具体问题
   - **询问操作员**：回滚本次修复 / 手动修正回归问题 / 忽略继续
   - 如果选择回滚 → `git revert` 本次修复的 commit，恢复到修复前状态

```
[HEALTH] ⚠ 回归问题

本次修复影响了以下已有功能：
  ✗ REQ-A-003 用户搜索 — src/composables/useSearch.js 核心逻辑被改动
    修复前：搜索结果按相关度排序
    修复后：排序逻辑被 try-catch 包裹后行为变化

→ 选择处理方式：
  1. 回滚本次所有修复（git revert）
  2. 只回滚影响 REQ-A-003 的修改
  3. 手动修正回归问题
  4. 忽略，继续
```

### 可自动修复 vs 需操作员决定

### 自动修复判断边界

**核心原则**：只有"改动不涉及业务逻辑判断"的问题才能自动修复。如果修复需要理解"这个功能应该怎么工作"，就必须交给操作员决定。

| 可自动修复（纯技术性，不涉及业务判断） | 需操作员决定（涉及业务逻辑或功能设计） |
|-----------|------------|
| 异常未捕获 → 补 try-catch（catch 中 throw 原错误） | CRUD 不闭环 → 需确认补哪些功能 |
| 资源未释放 → 补 removeEventListener/clearInterval | 需求未实现 → 走 /dev 流程 |
| 状态未重置 → 在 finally 块中重置 loading/error 状态 | 架构层问题 → 走 /dev refactor |
| 缺少二次确认 → 在 delete/remove 调用前补 confirm 弹窗 | 功能偏离需求 → 走 /req update |
| 错误提示不明确 → 将 catch 中的通用提示改为包含 error.message | 新增功能 → 走 /dev start |
| aria 标签缺失 → 为 button/a/input 补充 aria-label | 操作路径优化 → 需确认交互方案 |

**判断不了时**：一律归为"需操作员决定"，宁可多问不误改。

#### Skills 项目维度的自动修复边界

| 可自动修复 | 需操作员决定 |
|-----------|------------|
| S2 禁止目录存在（空的 templates/ examples/）→ 重命名或删除 | S2 目录内已有文件 → 需操作员确认迁移 |
| S6 .gitignore 缺 `.skills/` → 追加规则 | S1 frontmatter 缺 description → 需操作员补写文案 |
| S5 CLAUDE.md 孤儿 skill 未登记 → 追加一行指向 | S3 协议冲突（多方写同一文件）→ 需操作员裁决归属 |
| S6 SKILL.md 中的 console.log 含敏感字段 → 删除或脱敏 | S4 全局与项目 skill 版本分叉 → 需操作员确认以谁为准 |
| — | S7 流程超过 10 步或职责混杂 → 需操作员决定是否回 /plan 拆分 |
| — | S8 实现承载与 PRD 不同步 → 需操作员裁决补 PRD 还是改产物 |

#### 通用维度的自动修复边界

| 可自动修复 | 需操作员决定 |
|-----------|------------|
| G1 async 无 try-catch → 补 try-catch 原样抛错 | G3 REQ 未实现 → 走 /dev start |
| G2 定时器/监听器未清理 → 补 clear/remove | 修复方式涉及业务判断 |
| G4 console.log 含敏感字段 → 删除或脱敏 |  |

---

## report — 查看最近报告

### 执行步骤

1. 读取 `.skills/{product}/docs/health-report.md`
   - 不存在 → 输出"暂无扫描记录，请先执行 `/health scan`"并终止
2. 提取最近一次扫描记录（按时间戳取最新的 `### [YYYY-MM-DD]` 段落）
3. 输出完整报告内容
4. 如果报告中有未修复的 🔴 严重问题，末尾追加：
   ```
   ⚠ 仍有 N 个严重问题未修复，建议执行 /health fix
   ```

## history — 历史记录

### 执行步骤

1. 读取 `.skills/{product}/docs/health-report.md`
   - 不存在 → 输出"暂无扫描记录"并终止
2. 提取所有扫描记录的摘要行（日期 + 总问题数 + 各级别数 + 健康度）
3. 计算趋势方向（对比最近两次的严重问题数变化）
4. 输出趋势表：

```
[HEALTH] 历史体检记录

| 时间 | 总问题 | 严重 | 中等 | 建议 | 健康度 |
|------|--------|------|------|------|--------|
| 04-16 | 12 | 3 | 6 | 3 | 75% 良好 |
| 04-10 | 18 | 5 | 8 | 5 | 62% 一般 |
| 04-03 | 25 | 8 | 12 | 5 | 48% 需关注 |

趋势：↑ 改善中（问题数减少，严重问题从 8→3）
```

---

## 健康度计算

```
健康度 = 100 - (严重问题数 × 5 + 中等问题数 × 2 + 建议问题数 × 0.5)

≥ 90%：优秀
≥ 75%：良好
≥ 60%：一般
< 60%：需关注
```

---

## 与其他 Skill 的协同

| Skill | 协同方式 |
|-------|---------|
| `/dev` | 严重问题写入 todo，下次 /dev 唤醒时告知 |
| `/review` | health 报告可作为验收的补充参考 |
| `/req` | 代码-需求一致性检查依赖 PRD |
| `/lint` | 逻辑漏洞检查与 lint 规范检查互补，不重叠 |
| `/guard` | health 发现的偏离可与 guard 日志交叉验证 |

---

## 无参数时（`/health`）

等同于 `/health scan`，进入扫描流程。
