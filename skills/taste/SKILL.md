---
name: taste
description: 前端审美 brief 注入 + 项目一致性约束。代码生成前读 brief、推断设计语言、注入风格规则、AI 反套路黑名单，并强制项目内多页面视觉一致性（过渡/时长/缓动/层级）。触发词："taste"、"审美"、"设计品味"、"做个 landing"、"前端风格"、"brief 推断"、"反 AI 套路"、"反套路"、"一致性"、"过渡时长统一"。
argument-hint: "[analyze|rules|tells|preflight|dials]"
disable-model-invocation: true
allowed-tools: Read Write Edit Glob Grep
---

# /taste — 前端审美 brief 注入

## 定位

`/taste` 是**代码生成前**的设计语言推断、风格规则注入与项目一致性约束工具。

与其他 Skill 的区别：
- `/lint`：代码语法规范（命名/结构/写法）
- `/scaffold`：生成模板代码
- **`/taste`：编码前注入设计意图（三旋钮 + AI Tells + 设计纪律 + 项目一致性）**

核心理念：**Anti-Slop + Cross-Page Consistency**——主动反 AI 套路，并强制项目内多页面用同一套过渡/时长/缓动/层级语言，避免每页都"通用好看"但整体割裂。

> **历史背景**：曾有配对的 `/ui`（事后 4 维审计），已归档到 `.claude/skills/_deprecated/ui/`。模型自身审美能力已足够，事后审计沦为冗余；`/ui` 里"项目一致性"这一维前置到本 skill 的第五层。

## 三旋钮（核心机制）

三个 1-10 旋钮决定整套输出的设计走向。`/taste analyze` 会读 brief 后推断这三个值。

| 旋钮 | 名字 | 1 端 | 10 端 | 基线 |
|---|---|---|---|---|
| V | DESIGN_VARIANCE | 居中对称 / 模板感 | 不对称 / 实验布局 | **7** |
| M | MOTION_INTENSITY | 静态 | 滚动驱动 + 磁吸 | **5** |
| D | VISUAL_DENSITY | 大留白 / 画廊感 | 高密度 / 仪表板 | **4** |

> **本项目基线 7/5/4**（Linear 现代克制风格）。Taste 上游 v2 默认 8/6/4，我们降一档因为 Linear 偏紧凑、克制。

### 旋钮推断表（brief 信号 → 推断值）

| brief 信号 | V | M | D |
|---|---|---|---|
| "minimalist"、"克制"、"editorial" | 5-6 | 3-4 | 2-3 |
| "modern SaaS"、"产品官网" | 7 | 5 | 4 |
| "dashboard"、"data-heavy" | 4 | 3 | 8-9 |
| "Awwwards"、"实验"、"获奖级" | 9-10 | 8-10 | 3-4 |
| "agency"、"作品集" | 8 | 7 | 4 |
| "政务"、"企业级" | 3-4 | 2 | 5-6 |

## 共通规则

1. **需求接收**：先 `analyze` 输出 Design Read 一行 + 旋钮推断 → 等操作员确认 → 再注入规则
2. **中文输出**：报告和交互用中文
3. **项目偏好优先**：第三节"项目偏好覆盖"内容永远压过 Taste 上游默认
4. **不动业务代码**：`/taste` 只输出规则文档，不直接改 .vue 文件（改文件交给 /scaffold 或操作员）
5. **一致性优先**：第五层"项目一致性约束"是硬约束，编码时必须遵守——同一项目内过渡/时长/缓动/层级必须一致

## 前置检查

1. 读取 `.skills/context.json` 获取当前产品
   - **不存在时**：允许无上下文运行，规则文档降级输出到 `.skills/taste-rules.md`
2. **前端框架识别**（本会话未扫过时执行）：
   - Read `package.json` 看构建工具和主要依赖
   - 前端框架识别：Vue / React / 纯 HTML
   - 检查 `tailwind.config.js` 是否存在
   - 输出一行：`[项目摸底] 类型:Vue/React/HTML | Tailwind:有/无 → 继续`

## 子命令路由

| 参数 | 执行 |
|---|---|
| `analyze "<brief>"` | → 读 brief 推断旋钮 + 输出 Design Read |
| `rules` | → 输出当前完整注入规则（给 /dev 编码时参考） |
| `tells` | → 输出 AI Tells 黑名单（约 60 项） |
| `preflight` | → Pre-flight 自查表（给 commit 前用） |
| `dials [V] [M] [D]` | → 手动覆盖旋钮值（例：`/taste dials 5 3 2`） |
| `dials show` | → 查看当前旋钮值 |
| 无参数 | → 显示当前状态 |

