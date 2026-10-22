---
name: scaffold
description: 脚手架搭建。当用户提到"生成组件"、"创建模板"、"新建页面"、"scaffold"、"脚手架"时触发。基于模板生成标准化代码。
argument-hint: "[create|template list]"
allowed-tools: Read Write Edit Glob Grep Bash(mkdir *) Bash(npm *) Bash(npx *)
---

# /scaffold — 脚手架搭建

## 共通规则

1. **需求接收规则**：创建前先确认需求和规范，输出预览后确认再生成
2. **规范遵循**：生成的代码自动遵循 `.skills/{product}/docs/standards.md` 中的规范；若该文件不存在，使用内置默认规范（Vue 3 + Vite + Tailwind CSS 4.x，Linear 风格）
3. **需求关联**：如有对应 PRD 需求，生成时关联需求编号
4. **不覆盖已有**：如目标文件已存在，提示用户选择处理方式（见 create 步骤）

---

## 路径约定

`${CLAUDE_SKILL_DIR}` 指向本 Skill 的安装目录（即 `.claude/skills/scaffold/`）。运行时由 Claude Code 自动解析。

**模板路径降级**：模板加载按以下优先级依次查找，找到即用：
1. `${CLAUDE_SKILL_DIR}/templates/custom/[类型]/` — 用户自定义模板（最高优先）
2. `${CLAUDE_SKILL_DIR}/templates/[类型].vue` 或 `.js` — Skill 自带模板文件
3. **本文件"内置模板"章节中的代码** — 兜底方案，直接从 SKILL.md 中提取对应代码块生成

三级都找不到 → 输出 `[SCAFFOLD] 未找到类型 "[类型]" 的模板` 并终止。降级时输出提醒：
```
[SCAFFOLD] 模板文件缺失，已使用内置默认模板生成。
```

---

## 子命令路由

| 参数 | 执行 |
|------|------|
| `create [类型] [名称]` | → 基于模板生成代码 |
| `template list` | → 查看可用模板 |
| `template delete [名称]` | → 删除指定自定义模板 |
| 无参数 | → 显示可用模板和帮助 |

### 自然语言路由

当操作员使用自然语言而非精确命令时，按以下规则映射：

| 操作员可能的表达 | 映射到 |
|---|---|
| "生成一个组件"、"新建XX组件" | → create component |
| "新建一个页面" | → create page |
| "创建新项目"、"搭个项目" | → create project |
| "有哪些模板" | → template list |

---

## create — 生成代码

`/scaffold create [类型] [名称]`

### 可用类型

| 类型 | 说明 | 生成文件 |
|------|------|---------|
| `component [名称]` | Vue 组件 | `src/components/[Name].vue` |
| `page [名称]` | 页面组件（含路由配置提示） | `src/components/[Name]Page.vue` |
| `composable [名称]` | Composable 函数 | `src/composables/use[Name].js` |
| `api [名称]` | API 模块 | `src/api/[name].js` |
| `data [名称]` | 数据文件 | `src/data/[name]Data.js` |
| `project [名称]` | 完整项目脚手架 | 整个项目目录 |
| `start-scripts` | 智能启动脚本 | `start.bat` + `start.command` |

### 执行步骤

1. **确认参数**：类型 + 名称 + 关联需求（可选）
   - 名称合法性检查：只允许字母、数字、连字符、下划线；若包含空格或特殊字符，提示用户修正后再继续
2. **项目快扫**（本会话未扫过时执行）：
   - Read `package.json` 看构建工具和依赖（Vite/Webpack/无）
   - Glob `src/components/`、`src/pages/`、`src/composables/` 看现有组织方式
   - 检查 `vite.config.js` / `tailwind.config.js` 是否存在
   - 输出一行：`[项目摸底] 类型:XX | 栈:XX | 现有组件目录:src/components/(N 个) → 继续`
   - 摸底结果用于：决定生成文件放哪个目录、是否需要在路由文件中注册、是否需要安装额外依赖
