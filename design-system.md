# 团队前端项目规范 — Linear 风格 + Vue 3

> 本文件是团队新建前端项目时的完整开发规范。全局 CLAUDE.md 中有精简版索引，AI 需要细节时来读这个文件。

---

## 一、技术栈（硬性要求）

| 层 | 选型 | 版本 |
|---|---|---|
| 框架 | Vue 3 Composition API + `<script setup>` | 3.5+ |
| 构建 | Vite | 7+ |
| 样式 | Tailwind CSS（`@theme` 指令定义 token） | 4.x |
| 语言 | JavaScript（非 TypeScript） | ES2022+ |
| 设计风格 | Linear App 风格，亮暗主题切换，默认亮色/跟随系统 | — |

---

## 二、颜色系统（亮暗双主题）

### 2.0 色彩使用原则（最高优先级）

**克制用色，灰度为主，彩色只服务于重要信息。**

- 页面 90% 的内容应该是**灰度体系**（背景、边框、正文、次要文字）
- 彩色**只用于**：主操作按钮、关键状态指示、数据高亮、品牌强调
- 普通文字、标签、分割线、卡片背景**一律灰度**，不加彩色
- 同一视图中彩色元素不超过 2-3 处，避免视觉噪音
- 如果不确定该不该用彩色，**就不用**——默认灰度永远不会出错

| 场景 | 正确 | 错误 |
|------|------|------|
| 普通按钮 | `border-linear-border text-linear-text` | `bg-linear-accent text-white` |
| 主操作按钮 | `bg-linear-accent text-white`（一个页面最多 1-2 个） | 所有按钮都用强调色 |
| 状态标签 | 成功/失败/警告用对应语义色 | 所有标签都带彩色背景 |
| 图标 | `text-linear-text-secondary`（灰色） | 每个图标一个颜色 |
| 数据图表 | 彩色（这是彩色的正确用途） | — |
| Section 标题 | `text-linear-text`（白/黑） | `text-linear-accent` |
| 竖线装饰 | 一个 section 一处彩色点缀即可 | 每个元素都加彩色装饰 |

### 2.1 实现原理

Tailwind 4.x 的 `@theme` 生成 `:root` 级 CSS 变量，作为**亮色默认值**。用 `[data-theme="dark"]` 选择器覆盖为暗色。主题优先级：**系统偏好 → 用户手动切换 → 默认亮色**。

### 2.2 亮色主题 Token（默认，在 `@theme` 中定义）

```css
@theme {
  /* 背景层级：由浅到深 */
  --color-linear-bg: #FFFFFF;            /* 页面底色 */
  --color-linear-bg-secondary: #F5F5F5;  /* 卡片/区块背景 */
  --color-linear-bg-tertiary: #EBEBEB;   /* 悬停/三级背景 */

  /* 边框 */
  --color-linear-border: #E0E0E0;

  /* 文字 */
  --color-linear-text: #1A1A1A;          /* 主文字 */
  --color-linear-text-secondary: #6B7280; /* 次要文字 */

  /* 品牌色 */
  --color-linear-accent: #4F46E5;        /* 主强调色（Indigo） */
  --color-linear-accent-hover: #4338CA;  /* 强调色悬停态 */

  /* AI 专属色 */
  --color-linear-ai-primary: #9333EA;    /* 紫色 */
  --color-linear-ai-secondary: #DB2777;  /* 粉色，用于渐变终点 */

  /* 功能色 */
  --color-linear-accent-glow: #6366f1;   /* 辉光 */
  --color-linear-success: #059669;       /* 成功 */
}
```

### 2.3 暗色主题 Token（用 `[data-theme="dark"]` 覆盖）

```css
[data-theme="dark"] {
  --color-linear-bg: #0D0D0D;
  --color-linear-bg-secondary: #1A1A1A;
  --color-linear-bg-tertiary: #262626;
  --color-linear-border: #333333;
  --color-linear-text: #E5E5E5;
  --color-linear-text-secondary: #A3A3A3;
  --color-linear-accent: #5E6AD2;
  --color-linear-accent-hover: #7C85E0;
  --color-linear-accent-glow: #818cf8;
  --color-linear-success: #10b981;
  --color-linear-ai-primary: #a855f7;
  --color-linear-ai-secondary: #ec4899;

  color-scheme: dark;
}
```

### 2.4 主题切换 Vue 实现模式

