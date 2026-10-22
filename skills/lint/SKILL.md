---
name: lint
description: 代码规范化。定义/检查/修复项目代码规范。当用户提到"规范检查"、"代码风格"、"lint"、"格式化"时触发。默认 Vue 3 + Tailwind 预设。
argument-hint: "[init|check|fix|rules]"
disable-model-invocation: true
allowed-tools: Read Write Edit Glob Grep
---

# /lint — 代码规范化

## 共通规则

1. **需求接收规则**：规范变更前先分析影响范围，确认后再执行
2. **中文输出**：所有报告和交互用中文
3. **不破坏已有**：修复规范问题时不能引入功能性 bug

## 前置检查

1. 读取 `.skills/context.json` 获取当前产品
   - **如果 context.json 不存在**：提示"未找到产品上下文，请先执行 `/req init [产品名]` 或手动指定检查范围"
   - **允许无上下文运行**：如果操作员指定了具体文件/目录，跳过产品上下文，直接检查指定范围
2. 检查 `.skills/{product}/docs/standards.md` 是否存在
   - **如果不存在**：提示先执行 `/lint init`
   - **如果操作员只想快速检查**：使用内置默认规则（7 条错误级 + 7 条警告级）作为 fallback，输出提醒"当前使用默认规则，建议执行 /lint init 生成项目规范"
3. 检查是否在 git 仓库中（check 默认模式需要 git diff）
   - **如果不是 git 仓库**：默认模式退化为 `--all`，提醒操作员
4. **项目快扫**（本会话未扫过时执行）：
   - Read `package.json` 看构建工具和主要依赖
   - 检查 `vite.config.js` / `tailwind.config.js` / `tsconfig.json` 等配置文件
   - Glob 看 `src/**/*.{vue,jsx,tsx,ts,js}` 任一存在 → 判定前端类型
   - 输出一行：`[项目摸底] 类型:XX | 栈:XX | 配置:Vite/Tailwind/TS → 继续`
   - 摸底结果决定加载哪组规则集（Vue 项目加 Vue 规则，TS 项目加类型规则）
   - `init` 子命令复用此摸底结果，不重复扫

---

## 子命令路由

| 参数 | 执行 |
|------|------|
| `init` | → 初始化项目代码规范 |
| `check` | → 检查当前代码变更是否符合规范 |
| `check --all` | → 检查全部代码（不仅是变更部分） |
| `fix` | → 自动修复可修复的规范问题 |
| `rules` | → 查看/编辑当前规范规则 |
| `rules add [规则]` | → 添加项目特定规则 |
| `rules delete [规则ID]` | → 删除指定自定义规则 |
| `rules edit [规则ID]` | → 编辑指定自定义规则 |
| 无参数 | → 显示当前规范状态 |

### 自然语言路由

当操作员使用自然语言而非精确命令时，按以下规则映射：

| 操作员可能的表达 | 映射到 |
|---|---|
| "初始化规范"、"设置代码规范" | → init |
| "检查一下代码"、"规范检查" | → check |
| "自动修复"、"帮我修" | → fix |
| "看看规则"、"当前有哪些规范" | → rules |
| "加一条规则" | → rules add |

---

## init — 初始化规范

### 执行步骤

1. **识别技术栈**：
   - 检查项目中是否有 `package.json`、`vite.config.js`、`tailwind.config.js` 等
   - 自动判断技术栈，或询问操作员确认

2. **加载预设规范**：
   - Vue 3 + Tailwind 项目 → 加载 `~/.claude/design-system.md` 作为基础
     - 如果 `~/.claude/design-system.md` 不存在，使用 SKILL.md 中定义的内置默认规则（7 条错误级 + 7 条警告级）作为基础规范，输出提醒：`[LINT] design-system.md 未找到，已使用内置默认规则初始化。`
   - 其他技术栈 → 引导操作员定义基础规范

3. **生成规范文档** `.skills/{product}/docs/standards.md`（使用模板）