3. **读取规范**：`.skills/{product}/docs/standards.md`
   - 若文件不存在，输出提示 `[SCAFFOLD] standards.md 未找到，使用内置默认规范（Vue 3 + Vite + Tailwind CSS 4.x，Linear 风格）` 并继续
3. **读取模板**：从 `${CLAUDE_SKILL_DIR}/templates/` 加载对应模板
   - 若模板不存在，检查内置模板（见"内置模板"章节）
   - 若内置模板也无对应类型，输出 `[SCAFFOLD] 未找到类型 "[类型]" 的模板，可用类型：component / page / composable / api / data / project / start-scripts` 并终止
4. **目标路径冲突检查**：检查目标文件是否已存在
   - 若已存在，暂停并提示：
     ```
     [SCAFFOLD] 目标文件已存在：src/components/UserProfile.vue
     请选择处理方式：
       1. 跳过（保留原文件，不生成）
       2. 覆盖（用新内容替换原文件）
       3. 重命名（生成为 UserProfile_new.vue）
       4. 取消
     ```
   - 等待用户选择后再继续
5. **如有关联需求**：读取 `03-features.md` 中的功能规格，预填充交互逻辑
6. **输出预览**：展示将要生成的文件内容（含占位符已填充的最终内容）
7. **用户确认**：等待确认后再写入，不自动执行

### 输出格式

```
[SCAFFOLD] 生成预览

类型：Vue 组件
名称：UserProfile
关联需求：REQ-A-005
目标路径：src/components/UserProfile.vue

--- 预览 ---
<script setup>
import { ref, computed } from 'vue'

const props = defineProps({
  ...
})
...
</script>
--- 结束 ---

→ 确认生成？
```

---

## 内置模板

### component — Vue 组件模板

```vue
<script setup>
import { ref, computed } from 'vue'

// Props
const props = defineProps({
  // {{根据需求填充}}
})

// Events
const emit = defineEmits([])

// State
const isLoading = ref(false)

// Methods
const handleAction = () => {
  // {{根据需求填充}}
}
</script>

<template>
  <div class="bg-linear-bg-secondary rounded-2xl border border-linear-border/50 p-6 transition-all duration-300">
    <!-- {{组件内容}} -->
  </div>
</template>

<style scoped>
/* 组件私有样式 */
</style>
```

### page — 页面模板

```vue
<script setup>
import { ref, onMounted } from 'vue'

// State
const isVisible = ref(false)

// Lifecycle
onMounted(() => {
  setTimeout(() => isVisible.value = true, 200)
})
</script>

<template>
  <div class="min-h-screen bg-linear-bg text-linear-text font-sans overflow-x-hidden">
    <!-- 背景光效层 -->
    <div class="fixed top-0 left-1/2 -translate-x-1/2 w-[1000px] h-[600px] bg-linear-accent/10 rounded-full blur-[120px] pointer-events-none z-0 mix-blend-screen"></div>

    <!-- Header -->
    <header class="relative z-10 max-w-7xl mx-auto px-6 py-8">
      <!-- {{Header 内容}} -->
    </header>

    <!-- Main -->
    <main class="relative z-10 max-w-7xl mx-auto px-6">
      <!-- {{主体内容}} -->
    </main>

    <!-- Footer -->
    <footer class="relative z-10 mt-auto">
      <div class="max-w-7xl mx-auto px-6 py-8 flex justify-center">
        <p class="text-xs text-linear-text-secondary/20 font-light tracking-widest">
          © AI Innovation 2026
        </p>
      </div>
    </footer>
  </div>
</template>

<style scoped>
</style>
```

### composable — Composable 模板