```js
// src/composables/useTheme.js
import { ref, watchEffect } from 'vue'

// 优先级：localStorage > 系统偏好 > 默认亮色
function getInitialTheme() {
  const stored = localStorage.getItem('theme')
  if (stored) return stored
  if (window.matchMedia('(prefers-color-scheme: dark)').matches) return 'dark'
  return 'light'
}

const theme = ref(getInitialTheme())

export function useTheme() {
  // 响应式同步到 DOM
  watchEffect(() => {
    document.documentElement.setAttribute('data-theme', theme.value)
    localStorage.setItem('theme', theme.value)
  })

  // 监听系统主题变化（用户未手动设置时跟随系统）
  window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', (e) => {
    if (!localStorage.getItem('theme')) {
      theme.value = e.matches ? 'dark' : 'light'
    }
  })

  const toggleTheme = () => {
    theme.value = theme.value === 'dark' ? 'light' : 'dark'
  }

  return { theme, toggleTheme }
}
```

```html
<!-- 主题切换按钮组件示例 -->
<button @click="toggleTheme" class="p-2 rounded-lg bg-linear-bg-secondary border border-linear-border hover:bg-linear-bg-tertiary transition-colors">
  <svg v-if="theme === 'dark'" class="w-5 h-5 text-linear-text-secondary" ...><!-- sun icon --></svg>
  <svg v-else class="w-5 h-5 text-linear-text-secondary" ...><!-- moon icon --></svg>
</button>
```

### 2.5 历史记录组件（必选）

每个项目必须内置历史记录功能，让用户可以回溯和恢复之前的操作会话。

#### UI 位置与交互

- 按钮位置：主题切换按钮的**左侧**，同一行工具栏
- 点击展开侧边栏面板（从右侧滑入，必须用 `<Transition>` 包裹，禁止瞬切）
- 列表按时间倒序，每条显示：时间、摘要标签、缩略图预览、状态标记
- 支持：单条删除、清空全部、点击恢复会话
- 展开/收缩过渡：遵循 4.6 节规范，侧边栏用 `translate-x` + `opacity` 组合过渡

```html
<!-- 历史记录按钮（放在主题切换按钮左侧） -->
<button @click="showHistory = !showHistory" class="p-2 rounded-lg bg-linear-bg-secondary border border-linear-border hover:bg-linear-bg-tertiary transition-colors relative">
  <svg class="w-5 h-5 text-linear-text-secondary" ...><!-- clock/history icon --></svg>
  <span v-if="historyCount > 0" class="absolute -top-1 -right-1 w-4 h-4 rounded-full bg-linear-accent text-[10px] text-white flex items-center justify-center">{{ historyCount > 9 ? '9+' : historyCount }}</span>
</button>

<!-- 侧边栏面板（必须 Transition 包裹，禁止瞬切） -->
<Transition
  enter-active-class="transition-all duration-300 ease-out"
  leave-active-class="transition-all duration-200 ease-in"
  enter-from-class="translate-x-full opacity-0"
  enter-to-class="translate-x-0 opacity-100"
  leave-from-class="translate-x-0 opacity-100"
  leave-to-class="translate-x-full opacity-0"
>
  <aside v-if="showHistory" class="fixed top-0 right-0 h-full w-80 bg-linear-bg border-l border-linear-border shadow-xl z-50">
    <!-- 历史记录列表内容 -->
  </aside>
</Transition>
```

#### 存储架构：localStorage 索引 + IndexedDB 完整数据

| 层 | 存什么 | 为什么 |
|----|--------|--------|
| localStorage | 轻量索引（id、时间、摘要、缩略图、状态） | 快速渲染列表，无需打开 IndexedDB |
| IndexedDB | 完整会话数据（原始数据、分析结果、用户操作状态） | 大容量存储，不受 localStorage 5MB 限制 |

#### useHistory composable 模式

```js
// src/composables/useHistory.js — 通用骨架，按项目需求填充 payload 字段
import { ref, computed } from 'vue'

const INDEX_KEY = '{project}_history_index'  // 替换 {project} 为项目标识
const DB_NAME = '{project}_db'
const STORE_NAME = 'sessions'
const MAX_INDEX_BYTES = 5 * 1024 * 1024  // localStorage 索引上限 5MB

export function useHistory() {
  const indexList = ref(loadIndex())

  const historyList = computed(() =>
    [...indexList.value].sort((a, b) => b.savedAt - a.savedAt)
  )
  const historyCount = computed(() => indexList.value.length)

  // 必须实现的方法：
  // saveSession(payload)    — 操作完成时自动调用，写入 IndexedDB + 更新索引
  // updateSession(id, payload) — 同一会话内更新已有记录
  // loadSession(id)         — 点击历史条目时恢复完整数据
  // deleteSession(id)       — 单条删除（索引 + IndexedDB 同步清理）
  // clearAll()              — 清空全部
  // refreshIndex()          — 重新从 localStorage 加载索引

  return { historyList, historyCount, saveSession, updateSession, loadSession, deleteSession, clearAll, refreshIndex }
}
```