### 自然语言路由

| 操作员表达 | 映射到 |
|---|---|
| "做个 landing"、"帮我写个 hero" | → analyze（用整句话当 brief） |
| "审美检查"、"风格规则" | → rules |
| "AI 套路有哪些"、"反套路黑名单" | → tells |
| "上线前检查"、"提交前自查" | → preflight |

---

## analyze — Brief 推断

### 执行步骤

1. **读 brief**：识别页面类型（landing/portfolio/dashboard/editorial）、vibe 词（minimalist/modern/experimental）、参考网站、目标用户、隐性约束
2. **推断旋钮**：按上面"旋钮推断表"映射，必要时折中
3. **输出 Design Read 一行**
4. **brief 模糊时**：允许问**最多 1 个**澄清问题（不允许追问连环炮）
5. **输出注入规则集**：根据旋钮值，从下面四层规则中按条件激活，输出给 /dev 编码时用

### Design Read 输出格式

```
[Design Read]
类型: [landing/portfolio/dashboard/editorial/agency/...]
vibe: [3-5 个关键词]
dials: V?/M?/D?
refs: [参考站点 0-3 个]
受众: [B2B/C 端/政企/...]
隐性约束: [品牌色已定/必须支持暗色/...]
```

---

## 第一层：纯净增量规则（直接吸收）

### 1.1 Brief 推断纪律

- ✅ 在写任何代码前**必须**输出 Design Read 一行
- ✅ brief 模糊时最多问一个澄清问题，禁止连环炮
- ❌ 不要默认 AI 紫色渐变、暗色 mesh 居中 hero、3 列等宽卡片

### 1.2 Hero 视口纪律

- Headline ≤ 2 行
- Subtext ≤ 20 词（中文 ≤ 35 字）
- Hero 必须 fit 首屏（100dvh，不用 100vh）
- Hero 上 padding ≤ pt-24
- Hero 内最多 4 个文本元素（eyebrow / headline / subtext / CTAs）
- Trust logos 必须放 Hero **下方**，不在内部
- Nav 单行，高度 ≤ 80px

### 1.3 Layout 多样性强制

- 一页 8 节中至少使用 **4 种不同 layout 家族**（asymmetric split / bento / centered / sticky-stack / horizontal-pan / editorial / ...）
- Zigzag 交替（image+text 左右切换）连续不超过 **2 段**
- Eyebrow（小标签）：每 3 节最多 1 个
- Bento 格子数必须精确匹配内容数，禁止"凑格子"
- Section 重复 layout 视为失败

### 1.4 Hierarchy & Spacing

- 一页一套圆角刻度（不能 rounded-md + rounded-3xl 混用）
- Z-index 必须成体系，禁止 z-[9999] 这类绝对值跳跃
- 移动端必须显式定义每节的折叠策略，不能"自适应就行"

### 1.5 内容密度纪律

- Section 默认形态：短 headline + 短 sub-paragraph + 一个视觉/CTA
- 长列表必须用专门 UI（card grid / tabs / accordion / scroll-snap / marquee），禁止 data-dump
- Spec sheet 禁止 border-b 逐行下划线
- 引用块 ≤ 3 行

---

## 第二层：AI Tells 黑名单（约 60 项）

> 命中以下任何一项 = AI 套路警告，编码时必须主动规避。`/taste tells` 输出完整清单。

### 2.1 视觉 Tells（11 项）

- ❌ 纯黑 #000000 背景（改用 off-black 如 #0a0a0a）
- ❌ 纯白 #ffffff 背景（改用 off-white 如 #FBFBFA）
- ❌ AI Purple / Blue glow 渐变（**项目例外**：Linear 紫色 accent 允许，见第三层）
- ❌ Neon 外发光
- ❌ 过饱和 accent（饱和度 > 80%）
- ❌ 渐变文字 headline
- ❌ 自定义 cursor
- ❌ Glassmorphism 滥用（≥ 3 个面板都用 = 套路）
- ❌ 暖米色 + 黄铜 + espresso 调色（"premium-consumer slop"）
- ❌ 装饰性颗粒/噪点滤镜误用（grain 加在每个 section 当质感）
- ❌ 鼠标尾巴/光标拖影特效（"赛博朋克"装饰）

### 2.2 排版 Tells（9 项）