```js
import { ref, watchEffect, onUnmounted } from 'vue'

export function use{{Name}}() {
  // State
  const data = ref(null)
  const isLoading = ref(false)
  const error = ref(null)

  // Logic
  const fetch = async () => {
    isLoading.value = true
    error.value = null
    try {
      // {{业务逻辑}}
    } catch (e) {
      error.value = e.message
    } finally {
      isLoading.value = false
    }
  }

  // Cleanup
  onUnmounted(() => {
    // {{清理逻辑}}
  })

  return { data, isLoading, error, fetch }
}
```

### api — API 模块模板

```js
const BASE_URL = import.meta.env.VITE_API_BASE || '/api'

const request = async (url, options = {}) => {
  const res = await fetch(`${BASE_URL}${url}`, {
    headers: { 'Content-Type': 'application/json', ...options.headers },
    ...options,
  })
  if (!res.ok) throw new Error(`${res.status} ${res.statusText}`)
  return res.json()
}

export const {{name}}Api = {
  getList: (params) => request('/{{name}}', { method: 'GET' }),
  getById: (id) => request(`/{{name}}/${id}`, { method: 'GET' }),
  create: (data) => request('/{{name}}', { method: 'POST', body: JSON.stringify(data) }),
  update: (id, data) => request(`/{{name}}/${id}`, { method: 'PUT', body: JSON.stringify(data) }),
  remove: (id) => request(`/{{name}}/${id}`, { method: 'DELETE' }),
}
```

### data — 数据文件模板

```js
export const {{name}}Data = [
  {
    id: 1,
    // {{根据需求填充字段}}
  },
]

export const {{name}}Columns = [
  { key: 'id', label: 'ID', width: '80px' },
  // {{根据需求填充列定义}}
]

export const {{name}}Filters = {
  // {{根据需求填充筛选项}}
}
```

### project — 完整项目脚手架

生成完整的 Vue 3 + Vite + Tailwind 项目，包含：

```
[project-name]/
├── index.html
├── package.json
├── vite.config.js
├── tailwind.config.js        # animation/keyframes 配置
├── src/
│   ├── main.js
│   ├── App.vue
│   ├── style.css             # Tailwind 入口 + @theme 定义
│   ├── components/
│   ├── composables/
│   │   └── useTheme.js       # 主题切换（来自 design-system）
│   ├── data/
│   ├── assets/
│   └── utils/
├── start.bat                  # Windows 启动脚本
└── start.command              # macOS 启动脚本
```

### start-scripts — 启动脚本

生成 `start.bat`（Windows）和 `start.command`（macOS），包含：
- Node.js 环境检测
- 依赖自动安装
- 端口占用检测（杀进程/换端口/取消）
- 自动打开浏览器

---

## template delete — 删除模板

**执行步骤**：

1. 检查 `${CLAUDE_SKILL_DIR}/templates/custom/` 下是否存在指定名称的模板
   - 不存在 → 输出"模板 [名称] 不存在"并终止
   - 存在 → 继续
2. 输出模板信息预览（名称、创建时间、文件数），等操作员确认
3. 确认后删除模板文件
4. 输出确认：`✓ 模板 [名称] 已删除`

**限制**：只能删除 `custom/` 目录下的自定义模板，内置模板（component/page/composable/project/start-scripts）不可删除。

---

## template list — 查看模板

列出所有可用模板（内置 + 项目保存的）：

```
[SCAFFOLD] 可用模板

内置模板：
  component    — Vue 组件（Linear 风格卡片）
  page         — 页面组件（含 Header/Footer/光效）
  composable   — Composable 函数
  api          — API 模块
  data         — 数据文件
  project      — 完整项目脚手架
  start-scripts — 智能启动脚本
```

---

## 无参数时（`/scaffold`）

```
当前产品：[产品名]
可用模板：N 个内置模板

命令：
  /scaffold create component [名称]  — 生成 Vue 组件
  /scaffold create page [名称]       — 生成页面
  /scaffold create project [名称]    — 生成完整项目
  /scaffold template list            — 查看所有模板
```