4. **输出确认**：
```
✓ 代码规范已初始化

技术栈：Vue 3 + Vite + Tailwind CSS 4.x
预设规范：design-system.md（已加载）
规范文件：.skills/{product}/docs/standards.md

包含：
  - 7 条 错误级禁止项
  - 命名规范（文件、变量、函数、组件）
  - 目录结构规范
  - Vue 编码规范（SFC 顺序、ref 统一、Props 格式）
  - Git 规范（commit 格式、分支命名）
  - 颜色系统规范（linear-* token）

→ 可用 /lint rules 查看完整规则
→ 可用 /lint rules add 添加项目特定规则
```

---

## check — 规范检查

### 执行步骤

1. 读取 `.skills/{product}/docs/standards.md`
2. 获取待检查文件范围：
   - 默认：当前 git 变更的文件（`git diff --name-only`）
   - `--all`：项目 src/ 下所有文件
3. **大项目策略**：当待检查文件数 > 50 时，按以下优先级排序，只检查前 50 个文件：
   1. 本次 git diff 涉及的文件（最高优先）
   2. 最近 7 天内修改过的文件
   3. 其余按文件大小降序（大文件更可能有问题）
   输出时标注"[已截断] 共 N 个文件，本次检查前 50 个"
4. 逐文件逐规则检查
5. 输出违规报告

### 检查规则分级

| 级别 | 含义 | 处理 |
|------|------|------|
| `错误` | 必须修复 | 标红，计入失败 |
| `警告` | 建议修复 | 标黄，不计入失败 |
| `提示` | 仅提示 | 标灰，供参考 |

### 错误级规则（来自 design-system.md 禁止项）

| # | 规则 | 检查方式 |
|---|------|---------|
| E1 | 禁止 Vue 2 语法（Options API、this、mixins） | 搜索 `export default {`、`this.`、`mixins:` |
| E2 | 禁止 `reactive`，统一 `ref` | 搜索 `reactive(` 的使用 |
| E3 | 禁止硬编码 `text-white`/`bg-black` 作为主要色 | 搜索模板中的 `text-white`、`bg-black` |
| E4 | 禁止 Tailwind 默认色（`bg-gray-900` 等） | 搜索 `bg-gray-`、`text-blue-` 等默认色 |
| E5 | 禁止全局状态管理库（Pinia/Vuex） | 搜索 `pinia`、`vuex` import |
| E6 | 禁止 TypeScript（`.ts`/`.tsx` 文件） | 检查文件扩展名 |
| E7 | 禁止无 scoped 的 `<style>`（App.vue 除外） | 搜索 `<style>` 不带 `scoped` |

### warn 级规则

| # | 规则 | 检查方式 |
|---|------|---------|
| W1 | SFC 顺序应为 `<script setup>` → `<template>` → `<style scoped>` | 检查 SFC 三段顺序 |
| W2 | Props 应使用 `defineProps` 对象语法 | 搜索 `defineProps([` 数组语法 |
| W3 | 事件处理函数应用 `handle` 前缀 | 搜索 `@click="` 后的函数名 |
| W4 | 复杂静态数据应抽到 `src/data/` | 检查组件内大段数据定义 |
| W5 | 硬编码魔法值应提取为配置 | 搜索数字常量和字符串常量 |
| W6 | 重复逻辑必须提取为共享模块 | Grep 相同函数名，检查函数体 ≥15 行且在 2+ 文件中出现的相似实现，应提取到 `services/` 或 `composables/shared/` |
| W7 | 模块边界封装 | 检查 composable/service 之间的 import 关系；禁止 composable 直接 import 另一个 composable 的内部函数，共享逻辑必须通过独立的 shared service 暴露 |

### 输出格式

```
[LINT CHECK] 规范检查报告

检查范围：N 个文件
规范版本：{product}/docs/standards.md

错误（必须修复）：
  ✗ E3 | src/components/Header.vue:12
    使用了 `text-white`，应改为 `text-linear-text`
  ✗ E2 | src/composables/useData.js:5
    使用了 `reactive({...})`，应改为 `ref({...})`

警告（建议修复）：
  ⚠ W1 | src/components/Card.vue
    SFC 顺序不正确：<template> 在 <script setup> 前面
  ⚠ W3 | src/components/Form.vue:24
    `@click="submit"` 应改为 `@click="handleSubmit"`

统计：2 个错误 | 2 个警告 | 0 个提示
结论：✗ 有 2 个错误需修复
```