- ❌ Inter 做默认（**项目例外**：Linear 用 Inter，允许，见第三层）
- ❌ Fraunces / Instrument_Serif 做默认
- ❌ 超大 H1（text-9xl 当首页装饰）
- ❌ `<br>` 拆 headline 装气质
- ❌ 文字旋转 90 度装设计感
- ❌ em-dash（**英文输出场景**强制禁用，中文场景豁免）
- ❌ 全大写 H1（"REVOLUTIONARY PLATFORM"装权威感）
- ❌ 字间距过大（tracking-widest）当所有 H2 默认
- ❌ 用 `<i>` 斜体作 emphasis（语义应该是 `<strong>` 或 font-weight）

### 2.3 布局 Tells（8 项）

- ❌ 3 列等宽 feature cards（"#1 layout slop"）
- ❌ 居中 hero 当默认（V > 4 时禁用）
- ❌ 8 节全是 image+text zigzag
- ❌ Split-header（左 logo 右 nav 中间空）当默认
- ❌ Bento 背景全部 #fff 单一
- ❌ Hero 内两个 CTA 做同一件事（"开始使用 → 立即注册"）
- ❌ Footer 四列均分套路（Product / Company / Resources / Contact）
- ❌ Hero 内嵌假视频时长（"Watch demo · 2:30"）

### 2.4 内容 Tells（10 项）

- ❌ 假人名 John Doe / Jane Smith
- ❌ 默认 avatar circles
- ❌ 假精确数字（99.9% / 10x faster 无来源）
- ❌ 创业风假品牌名（Stark / Apex / Forge / Nova）
- ❌ 套路动词："Elevate"、"Seamless"、"Unlock"、"Empower"、"Transform"
- ❌ Lorem ipsum 漏到 prod
- ❌ "Quietly used at <famous-company>" 自我吹捧
- ❌ 套路副标："Built for X teams that Y"
- ❌ 统计数字无单位（"98% something" 不说 98% of what）
- ❌ Founder/team 假大头照 + 一句话标语凑信任

### 2.5 微元素 Tells（15 项）

- ❌ Hero 内放版本号 v2.1 装专业
- ❌ Section 序号 eyebrow（01 / 02 / 03）
- ❌ 中点 · 滥用
- ❌ 装饰性小圆点散落
- ❌ 假产品 UI 截图（用 div 模拟 macOS 窗口）
- ❌ 假版本号 footer
- ❌ 诗意侧栏标签（"Whispers in the static"）
- ❌ 天气/地理位置 strip
- ❌ Pills 漂浮在图片上
- ❌ 照片版权信息装质感
- ❌ Score bar 带轨道背景
- ❌ Scroll cue（"Scroll ↓"）
- ❌ 滚动劫持
- ❌ 横向 marquee 一页 ≥ 2 个
- ❌ 角落 "NEW" / "BETA" badge 滥用（每个 feature 都贴）

### 2.6 技术 Tells（7 项）

- ❌ `window.addEventListener("scroll", ...)` 在 Vue/React 中直接监听（用 IntersectionObserver 或 scroll-driven animations）
- ❌ `window.scrollY` 灌进 ref/state 触发渲染
- ❌ requestAnimationFrame 循环操作响应式状态
- ❌ 重复 fetch 相同数据（应缓存）
- ❌ `onMounted`/`useEffect` 监听 resize 灌进 state（用 CSS clamp / container query）
- ❌ 内联 `style="..."` 写大段 CSS（应该提取到 class）
- ❌ "Powered by [stack]" 在 footer 装专业（Built with Next.js / Made with Vue 等）

---

## 第三层：项目偏好覆盖（明确不采纳 Taste 上游规则）

> 以下规则在 Taste 上游被禁用，但**本项目明确保留**，因为是 Linear App 风格的根基。

| Taste 上游禁用 | 本项目处理 | 理由 |
|---|---|---|
| Inter 字体 | ✅ **保留**为默认 body 字体 | Linear 用 Inter，design-system.md 已固化 |
| 紫色 accent（AI Purple） | ✅ **保留** Linear 紫色 accent | design-system.md 的核心色，是品牌识别 |
| 紧凑间距（vs Apple 大留白） | ✅ **保留** Linear 紧凑间距 | 信息密度需要 |
| `rounded-3xl`（24px）上限 | ✅ **保留**为圆角上限 | design-system.md 已约束 |
| 暗色为主 | ✅ **保留** dark-first | Linear 默认暗色 |

**触发条件**：以上覆盖仅适用于"本项目（Skills 体系项目）及衍生项目"。如果未来在非 Linear 风格项目里用 /taste，需要通过 `/taste rules edit` 调整这一节。

---

## 第四层：技术栈适配（Vue 3 + Tailwind 4.x）

> Taste 上游基于 React/Next.js + Motion + GSAP。本项目重写为框架无关 + Vue 优先。

### 4.1 动效实现替换