#### 存储淘汰策略（FIFO）

```
保存时检查 → JSON.stringify(indexList).length > 5MB?
  → 是：从最旧的开始逐条删除（索引 + IndexedDB 同步），直到低于阈值
  → 否：正常保存
```

#### 索引条目字段（localStorage）

| 字段 | 类型 | 说明 |
|------|------|------|
| `id` | string | 唯一标识，格式 `h_{timestamp}_{random4}` |
| `savedAt` | number | 保存时间戳 |
| `label` | string | 摘要标签（如首个文件名、操作描述） |
| `imageCount` | number | 关联项数量（可选，按项目需求） |
| `referenceThumb` | string | 主缩略图 base64（可选） |
| `previewThumbs` | string[] | 预览缩略图数组（可选） |
| `status` | string | 状态标记（按项目定义，如 no-issue/unhandled/fixed） |

#### 自动保存时机

- 用户完成一次完整操作后自动调用 `saveSession`
- 同一会话内后续操作调用 `updateSession` 覆盖更新
- 不要在每次微操作时保存，避免索引膨胀

### 2.6 亮色主题视觉适配要点

| 暗色模式 | 亮色模式等效 |
|----------|-------------|
| `bg-white/[0.02]` | `bg-black/[0.02]` |
| `bg-white/5` | `bg-black/5` |
| `text-white` | `text-linear-text`（跟随主题） |
| `text-white/40` | `text-linear-text-secondary`（跟随主题） |
| 背景光效 `blur-[120px]` | 亮色下降低 opacity 或隐藏 |
| `shadow-[0_0_8px_rgba(...)]` 辉光 | 亮色下改用 `shadow-md` 投影 |

**关键原则**：尽量用 `linear-*` token 而非硬编码 `text-white`/`bg-black`，这样主题切换时自动适配。对于 `bg-white/[0.02]` 这类半透明叠加，需要用 CSS 变量或条件 class 处理。

### 2.6 使用规则

- **必须**用 `linear-*` token（如 `bg-linear-bg`、`text-linear-text-secondary`），禁止 Tailwind 默认色（`bg-gray-900`）
- **禁止**在 `tailwind.config.js` 中重复定义 `@theme` 已有的颜色，config 只放 animation/keyframes/backgroundImage
- 数据可视化的语义色可用硬编码 hex + opacity（如 `bg-[#6B8AFF]/10`），但需通过 colorMap 对象统一管理
- **文字颜色**优先用 `text-linear-text` / `text-linear-text-secondary`，避免硬编码 `text-white`

### 2.7 数据可视化色板（亮暗通用）

| 用途 | 暗色 | 亮色 | 示例 |
|------|------|------|------|
| 蓝 | `#6B8AFF` | `#4F6ADF` | 编码提效、IT 技术 |
| 紫 | `#A78BFA` | `#8B5CF6` | 内容生成、AI 创新 |
| 青 | `#5EEAD4` | `#14B8A6` | 智能分析、协作 |
| 琥珀 | `#FCD34D` | `#D97706` | 传统流程、警告 |
| 粉 | `#F472B6` | `#DB2777` | AI 渐变终点 |

> 亮色下数据可视化色需要更高饱和度/更深色值，确保在白色背景上有足够对比度。

### 2.8 colorMap 模式（组件内颜色映射）

```js
const colorMap = {
  blue: {
    bg: 'bg-[#6B8AFF]/10',
    text: 'text-[#6B8AFF]',
    dot: 'bg-[#6B8AFF]',
    tagBg: 'bg-[#6B8AFF]/8',
    tagText: 'text-[#6B8AFF]/70'
  },
  // ... 其他颜色同理
}
```

---

## 三、视觉模式

### 3.1 卡片