---

## fix — 自动修复

### 执行步骤

1. **先执行 check**：获取当前所有违规项
2. **分类**：将违规项分为"可自动修复"和"需手动修复"两组
3. **展示修复预览**（修改前必须确认）：

```
[LINT FIX] 修复预览

可自动修复（N 项）：
  🔧 E3 | src/components/Header.vue:12
     text-white → text-linear-text
  🔧 E2 | src/composables/useData.js:5
     reactive({...}) → ref({...})

需手动修复（M 项）：
  ✋ E1 | src/components/Old.vue:3
     Options API → 需重构为 <script setup>

→ 确认自动修复以上 N 项？（手动项需操作员自行处理）
```

4. **操作员确认后执行修复**：
   - 逐文件修改，每个文件修改后立即验证语法正确性
   - 如果修改导致语法错误 → 回滚该文件，标记为"修复失败"
5. **输出修复报告**：

```
[LINT FIX] 修复报告

已修复（X 项）：
  ✓ E3 | src/components/Header.vue:12
  ✓ E2 | src/composables/useData.js:5

修复失败（Y 项）：
  ✗ W1 | src/components/Card.vue — 原因：调整顺序后语法错误，已回滚

需手动修复（M 项）：
  ✋ E1 | src/components/Old.vue:3

统计：修复 X 项 | 失败 Y 项 | 手动 M 项
```

### 可自动修复 vs 需手动修复

| 可自动修复 | 不可自动修复（需手动） |
|-----------|---------------------|
| `text-white` → `text-linear-text` | 架构层面的依赖方向问题 |
| `reactive(` → `ref(` | 业务逻辑重构 |
| SFC 顺序调整 | 模块边界重新划分 |
| `handle` 前缀添加 | 复杂数据抽取 |

---

## rules — 查看/编辑规范

`/lint rules`：输出当前所有规则列表和级别。

### rules add — 添加项目特定规则

`/lint rules add [规则描述]`

执行步骤：

1. **解析规则描述**：从操作员输入中提取规则内容
2. **确认规则详情**：

```
[LINT RULES] 新增规则确认

规则内容：[描述]
建议级别：[错误/警告/提示]（附理由）
检查方式：[具体如何检测]
编号：[自动分配，如 E8 / W6 / I1]

→ 确认添加？可调整级别。
```

3. **操作员确认后写入** `.skills/{product}/docs/standards.md`
4. **输出更新确认**：当前规则总数和新增规则摘要

---

## rules delete — 删除规则

1. 读取 `standards.md`，查找指定规则 ID
   - 不存在 → 输出"规则 [ID] 不存在"并终止
   - 是内置规则（E1-E7, W1-W7）→ 输出"内置规则不可删除，只能通过 rules edit 调整严重级别"并终止
2. 输出规则内容预览，等操作员确认
3. 确认后从 `standards.md` 中移除该规则
4. 输出确认：`✓ 规则 [ID] 已删除`

## rules edit — 编辑规则

1. 读取 `standards.md`，查找指定规则 ID
   - 不存在 → 输出"规则 [ID] 不存在"并终止
2. 展示当前规则内容，询问操作员要修改哪部分（描述/检查方式/严重级别）
3. 操作员给出修改后，输出修改预览（修改前 vs 修改后），等确认
4. 确认后更新 `standards.md`
5. 输出确认：`✓ 规则 [ID] 已更新`

---

## 与其他 Skill 的协同

| Skill | 协同方式 |
|-------|---------|
| `/dev check --all` | 一键同时跑需求对齐 + 规范检查 |
| `/dev done` 第3关 | 可维护性检查中引用 lint 规则 |
| `/scaffold` | 生成代码时自动遵循 lint 规范 |
| `/plan create` | 读取规范文档作为技术约束 |

---

## 无参数时（`/lint`）

```
当前产品：[产品名]
规范状态：[已初始化 / 未初始化]
规则数：N 个错误 | M 个警告 | K 个提示

命令：
  /lint init       — 初始化规范
  /lint check      — 检查变更文件
  /lint check --all — 检查全部文件
  /lint fix        — 自动修复
  /lint rules      — 查看规则
```