| Taste 上游 | 本项目等价方案 |
|---|---|
| `motion/react` 的 `motion.div` | Vue `<Transition>` + Tailwind transition class |
| `useMotionValue` + `useTransform` | Vue `ref` + computed + CSS scroll-driven animations |
| GSAP ScrollTrigger sticky-stack | CSS `position: sticky` + IntersectionObserver |
| GSAP horizontal-pan | CSS `scroll-snap-type: x mandatory` |
| `whileInView` stagger | IntersectionObserver + Vue `<TransitionGroup>` |

### 4.2 Vue/Tailwind 技术规则

- ✅ 用 `min-h-[100dvh]`，禁止 `h-screen`
- ✅ 布局优先 CSS Grid，避免 flex 算数硬撑
- ✅ 图标统一一家（Phosphor / Heroicons / Lucide 三选一，整项目一致）
- ✅ 字体用 `@font-face` 或 Google Fonts，禁止手画 SVG 字
- ✅ Motion 触发器超过 M > 3 必须尊重 `prefers-reduced-motion`
- ✅ 动效只动 `transform` 和 `opacity`，禁止动 width/height/top/left

### 4.3 状态管理

- ✅ 单组件状态用 `ref`
- ✅ 跨组件共享走 Pinia，避免 props drilling
- ❌ 连续值（如滚动进度）禁止用 ref/state，用 CSS scroll-driven animations 或 IntersectionObserver

---

## 第五层：项目一致性约束（硬约束，编码时必须遵守）

> 从原 `/ui` 的一致性检查前置而来。单页面看不出问题，多页面拼在一起才暴露——所以必须**编码前就约束**，不能事后审计。

### 5.1 过渡语言统一（原 U-W8/W9）

- **同类操作 → 同一种过渡**：折叠/展开统一用 `collapse`（grid-template-rows 方案）；弹窗/浮层统一用 `scale`；Tab/内容切换统一用 `slide`；淡入淡出统一用 `fade`
- **过渡时长收敛到 ≤ 3 种**：默认 `duration-150`（微交互 hover/press）、`duration-200`（快速反馈 fade）、`duration-300`（内容切换 collapse/tab）。禁止在项目里冒出 `duration-500`、`duration-700` 等零散值
- **禁止**同一场景（如"弹窗出现"）在不同页面用不同过渡

### 5.2 缓动函数统一（原 U-W10/W11）

- `ease-out` → 展开、出现、进入（元素从无到有）
- `ease-in` → 收起、消失、退出（元素从有到无）
- `ease-in-out` → 双向切换（Tab、状态互换）
- 禁止随机 `cubic-bezier(...)` 装饰；整项目缓动种类 ≤ 3 种

### 5.3 层级系统统一（原 U-I1）

- z-index 用**语义档位**，不用绝对值：
  - 内容层 `z-10` / 导航 `z-20` / 浮层 `z-30`（dropdown/popover）/ 弹窗 `z-40` / toast `z-50`
- 禁止 `z-[9999]` 这类跳跃写法
- 浮层深度递进：`bg-linear-bg`（页面） → `bg-linear-bg-secondary`（卡片） → `bg-linear-bg-secondary/90 backdrop-blur-md`（浮层）

### 5.4 圆角/间距刻度统一（跨页面共用一套）

- 一页/一项目一套圆角刻度，禁止 `rounded-md` 和 `rounded-3xl` 在同一视觉层混用
- 间距刻度沿 Tailwind spacing 阶（4/6/8/12/16/24），禁止任意 `p-[13px]` 一次性值
- 从 design-system.md 拉基线；本项目基线：圆角上限 `rounded-3xl`（24px），紧凑间距

### 5.5 编码时的自检提示

`/taste rules` 输出的规则文档末尾会附一句 **Pre-code Check**：

```
编码前自检（不需要工具，靠约束意识）：
- 我这次要加的过渡，项目里已有同类场景吗？沿用它的 name/duration/easing。
- 我要用的 z-index，属于哪个语义档位？
- 我要用的圆角/间距，是否在项目基线内？
```

---



执行 `/taste rules` 后，输出一份结构化 markdown 到 `.skills/{product}/docs/taste-rules.md`（无 activeProduct 时降级到 `.skills/taste-rules.md`），给 /dev 编码时参考。

输出格式参考 `templates/taste-rules.md`。

```
[/taste rules]

当前 dials: V7 / M5 / D4
项目偏好层: Linear App 风格

激活规则集（按当前 dials）:
- 第一层 1.1-1.5: 全部激活
- 第二层 AI Tells: 全部激活（60 项）
- 第三层 项目偏好覆盖: Inter / 紫色 accent / 紧凑间距 / 暗色 first
- 第四层 栈适配: Vue Transition + CSS（不用 GSAP）

完整规则: 已写入 .skills/{product}/docs/taste-rules.md
```