```html
<!-- 标准玻璃态卡片（暗色） -->
<div class="bg-linear-bg-secondary/40 backdrop-blur-md rounded-3xl border border-linear-border/50 p-6">

<!-- 标准卡片（亮色友好，推荐新项目使用） -->
<div class="bg-linear-bg-secondary rounded-3xl border border-linear-border/50 p-6">

<!-- 轻量卡片（列表项） -->
<div class="bg-linear-bg-secondary/20 rounded-2xl p-4 hover:bg-linear-bg-secondary/40 transition-all duration-300">
```

- 圆角：大卡片 `rounded-3xl`，小卡片 `rounded-2xl`，按钮/标签 `rounded-xl` 或 `rounded-full`
- 背景：优先用 `bg-linear-bg-secondary`（主题自适应），需要玻璃态时加 `/40 backdrop-blur-md`
- 边框：`border border-linear-border/50`
- 悬停：`hover:bg-linear-bg-tertiary` + `hover:-translate-y-0.5` + `transition-all duration-300`
- **亮暗兼容提示**：避免 `bg-white/[0.02]`，改用 `bg-linear-bg-secondary/20`，这样两个主题下都能正确显示

### 3.2 Section 标题

```html
<!-- 带竖线装饰的标题 -->
<div class="flex items-center gap-4 mb-6">
  <h2 class="text-lg font-bold text-white flex items-center gap-2">
    <div class="w-1 h-6 bg-linear-ai-primary rounded-full"></div>
    标题文字
  </h2>
  <div class="h-[1px] flex-1 bg-linear-border"></div>
</div>

<!-- 居中胶囊标题 -->
<h2 class="text-sm font-semibold text-linear-text-secondary uppercase tracking-[0.2em] px-4 py-2 border border-linear-border rounded-full backdrop-blur-md">
```

### 3.3 背景光效

```html
<!-- 顶部环境光 -->
<div class="fixed top-0 left-1/2 -translate-x-1/2 w-[1000px] h-[600px] bg-linear-accent/10 rounded-full blur-[120px] pointer-events-none z-0 mix-blend-screen"></div>

<!-- 组件内局部光晕 -->
<div class="absolute top-0 right-0 w-32 h-32 bg-linear-ai-primary/10 rounded-full blur-3xl"></div>
```

### 3.4 Tab 导航

```html
<nav class="inline-flex items-center p-1.5 bg-linear-bg-secondary/50 rounded-full border border-linear-border/50 backdrop-blur-md">
  <button class="px-6 py-2 rounded-full text-sm font-medium transition-all duration-300">
```

### 3.5 SVG 图标规范

- `viewBox="0 0 24 24"`，`fill="none"`，`stroke="currentColor"`
- `stroke-width="1.5"`（细线风格）或 `stroke-width="2"`（标准）
- `stroke-linecap="round"` + `stroke-linejoin="round"`
- 尺寸：`w-5 h-5`（标准）、`w-3 h-3`（小图标）

---

## 四、动画系统

### 4.1 全局动画（tailwind.config.js 中定义）

```js
animation: {
  'fade-in': 'fadeIn 0.8s ease-out forwards',
  'fade-in-up': 'fadeInUp 0.8s ease-out forwards',
  'draw-line': 'drawLine 2s ease-out forwards',
  'pulse-slow': 'pulse 4s cubic-bezier(0.4, 0, 0.6, 1) infinite',
}
```

### 4.2 SVG 路径绘制动画

```html
<animate attributeName="stroke-dashoffset" :from="totalLength" to="0"
  dur="2s" fill="freeze" calcMode="spline" keySplines="0.4 0 0.2 1" />
```

### 4.3 数值滚动动画（onMounted + requestAnimationFrame）

```js
onMounted(() => {
  const duration = 1500
  const start = performance.now()
  const animate = (now) => {
    const elapsed = now - start
    const percent = Math.min(elapsed / duration, 1)
    const eased = percent === 1 ? 1 : 1 - Math.pow(2, -10 * percent) // easeOutExpo
    value.value = Math.round(eased * targetValue)
    if (percent < 1) requestAnimationFrame(animate)
  }
  requestAnimationFrame(animate)
})
```

### 4.4 Vue Transition 模式

```html
<!-- 方向性切换 -->
<Transition :name="transitionName" mode="out-in">
  <div :key="currentId">...</div>
</Transition>
```

