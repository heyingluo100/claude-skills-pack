# /taste 注入规则集

> 此文档由 `/taste rules` 或 `/taste analyze` 自动生成。给 /dev、/scaffold 编码时参考。
> 生成时间：{TIMESTAMP}
> 当前 dials：V{V} / M{M} / D{D}
> 项目偏好层：{PROJECT_PREFERENCE}

---

## Design Read

```
类型: {TYPE}
vibe: {VIBE}
dials: V{V}/M{M}/D{D}
refs: {REFS}
受众: {AUDIENCE}
隐性约束: {CONSTRAINTS}
```

---

## 激活的规则集

### 第一层：设计纪律

**1.1 Brief 推断纪律**
- 写代码前必须有 Design Read（已生成 ↑）
- brief 模糊时最多问 1 个澄清问题

**1.2 Hero 视口纪律**
- Headline ≤ 2 行
- Subtext ≤ 20 词 / 35 中文字
- Hero fit 100dvh
- pt 上 padding ≤ pt-24
- Hero 内文本元素 ≤ 4 个
- Trust logos 放 Hero 下方

**1.3 Layout 多样性**（V={V} 触发等级：{V_LEVEL}）
- 一页 8 节至少 4 种 layout 家族
- Zigzag 连续 ≤ 2 段
- Eyebrow 每 3 节 ≤ 1 个
- Bento 格子数 = 内容数

**1.4 Hierarchy & Spacing**
- 一页一套圆角刻度
- Z-index 成体系，无 z-[9999]
- 移动端显式定义折叠策略

**1.5 内容密度**（D={D} 触发等级：{D_LEVEL}）
- Section 默认形态：headline + sub + 一视觉/CTA
- 长列表用专门 UI
- Spec sheet 禁 border-b
- 引用 ≤ 3 行

### 第二层：AI Tells 黑名单

激活 60 项（详见 `/taste tells`）。**项目偏好覆盖**：以下两项**允许**：
- Inter 字体作为 body 默认
- 紫色 accent（Linear App 紫）

### 第三层：项目偏好（硬约束）

- 字体：Inter（body）+ 项目允许的 display 字体
- 主 accent：Linear 紫色（design-system.md 定义）
- 间距：Linear 紧凑（非 Apple 大留白）
- 圆角上限：rounded-3xl（24px）
- 默认主题：暗色

### 第四层：栈适配（Vue 3 + Tailwind 4.x）

**动效**（M={M} 触发等级：{M_LEVEL}）
- Vue `<Transition>` 替代 motion/react
- CSS scroll-driven animations 替代 GSAP ScrollTrigger
- IntersectionObserver 替代 whileInView
- 不引入 GSAP

**技术硬规则**
- 用 `min-h-[100dvh]`，禁 `h-screen`
- 动效只动 `transform` 和 `opacity`
- M > 3 必须尊重 `prefers-reduced-motion`
- 禁止 `window.addEventListener("scroll")`
- 禁止 `window.scrollY` 灌入 ref
- 单组件状态用 `ref`，跨组件用 Pinia

### 第五层：项目一致性约束（硬约束）

**5.1 过渡语言统一**
- 同类操作同一种过渡：折叠 `collapse`（grid-template-rows）/ 弹窗 `scale` / Tab `slide` / 淡入 `fade`
- 过渡时长 ≤ 3 种：`duration-150`（微交互）/ `duration-200`（快速反馈）/ `duration-300`（内容切换）

**5.2 缓动函数统一**
- `ease-out`（出现/展开）/ `ease-in`（消失/收起）/ `ease-in-out`（切换）
- 整项目缓动种类 ≤ 3 种，禁止随机 `cubic-bezier`

**5.3 层级系统**
- z-index 语义档位：内容 `z-10` / 导航 `z-20` / 浮层 `z-30` / 弹窗 `z-40` / toast `z-50`
- 禁止 `z-[9999]`
- 深度递进：页面 → 卡片 `bg-linear-bg-secondary` → 浮层 `bg-linear-bg-secondary/90 backdrop-blur-md`

**5.4 圆角/间距刻度**
- 一页/一项目一套圆角刻度，禁止 `rounded-md` 和 `rounded-3xl` 同层混用
- 间距沿 Tailwind spacing 阶（4/6/8/12/16/24），禁止 `p-[13px]` 任意值

---

## Pre-code Check（编码前自检）

- 我要加的过渡，项目里已有同类场景吗？沿用它的 name/duration/easing
- 我要用的 z-index，属于哪个语义档位？
- 我要用的圆角/间距，是否在项目基线内？

---


## 推荐起手势（基于当前 dials）

{RECOMMENDED_STARTERS}

例（V7/M5/D4 SaaS landing）：
- Hero：asymmetric split，左文右视觉，no 居中
- 第 2 节：bento 4 格，内容驱动
- 第 3 节：horizontal feature row（不用 3 列等宽）
- 第 4 节：editorial split
- 动效：Vue Transition fade + slide-up，stagger 80ms
- 字体：Inter（body）+ 一个 display 字体
- 色彩：Linear 暗底 + 紫 accent + 一个辅色

---

## 待规避（针对当前 brief）

{BRIEF_SPECIFIC_TELLS}

每次 analyze 会针对 brief 高亮容易踩的 AI Tells。例如 "做个 SaaS landing" 会高亮：
- ❌ 3 列等宽 feature cards
- ❌ 居中 hero + dark mesh
- ❌ "Elevate your X" 类套路文案
- ❌ 假精确数字