---

## tells — 输出 AI Tells 黑名单

执行 `/taste tells` 输出第二层完整 60 项清单（grep 友好格式，方便复制到 /dev 上下文）。

每项格式：`[类别] ❌ 套路描述 → ✅ 推荐替代`

---

## preflight — Pre-flight 自查表

提交前自查清单（约 30 项），从 Taste 上游 55 项裁剪到适配 Vue + Linear 的部分。

完整模板见 `templates/preflight.md`。输出时按已完成/未完成统计：`总计: X / 30 ✓`

---

## dials — 旋钮控制

### 子命令

| 参数 | 行为 |
|---|---|
| `dials [V] [M] [D]` | 手动覆盖旋钮值（例：`/taste dials 5 3 2`） |
| `dials show` | 显示当前旋钮值 + 来源（推断 / 手动覆盖） |
| `dials reset` | 重置为项目基线 7/5/4 |

### 执行步骤（`dials [V] [M] [D]`）

1. **参数校验**：
   - 必须 3 个值，缺参数（如 `dials 5 3`）→ 报错「需要 3 个值：V M D」，不写文件
   - 每个值必须 1-10 整数，超范围 → 报错「旋钮范围 1-10」
   - 非整数（5.5 / abc）→ 报错「旋钮必须是整数」
2. **路径决议**：
   - 有 activeProduct → `.skills/{product}/docs/taste-dials.json`
   - 无 activeProduct → `.skills/taste-dials.json`
3. **冲突处理**：
   - 文件不存在 → 直接写
   - 文件已存在且新值不同 → 告知旧值，覆盖
   - 文件已存在且新值相同 → 不写，提示「值未变更」
4. **写入格式**：
   ```json
   {"V": 5, "M": 3, "D": 2, "source": "manual", "updated_at": "ISO 时间戳"}
   ```
5. **输出确认**：
   ```
   [dials] V5/M3/D2（覆盖原值 V7/M5/D4）
   来源：手动 | 文件：.skills/{product}/docs/taste-dials.json
   ```

### 执行步骤（`dials show` / `dials reset`）

- `show`：读 `taste-dials.json`，输出 V/M/D + source。文件不存在 → 输出「使用项目基线 V7/M5/D4」
- `reset`：删除 `taste-dials.json`（或写入基线值 + source=baseline）→ 输出「已重置为基线 V7/M5/D4」

---

## 与其他 Skill 协同

| Skill | 协同方式 |
|---|---|
| `/dev start` | 操作员可手动调 `/taste analyze "<brief>"` 注入风格规则，再开始 /dev（自动集成留待 v2） |
| `/dev done` | `/taste preflight` 作为可选补充检查 |
| `/scaffold` | 操作员调 /scaffold 前可先调 /taste rules，把规则贴给 scaffold（自动集成留待 v2） |
| `/lint` | 完全不同层。/lint 管语法，/taste 管意图 |
| `/health` | 不重叠。/health 体检 8 维，不审美 |
| `/visualize` | /visualize 输出页时可参考 /taste rules（特别是项目偏好层） |

---

## 无参数时（`/taste`）

```
[/taste] 前端审美 brief 注入

当前状态:
  dials: V7 / M5 / D4（基线）
  项目偏好层: Linear App
  AI Tells 数: 60

命令:
  /taste analyze "<brief>"  — 读 brief 推断设计语言
  /taste rules              — 查看当前注入规则
  /taste tells              — AI Tells 黑名单
  /taste preflight          — 提交前自查表
  /taste dials [V] [M] [D]  — 手动覆盖旋钮
  /taste dials show         — 查看当前旋钮

来源: Taste Skill v2 (MIT)，本项目改编版
配套: /scaffold（模板生成） · /dev（编码执行）
```

---

## 来源与署名

本 skill 改编自 [Taste Skill v2](https://github.com/Leonxlnx/taste-skill)（MIT License, Copyright © 2026 Leonxlnx）。

主要改编内容：
1. 技术栈从 React/Next.js + GSAP + Motion 改为 Vue 3 + Tailwind 4.x + CSS/Vue Transition
2. 项目偏好层覆盖了上游"反 Inter / 反紫色 accent / 反紧凑间距 / 反 dark-first"等规则（保留 Linear App 风格根基）
3. em-dash 禁用从全场景缩减为仅英文输出场景
4. 子命令与 /ui / /scaffold / /dev 协同关系本地化
5. 中文输出 + 中文触发词