```css
/* 前进 */
.slide-next-enter-from { opacity: 0; transform: translateX(30px); }
.slide-next-leave-to   { opacity: 0; transform: translateX(-30px); }

/* 后退 */
.slide-back-enter-from { opacity: 0; transform: translateX(-30px); }
.slide-back-leave-to   { opacity: 0; transform: translateX(30px); }

/* 折叠 */
.collapse-enter-from, .collapse-leave-to { opacity: 0; transform: translateY(-8px); }
```

### 4.6 状态切换过渡规范（强制）

凡是涉及**展开/收缩、显示/隐藏、Tab切换、开关切换、手风琴、下拉菜单**等状态变化的交互，**必须添加过渡动画**，禁止瞬切。

| 场景 | 推荐实现 | 示例 |
|------|---------|------|
| 展开/收缩（高度变化） | `<Transition>` + `max-height` 或 `grid-template-rows: 0fr→1fr` | 手风琴、折叠面板、详情展开 |
| 显示/隐藏（出现/消失） | `<Transition name="fade">` 或 `fade-in-up` | 弹窗、Toast、Tooltip |
| Tab/内容切换 | `<Transition mode="out-in">` + slide 方向 | Tab 面板、步骤切换 |
| 开关/选中态 | `transition-all duration-200` | Toggle、Checkbox、Radio |
| 列表增删 | `<TransitionGroup>` | 动态列表项增删 |

**默认参数**：
- 时长：`duration-200`（快速反馈）到 `duration-300`（内容切换），禁止超过 `500ms`
- 缓动：`ease-out`（展开）、`ease-in`（收起）、`ease-in-out`（切换）
- 高度动画优先用 `grid-template-rows` 方案（性能优于 `max-height`，无需预设最大值）

**grid-template-rows 展开/收缩模式**：

```css
.collapse-wrapper {
  display: grid;
  grid-template-rows: 0fr;
  transition: grid-template-rows 300ms ease-out;
}
.collapse-wrapper.is-open {
  grid-template-rows: 1fr;
}
.collapse-wrapper > .collapse-content {
  overflow: hidden;
}
```

**Vue Transition 折叠模式**：

```html
<Transition name="collapse">
  <div v-if="isOpen" class="overflow-hidden">
    <!-- 内容 -->
  </div>
</Transition>
```

```css
.collapse-enter-active, .collapse-leave-active {
  transition: opacity 200ms ease, transform 200ms ease;
}
.collapse-enter-from, .collapse-leave-to {
  opacity: 0;
  transform: translateY(-8px);
}
```

**判断原则**：如果用户能感知到"状态变了"，就必须有过渡。过渡不是装饰，是状态变化的视觉反馈。

### 4.5 SVG 辉光滤镜

```xml
<filter id="glow" x="-20%" y="-20%" width="140%" height="140%">
  <feGaussianBlur stdDeviation="4" result="coloredBlur" />
  <feMerge>
    <feMergeNode in="coloredBlur" />
    <feMergeNode in="SourceGraphic" />
  </feMerge>
</filter>
```

---

## 五、Vue 3 编码规范

### 5.1 组件结构（SFC 顺序）

```vue
<script setup>
// 1. Vue 核心 API
import { ref, computed, onMounted } from 'vue'
// 2. 外部数据/工具
import flowData from '../data/flowData'
// 3. 子组件
import ResultCard from './ResultCard.vue'

// 4. Props & Emits
const props = defineProps({
  tabs: { type: Array, required: true },
  activeTab: { type: String, required: true }
})
defineEmits(['update:activeTab'])

// 5. 响应式状态
const isVisible = ref(false)
const currentId = ref('initial')

// 6. 计算属性
const currentItem = computed(() => data.find(d => d.id === currentId.value))

// 7. 方法（handle 前缀）
const handleOptionClick = (option) => { /* ... */ }
const handleRestart = () => { /* ... */ }

// 8. 生命周期
onMounted(() => {
  setTimeout(() => isVisible.value = true, 200)
})
</script>

<template>
  <!-- 模板内容 -->
</template>

<style scoped>
/* 组件私有样式 */
</style>
```

### 5.2 响应式数据

- **统一用 `ref`**，禁止 `reactive`
- `computed` 用于派生状态
- `onMounted` 用于初始化动画（配合 `requestAnimationFrame` 或 `setTimeout`）

### 5.3 Props & Events

- `defineProps` 使用**对象语法** + `type` + `required`
- `defineEmits` 使用**数组语法**：`defineEmits(['update:activeTab'])`
- 双向绑定用 `update:xxx` 事件模式
- 事件处理函数用 `handle` 前缀

### 5.4 模板语法

- 条件渲染优先 `v-if`，动画场景用 `v-show`（配合 `<Transition>`）
- `v-for` 必须绑定唯一 `:key`（优先用 id/name，备选 index）
- Class 绑定用数组语法 + 三元运算符：`:class="[base, active ? 'text-white' : 'text-gray']"`
- 动态样式用 `:style` 对象绑定

### 5.5 状态管理

- **无全局状态管理库**（无 Pinia/Vuex）
- 本地状态为主，父子通信用 Props Down / Events Up
- 复杂静态数据抽取到 `src/data/` 目录

### 5.6 样式规范

- 100% 使用 `<style scoped>`
- Tailwind utility classes 为主
- 组件内自定义 keyframes 放在 scoped style 中
- 无 CSS-in-JS 库

---

## 六、布局系统

### 6.1 页面结构

```html
<div class="min-h-screen bg-linear-bg text-linear-text font-sans overflow-x-hidden">
  <!-- 背景光效层 (fixed, z-0) -->
  <!-- Header (relative, z-10, max-w-7xl mx-auto px-6) -->
  <!-- Main (relative, z-10, max-w-7xl mx-auto px-6) -->
  <!-- Footer（必须） -->
</div>
```

### 6.2 页脚版权（所有网页应用必须包含）

```html
<footer class="relative z-10 mt-auto">
  <div class="max-w-7xl mx-auto px-6 py-8 flex justify-center">
    <p class="text-xs text-linear-text-secondary/20 font-light tracking-widest">
      © AI Innovation 2026
    </p>
  </div>
</footer>
```

要点：
- `text-xs` + `font-light` + `tracking-widest` — 小号、细体、宽字距，极度弱化
- `text-linear-text-secondary/20` — 20% 透明度，几乎隐入背景，不干扰主体内容
- 居中、无装饰、无链接，纯静态文本
- 放在 `min-h-screen` 容器底部，`mt-auto` 确保始终贴底

### 6.2 网格

- 主布局：`grid grid-cols-1 lg:grid-cols-3 gap-6`
- 卡片列表：`grid grid-cols-1 md:grid-cols-2 gap-6`
- 按钮组：`grid grid-cols-2 gap-4`

### 6.3 间距

- Section 间距：`gap-10`
- 卡片内间距：`p-6`（大）、`p-4`（小）
- 标题与内容：`mb-6`
- 最大宽度：`max-w-7xl`（页面）、`max-w-2xl`（居中内容）

---

## 七、数据结构模式

### 7.1 常量数据（组件内）

```js
const contacts = [
  {
    category: '分类名',
    description: '描述',
    icon: 'question',
    color: 'blue',
    people: [{ name: '张三', role: '角色' }],
    examples: ['示例1', '示例2']
  }
]
```

### 7.2 外部数据文件（src/data/）

```js
// src/data/flowData.js
export default {
  title: "标题",
  questions: [
    { id: "q1", text: "问题?", options: [{ label: "是", next: "q2" }, { label: "否", next: "r1" }] }
  ],
  results: [
    { id: "r1", title: "结果", desc: "描述", color: "blue", explanation: "详细说明" }
  ]
}
```

---

## 7.5、智能启动脚本（每个新项目必须创建）

根据用户操作系统创建对应的启动脚本，放在项目根目录。

### macOS: `start.command`

```bash
#!/bin/bash
cd "$(dirname "$0")"

echo "================================"
echo "  项目启动中..."
echo "================================"

# 1. 检查 Node.js
if ! command -v node &> /dev/null; then
  echo "❌ 未检测到 Node.js，请先安装: https://nodejs.org"
  read -p "按回车退出..."
  exit 1
fi

# 2. 检查依赖
if [ ! -d "node_modules" ]; then
  echo "📦 首次运行，正在安装依赖..."
  npm install
fi

# 3. 端口检测（默认 5173）
PORT=5173
if lsof -i :$PORT &> /dev/null; then
  echo ""
  echo "⚠️  端口 $PORT 已被占用"
  echo ""
  echo "  1) 杀掉占用进程，继续使用 $PORT"
  echo "  2) 换用其他端口"
  echo "  3) 取消启动"
  echo ""
  read -p "请选择 [1/2/3]: " choice
  case $choice in
    1)
      lsof -ti :$PORT | xargs kill -9
      echo "✅ 已释放端口 $PORT"
      ;;
    2)
      read -p "请输入新端口号: " PORT
      ;;
    3)
      echo "已取消"
      exit 0
      ;;
  esac
fi

# 4. 启动项目并自动打开浏览器
echo ""
echo "🚀 启动开发服务器 (端口: $PORT)..."
echo ""

# 后台延迟打开浏览器（等待 vite 就绪）
(sleep 2 && open "http://localhost:$PORT") &

npx vite --port $PORT
```

> 创建后需执行 `chmod +x start.command`

### Windows: `start.bat`

```bat
@echo off
chcp 65001 >nul
cd /d "%~dp0"

echo ================================
echo   项目启动中...
echo ================================

:: 1. 检查 Node.js
where node >nul 2>nul
if %errorlevel% neq 0 (
  echo ❌ 未检测到 Node.js，请先安装: https://nodejs.org
  pause
  exit /b 1
)

:: 2. 检查依赖
if not exist "node_modules" (
  echo 📦 首次运行，正在安装依赖...
  call npm install
)

:: 3. 端口检测（默认 5173）
set PORT=5173
netstat -ano | findstr ":%PORT% " | findstr "LISTENING" >nul 2>nul
if %errorlevel% equ 0 (
  echo.
  echo ⚠️  端口 %PORT% 已被占用
  echo.
  echo   1^) 杀掉占用进程，继续使用 %PORT%
  echo   2^) 换用其他端口
  echo   3^) 取消启动
  echo.
  set /p choice="请选择 [1/2/3]: "
  if "!choice!"=="1" (
    for /f "tokens=5" %%a in ('netstat -ano ^| findstr ":%PORT% " ^| findstr "LISTENING"') do taskkill /PID %%a /F >nul 2>nul
    echo ✅ 已释放端口 %PORT%
  ) else if "!choice!"=="2" (
    set /p PORT="请输入新端口号: "
  ) else (
    echo 已取消
    exit /b 0
  )
)

:: 4. 启动项目并自动打开浏览器
echo.
echo 🚀 启动开发服务器 (端口: %PORT%)...
echo.

:: 后台延迟打开浏览器（等待 vite 就绪）
start "" cmd /c "timeout /t 3 /nobreak >nul && start http://localhost:%PORT%"

npx vite --port %PORT%
```

> Windows 脚本需在顶部加 `setlocal enabledelayedexpansion` 以支持 `!choice!` 变量延迟展开。

---

## 八、UI 交互规范

### 8.1 图片上传

**一个区域，三种上传方式**：点击、拖拽、粘贴（Ctrl+V），共用同一个交互区域，禁止拆成多个独立区域。

**核心 UX 原则**：
- 空状态时，整个区域就是上传入口（点击触发文件选择、拖入触发上传、粘贴触发上传）
- 有图片后，上传区域缩小为底部的"继续添加"入口，主体展示预览
- 禁止出现独立的"上传按钮"和独立的"拖拽区域"两个分离的交互区

**组件结构**

```vue
<script setup>
import { ref, onMounted, onUnmounted } from 'vue'

const props = defineProps({
  accept: { type: String, default: 'image/*' },
  maxSize: { type: Number, default: 10 },       // MB
  maxCount: { type: Number, default: 50 },
  multiple: { type: Boolean, default: true }
})

const emit = defineEmits(['update:files'])

const fileInput = ref(null)
const isDragging = ref(false)
const previews = ref([])

const handleClick = () => fileInput.value?.click()

const handleFiles = (fileList) => {
  const files = Array.from(fileList).filter(f => {
    if (!f.type.startsWith('image/')) return false
    if (f.size > props.maxSize * 1024 * 1024) return false
    return true
  })
  const remaining = props.maxCount - previews.value.length
  files.slice(0, remaining).forEach(file => {
    previews.value.push({
      file,
      url: URL.createObjectURL(file),
      name: file.name
    })
  })
  emit('update:files', previews.value)
}

const handleDrop = (e) => {
  isDragging.value = false
  handleFiles(e.dataTransfer.files)
}

const handleInputChange = (e) => {
  handleFiles(e.target.files)
  e.target.value = ''  // 允许重复选择同一文件
}

// 全局粘贴监听（Ctrl+V 上传）
const handlePaste = (e) => {
  const items = e.clipboardData?.items
  if (!items) return
  const files = []
  for (const item of items) {
    if (item.type.startsWith('image/')) {
      files.push(item.getAsFile())
    }
  }
  if (files.length) handleFiles(files)
}

const handleRemove = (index) => {
  URL.revokeObjectURL(previews.value[index].url)
  previews.value.splice(index, 1)
  emit('update:files', previews.value)
}

onMounted(() => document.addEventListener('paste', handlePaste))
onUnmounted(() => document.removeEventListener('paste', handlePaste))
</script>
```

**模板结构**

```html
<template>
  <div
    @dragover.prevent="isDragging = true"
    @dragleave="isDragging = false"
    @drop.prevent="handleDrop"
  >
    <input ref="fileInput" type="file" :accept="accept" :multiple="multiple"
      class="hidden" @change="handleInputChange" />

    <!-- 空状态：整个区域可点击 + 可拖拽 + 可粘贴 -->
    <div v-if="!previews.length"
      @click="handleClick"
      :class="[
        'border-2 border-dashed rounded-2xl p-12 text-center cursor-pointer transition-all duration-300',
        isDragging
          ? 'border-linear-accent bg-linear-accent/5'
          : 'border-linear-border hover:border-linear-text-secondary'
      ]"
    >
      <p class="text-sm text-linear-text-secondary">
        拖拽图片到此处，或 <span class="text-linear-accent cursor-pointer">点击上传</span>
      </p>
      <p class="text-xs text-linear-text-secondary/40 mt-2">
        支持粘贴上传 · JPG / PNG / WebP · 单张不超过 {{ maxSize }}MB · 最多 {{ maxCount }} 张
      </p>
    </div>

    <!-- 有图片：预览网格 + 底部继续添加 -->
    <template v-else>
      <div class="grid grid-cols-3 sm:grid-cols-4 md:grid-cols-5 gap-3">
        <div v-for="(item, index) in previews" :key="item.url"
          class="relative group rounded-xl overflow-hidden border border-linear-border/50 aspect-square"
        >
          <img :src="item.url" :alt="item.name" class="w-full h-full object-cover" />
          <button @click.stop="handleRemove(index)"
            class="absolute top-1 right-1 w-6 h-6 rounded-full bg-linear-bg/80 text-linear-text-secondary hover:text-linear-text flex items-center justify-center opacity-0 group-hover:opacity-100 transition-opacity"
          >
            <svg class="w-3 h-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
            </svg>
          </button>
        </div>

        <!-- 继续添加（同一网格内） -->
        <div v-if="previews.length < maxCount"
          @click="handleClick"
          class="aspect-square rounded-xl border-2 border-dashed border-linear-border hover:border-linear-text-secondary flex items-center justify-center cursor-pointer transition-colors"
        >
          <svg class="w-6 h-6 text-linear-text-secondary/50" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M12 4v16m8-8H4" />
          </svg>
        </div>
      </div>
    </template>
  </div>
</template>
```

**交互要求清单**

| 功能 | 必须 | 说明 |
|------|------|------|
| 点击上传 | ✅ | 整个空状态区域可点击，有图片后点"+"添加 |
| 拖拽上传 | ✅ | 整个组件区域可拖入，拖入时视觉反馈 |
| 粘贴上传 | ✅ | 全局监听 `paste` 事件，Ctrl+V 直接上传 |
| 图片预览 | ✅ | `URL.createObjectURL`，网格缩略图 |
| 删除已选 | ✅ | hover 显示删除按钮，释放 ObjectURL |
| 文件校验 | ✅ | 类型 + 大小 + 数量上限 |
| 拖拽视觉反馈 | ✅ | `isDragging` 切换边框颜色 |
| 单区域原则 | ✅ | **禁止**拆分为独立的拖拽区和按钮区 |

---

## 九、禁止事项

1. 禁止 Vue 2 语法（Options API、`this`、mixins、filters）
2. 禁止 `reactive`，统一用 `ref`
3. 禁止硬编码 `text-white`/`bg-black` 作为主要文字/背景色，必须用 `linear-*` token 以支持主题切换
4. 禁止硬编码颜色值到模板，必须用 `linear-*` token 或 colorMap
5. 禁止 Tailwind 默认颜色（`bg-gray-900`、`text-blue-500` 等）
6. 禁止在 `tailwind.config.js` 中重复定义 `@theme` 已有的颜色
7. 禁止全局状态管理库（Pinia/Vuex）
8. 禁止 CSS-in-JS
9. 禁止 TypeScript（团队统一用 JS）
10. 禁止 `<style>` 不加 `scoped`（App.vue 全局样式除外）

