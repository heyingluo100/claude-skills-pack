# Skills 体系项目

本项目是通用的产品开发规范化工具，提供从需求分析到研发落地的全流程 Skills 体系。

## 核心规则

1. 用中文回答
2. 遇到不确定先自主解决（详见「自主解决优先规则」），无法解决再反问
3. 执行前先告知简要方案和想法，确认后再动手
4. 如果用户说的太离谱，直接指出问题
5. 每次改动必须保证已实现的功能完整保留
6. 操作员提供了文件路径时，**必须先尝试读取**，禁止未尝试就拒绝。读取失败了再说明具体原因。对于图片路径：当前 CLI/IDE 环境无法直接查看图片内容，收到图片路径时主动说明，并引导操作员将图片粘贴到支持图片的客户端（如 claude.ai 或 Desktop App），或描述图片内容由操作员口述

## 自主解决优先规则（最高优先级）

遇到不确定的点时，按以下顺序处理，**不要直接把问题甩给操作员**：

1. **读项目** — 翻代码、PRD、commit 历史、相关文件，看现状有没有答案
2. **联网搜** — 查同类做法、竞品方案、官方文档、社区实践
3. **基于 1+2 推断** — 给出方案，并明确告诉操作员「我推断 XX，依据是 YY」

只有以下三种情况才直接问操作员：

- 上述三步都试过仍无法确定
- 涉及**不可逆操作**（删文件/删分支、推送、改数据库、commit、改 skill 定义等）
- 多种理解会导致**方向完全不同**（如"做个登录"——账号密码 vs OAuth 是方向分歧，不是细节差异）

**呈现要求**：推断结果必须显式标注是推断，禁止当作既定事实输出。例如"我推断你想要 A 方案（依据：项目用了 Vue 3 + Vite），如果不对请纠正"，而不是直接"那就用 A 方案"。

**为什么**：把每个不确定点都甩给操作员、问东问西，是把风险和心智负担都转嫁了。先自己读项目、联网查、推断，能解决 80% 的"不确定"；剩下的 20%（不可逆 + 方向分歧）才值得占用操作员注意力。

## 任务中断处理规则

执行当前任务过程中，如果收到新的输入/消息，**禁止直接切换**。先判断新内容的性质：

1. **是当前任务的补充/澄清/修正** → 合并到当前任务一起处理，不单独开分支
2. **不是当前任务的补充**（新需求、新话题、无关问题）→ **先把当前任务执行完**，再回头确认新内容情况，作为新对话来处理
3. **判断不清** → 直接问操作员"这是对 XX 的补充，还是新任务？"，不要自己猜

**为什么**：这套 skills 会被多个 Claude 实例/不同会话使用，会话随时可能中断。强制"先做完再切"避免任务半途崩、上下文错乱、或把无关需求硬塞进当前范围。

**适用范围**：所有任务级别（微型/小功能点/复杂需求），每次收到新消息时都要判断一次。

## 会话边界协议（最高优先级）

跨会话续接是所有长任务的共性问题。四层载体各司其职，**禁止**用 conversation export txt 当交接载体。

### 四层载体

| 载体 | 寿命 | 触发 | 用途 |
|------|------|------|------|
| `memory/*.md` | 跨项目永久 | 操作员触发 | 长期偏好、事实快照 |
| `.skills/session.json` | 当前任务 | `/dev start\|done\|abandon` | 机器可读的 /dev 断点 |
| `.skills/{product}/carryover/{时间}.md` | 当前任务 | **半自动**（Claude 主动） | 任务级续接卡，跟 /dev 生命周期绑定 |
| `.skills/{product}/handoff/{时间}.md` | 当前会话 | **手动**（`/handoff save`） | 会话级交接卡，多任务/纯讨论用 |

单任务场景优先 carryover（自动化）；多任务混合、纯讨论、大杂烩用 handoff；两者可并存。

### 开局动作

新会话第一件事，扫三个位置（优先级从高到低）：
1. `.skills/{activeProduct}/carryover/` —— SessionStart hook 自动检测，命中就 Read 汇报 topic + 下一步
2. `.skills/{activeProduct}/handoff/` —— 命中就 `/handoff load`
3. `.skills/_discussions/*.md` —— 未完结讨论，告知文件名 + 主题问是否续接

**禁止**：把 `.skills/archive/conversations/` 下的 export txt 整个 Read 进上下文。要查具体段落用 `Grep`。

### 中途动作

- context >60% → 主动提醒"是否要写 handoff？"（carryover 由 Claude 在关键节点自动更新，不用提醒）
- context >80% → 强制建议收口："建议本会话停止，`/handoff save` + 强制更新 carryover，开新会话续做"

**carryover 关键节点主动更新**（每轮对话最多 1 次）：完成子步骤、关键决策产生、任务方向调整、操作员说暂停。
**强制更新场景**（绕过每轮 1 次限制）：/dev done、操作员明说完成或暂停、context >80%。

### 结尾动作

| 触发 | carryover | handoff |
|------|-----------|---------|
| `/dev done` + commit 成功 | **自动软删**到 archive | 无动作 |
| 操作员说"完成了/搞定了/OK 了" | **自动软删**到 archive | status 标 `已结束` |
| `/dev abandon` | **自动软删**到 archive | 无动作 |
| 操作员说"暂停/待会儿/明天" | 强制更新"当前进度"+"下一步" | 主动 `/handoff save` |

### 旧 export txt 归档规则

历史 `/export` 产出的 conversation txt 一律归档到 `.skills/archive/conversations/`：
- 不入 git（沿用 `.skills/` 全局规则）
- 不作为下次会话的常规交接载体
- 仅供回溯具体决策原话时用 `Grep` 抓取

## Skill 独立性原则

基于 skills 在项目里做出来的"落地产物"——因为调用某个 skill 才生出来的业务代码/页面/配置/文件——归项目所有，不等于 skill 定义本身。优化时严格遵守两条独立性：

### 规则 A：同项目内，skill 与 skill 之间独立
在一个项目里优化某个 skill（的落地部分）时，只动**这个 skill 在本项目的落地产物**，不顺手改别的 skill，也不动别的 skill 的落地产物。

### 规则 B：跨项目，同个 skill 的实例独立
同一个 skill（如 /dev）在 A 项目和 B 项目都用过时，两边落地产物是两份独立存在。在 A 项目里优化 /dev 并更新 A 的落地产物时，**绝对不要跨项目改 B 项目的落地产物**。

### 默认行为：改 skill 定义是"特权操作"
操作员在某项目里说"优化 XX skill"时：
1. **默认**只改当前项目本地的落地产物，**不碰** skill 定义文件（`~/.claude/skills/{skill}/SKILL.md` 或项目源 `.claude/skills/{skill}/SKILL.md`）
2. 如果判断 skill 定义本身需要改，**主动告知**："这会改动 skill 定义本身，影响所有使用这个 skill 的项目"，由操作员决定是否动
3. 只有操作员**明确说**"改 skill 本身/改 skill 定义/改全局"时，才动 skill 源文件
4. 改了 skill 定义后，**不主动回溯** B 项目、C 项目里老的落地产物——那些保持原样，除非各自项目被打开并要求同步新版

**为什么**：skill 是工具，项目落地产物是用工具做出来的成品。工具升级不应该自动回溯改写已经交付的成品。跨项目共享的是 skill 定义，不是对每个落地产物的维护义务。

## 项目上下文先行规则

参见全局 CLAUDE.md 的「项目上下文先行规则」。本项目特殊点：
- 这是 Skills 定义项目（`.claude/skills/*/SKILL.md`），摸底时识别此类型
- 摸底输出固定格式：`[项目摸底] 类型:Skills定义 | 已有 skill:N 个 | 相关:XX → 继续`
- 改 skill 定义时配合「Skill 独立性原则」，先确认是否改源文件

## Skill 本地优先扫描规则（最高优先级）

收到任何功能类需求时（"分析 X"、"生成 Y"、"处理 Z"、"帮我做 W"等），在判断"没有匹配的 skill"之前，**必须主动扫描项目内的 skill 目录**。系统提示里注入的 available skills 列表**不等于**项目 skill 全集——设了 `disable-model-invocation: true` 的 skill、description 写得不够显眼的 skill，都只能在列表里"隐身"。

### 扫描流程

收到功能类需求 → 按以下顺序处理，前一步没结果再走下一步：

1. **看系统提示列表**：浏览完整的 available skills 列表（不要只扫前几行），有明显匹配项就直接用
2. **扫项目级 skill 目录**：从当前工作目录的 `.claude/skills/` 开始，向上递归到 git 仓库根目录（覆盖 monorepo 场景）。用 Glob 列出 `**/.claude/skills/*/SKILL.md`
3. **读候选 skill**：文件名或路径像的，用 Read 打开看 frontmatter 的 `description` 和正文的触发场景
4. **匹配上就直接执行**：哪怕 skill 设了 `disable-model-invocation: true`、Skill 工具调不起来——按 SKILL.md 内容**手工执行**，效果等同。匹配上的判断标准：description 命中关键词，或正文触发场景明显契合需求
5. **三步都没匹配**：才回报"项目里没找到匹配的 skill"，并主动给出建议（手工做 / 走 /create-skill 现场搭一个 / 走标准 /req+/plan+/dev 流程）

### 适用范围

- ✅ **触发**：功能类需求（"分析视频"、"生成报告"、"批量处理文件"、"帮我做个 XX"）
- ❌ **不触发**：微型任务（改文案、改颜色、改配置）、纯问答、读代码、debug

### 正反例

**正例**：
- 操作员："帮我分析这个视频" → 我先 Glob `**/.claude/skills/*/SKILL.md`，发现项目里有个 `video-analyzer` skill，Read 它的 SKILL.md，按内容执行。
- 操作员："批量重命名这批图片" → 列表里没明显匹配，扫项目目录发现 `batch-rename` skill，直接用。

**反例**：
- 操作员："帮我分析这个视频" → 我看了系统提示列表没有"分析视频"相关的，直接回"没找到，要不要我手工分析一下？" ❌（漏了扫项目目录这步）
- 操作员："改一下首页标题" → 我先 Glob 项目 skill 目录 ❌（微型任务不该触发扫描）

### 为什么

- 系统提示注入的 skill 列表是**会话启动时**的快照，且会过滤掉 `disable-model-invocation: true` 的 skill；项目里真实存在的 skill **可能多于**列表所示
- 操作员把 skill 放在项目里，就是希望优先用项目版而不是凭空手工做或现场搭新的
- "没找到就放弃"等于让项目里已沉淀的资产白白浪费

---

## 需求/优化接收规则（最高优先级）

当操作员提出一个优化点或新功能/新需求时，**禁止直接动手**，必须先执行以下流程：

> **前置**：如果是功能类需求（"分析 X"、"生成 Y"等），先按上面「Skill 本地优先扫描规则」走一遍。匹配到现成 skill 就直接执行，不用再走下面的分级判断。

### 完整流程总览

```
操作员说了一句话
    │
    ▼
需求清晰吗？（能不能判断要做什么、多大规模）
├── 不清晰 → /clarify（最多 2 轮对话澄清）→ 得到清晰需求
└── 清晰 ↓
    │
    ▼
第0步：任务分级预判
    │
    ├── 微型（改文案/颜色/配置）
    │     → 简化流程：确认 → 改代码 → 范围校验 → commit
    │
    ├── 小功能点（1-2 个研发功能点，流程简单）
    │     → /create-skill → 生成 SKILL.md（当 PRD）→ /dev
    │
    ├── 轻量单 skill（1-2 个 skill 元开发功能点）
    │     → /create-skill → /darwin-skill → /eval-skill（按需）→ /review → /pack
    │
    └── 复杂需求（多功能点/多模块/需要架构设计）
          → 走【双轨主链路】决策树（见上方章节）
            ├── 研发产品轨：/req → /plan → /dev → /review
            └── Skill 元开发轨：/req → /plan → /github-blueprint × N
                → /create-skill × N → /darwin-skill × N
                → /eval-skill（按需）→ /review → /pack
```

**独立调用的 Skills**（不在主流程中，按需使用）：
```
/lint            → 代码规范管理（/dev 第3关读取）
/guard           → 偏离日志查看与 Override（/dev 自动写入）
/scaffold        → 项目脚手架搭建
/health          → 项目全局体检（8 维度）
/visualize       → 单文件 HTML 展示页生成
/Auto-Optimize   → 复杂任务迭代优化工作流
```

---

### 前置步骤：模糊需求澄清（/clarify）

收到需求时，先判断是否能理解"要做什么"和"大概多大"：
- **能判断** → 跳过，直接进第0步
- **不能判断**（"帮我弄个东西"、"做个数据相关的"、"优化一下"）→ 触发 /clarify

/clarify 规则：
- 只问一个核心问题：「你最终想要得到什么？」
- 不够再追问一个（最多 2 轮）
- 输出：一句话清晰需求 + 规模预判
- 然后进入第0步

---

### 第0步：任务分级预判

收到需求后（或 /clarify 输出后），**根据描述本身**快速判断任务级别：

| 级别 | 怎么判断 | 走什么流程 |
|------|---------|-----------|
| **微型** | "改一下"、"换个"、"调成"——单个值/文案/颜色/配置，影响范围一目了然 | 简化流程（见下方） |
| **小功能点** | 1-2 个**研发**功能点，追问后确认流程简单、容易完成，不需要复杂架构 | /create-skill → /dev（研发产品轨轻量路径） |
| **轻量单 skill** | 1-2 个 **skill 元开发**功能点，输入输出明确，不需要多 skill 协作 | /create-skill → /darwin-skill → /eval-skill（按需）→ /review → /pack |
| **复杂需求** | 多功能点、多模块、需要架构设计 | 见【双轨主链路】章节，先判定研发产品轨 / Skill 元开发轨 |

**判断原则**：
- 秒判"改完不影响别的" → 微型
- 功能少、流程清晰、要的是**业务代码** → 小功能点
- 功能少、流程清晰、要的是**新 skill 给别人用** → 轻量单 skill
- 需要想一想才能确定影响范围 → 复杂需求
- 拿不准 → 告知操作员两条路，让操作员选

#### 微型任务简化流程

```
1. 简要确认（一句话重述理解 → 等操作员确认）
2. 范围锁定（列出本次只动哪些文件，1-2行即可）
3. 直接改代码
4. 范围校验（commit 前检查实际改动文件 vs 白名单，多改了就停下来问）
5. 安全检查（commit 前）
6. commit

不调用 /dev，不走自测闭环，不走文档同步
```

**注意**：微型只是流程简化，不是跳过确认。哪怕改一行文案也要先说"我理解你要把 X 改成 Y，确认？"再动手。

**范围校验规则**：commit 前对比实际改动文件 vs 第2步的白名单。发现白名单外的文件被改动时，必须停下来问操作员——确认需要改则追加到白名单，确认不该改则还原该文件。

**如果判断不准**：宁可按复杂需求走完整流程，也不要把本该走流程的需求当微型处理。

---

#### 小功能点流程（/create-skill → /dev）

功能点 ≤ 2 个且流程简单时，走此路线：

```
1. /create-skill 交互式引导（5 步：⓪项目摸底 → ①基本信息 → ②流程描述 → ③规则与约束 → ④生成）
2. 生成 SKILL.md（直接作为 PRD 使用）
3. 安全扫描（检查 SKILL.md 是否存在安全漏洞）
4. /dev 开发执行
```

不走 /req，不走 /plan，SKILL.md 就是需求文档。

---

### 第1步：自主分析整理（复杂需求）

收到需求后，先自己思考和整理，输出结构化分析：

```
## 需求分析

**操作员原始描述**：[原话]

**我的理解**：[用自己的话重述，确认理解对不对]

**涉及的优化点**：
1. [优化点 A] — [为什么需要优化、当前问题是什么]
2. [优化点 B] — [为什么需要优化]

**需要优化的流程**：
1. [步骤 1]：[做什么、怎么做]
2. [步骤 2]：[做什么、怎么做]

**功能边界分析**：
- 本次改动范围：[涉及哪些模块/文件]
- 不动的部分：[明确哪些不动]
- 交叉影响：[与哪些已有功能有交叉，如何兼顾]

**变更白名单**（只允许动这些文件/目录）：
- [文件/目录 1]
- [文件/目录 2]

**变更黑名单**（绝对不动）：
- [不相关模块/文件]

**风险点**：
- [可能影响到的已有功能]
- [需要额外注意的边界情况]
```

**白名单硬约束**：编码过程中发现需要动白名单外的文件 → 必须先告知操作员并获得确认，然后更新白名单再动手。禁止顺手重构、格式调整等超出范围的改动。

### 第2步：等待确认

输出分析后，**必须等操作员确认**才能执行。不能自行判断"应该没问题"就开始做。

### 第3步：确认后执行

操作员确认后，按分析中的流程逐步执行，每步完成后简要汇报。

### 关键要求

- **不要只做操作员说的**：要主动思考操作员没说到但应该考虑的点
- **功能边界意识**：每次都要分析当前改动对其他功能点的影响
- **兼顾已有功能**：优化 A 功能时不能破坏 B 功能，新增时不能影响已有
- **不要贪多**：一次只解决一个优化点/功能点，做完确认后再做下一个

### 需求拒绝与质疑机制

收到需求时，同步检查以下四类风险。**任何级别的任务（包括微型）都要检查**：

| 类型 | 触发条件 | 处理方式 |
|------|---------|---------|
| **1. 安全红线** | 密码明文存储、关闭鉴权/验证、数据库直连前端、硬编码密钥到代码中、关闭 HTTPS | **硬拒绝**，直接说明不能这样做和原因 |
| **2. 技术常识违反** | 违反项目架构规范（如前端直连第三方 API、规范要求用 ref 却要求用 reactive）、在前端做应该后端做的事 | **拒绝 + 给出正确做法**作为替代方案 |
| **3. 逻辑矛盾** | 新需求和已有 PRD/功能冲突、操作员前后说法矛盾、新功能和已实现功能互斥 | **指出矛盾**，列出冲突点，等操作员决定 |
| **4. 业务倒退** | 功能缩减、数值降低、权限收窄、体验降级——且操作员**没有主动说明原因** | **质疑提醒**，要求补充理由后再执行 |

**第4类判断逻辑**：改动的方向是"减"而不是"加"，且操作员没解释为什么减。

示例：
- "额度从4000改成2000" → "这会降低用户额度50%，是业务调整还是改错了？请补充原因。"
- "删掉导出功能" → "这会移除已有功能，是否有替代方案？请确认是有意为之。"
- "额度从4000改成2000，因为成本控制" → 理由已给，直接执行，不提醒

## 双轨主链路（最高优先级）

复杂需求级别有两条主链路并存。**判断走哪条轨，看交付物是什么**——而不是看用什么技术、用 Vue 还是 Python。

### 决策树

```
复杂需求确认后，先判断交付物：

交付物是什么？
├── 业务代码 / 页面 / API / 数据处理 / 报告工具
│     用户最终运行/使用的是这些产物本身
│   → 走【研发产品轨】
│
├── Skill 定义（SKILL.md + 配套资源）
│     最终别人用 /xxx 调用的是这个 skill
│   → 走【Skill 元开发轨】
│
└── 既要业务代码也要新 skill（混合）
   → 默认按【研发产品轨】，新 skill 部分单独走 /create-skill 微流程
   → 拿不准就直接问操作员
```

### 研发产品轨

```
/clarify → /req → /plan → /dev → /review
```

适用：开发 Vue 前端 / FastAPI 后端 / 通用项目；交付物是业务代码。
状态文件：`session.json`、`guard/{product}.log`、`tracemap/{product}.json`、`test-context-cache.json`（沿用现有协议）。

### Skill 元开发轨

```
/clarify → /req → /plan
       → /github-blueprint × N （标准/复杂建议；轻量可跳过）
       → /create-skill × N
       → /darwin-skill × N
       → /eval-skill（按需，核心/高风险/准备分发时）
       → /review → /pack
```

适用：做新的 skill 给别人用；交付物是 SKILL.md + 配套资源 + 分发包。
状态文件：`skill-map.md`（精确状态源，状态枚举 `planned → created → optimized → reviewed → packed`）、`blueprints/`、`eval-skill/artifacts/`。

### 轻量单 skill（Skill 元开发轨的子路径）

功能点 ≤ 2 个、输入输出明确、不需要多 skill 协作时：

```
/create-skill → /darwin-skill → /eval-skill（按需）→ /review → /pack
```

不走 /req、不走 /plan、不走 /github-blueprint（由 /create-skill 做本地查重）。

### 双轨规则

- **互不替代**：研发产品轨不能为了"做 skill"省事而压成一个超大 SKILL.md；Skill 元开发轨不能为了"快速产出"绕过 /dev 跑业务代码。
- **共用入口可复用**：`/clarify`、`/req`、`/plan`、`/review` 在两条轨道都能用，但 `/plan` 在元开发轨里产出的是 skill 交付方案（`plan.md` + `skill-map.md`），不是研发任务列表。
- **微型/小功能点不分轨**：流程简单到不需要主链路的，按原「微型简化流程」或「小功能点流程（/create-skill → /dev）」处理；后者本质是用 SKILL.md 当 PRD 的研发产品轨。
- **拿不准走哪条**：直接告诉操作员两条路的差别，让操作员选——别自己猜。

### 实现承载线（Skill 元开发轨补充概念）

做 skill 时如果需要落到系统、页面、API、CLI、脚本、数据处理、报告工具或状态看板（"实现承载"），不要恢复旧 `/dev/lint/guard/scaffold/ui` 作为分发 skill；只把研发纪律按需固化为验收规则：
- 功能能追溯到 REQ-ID 或 skill-map 条目
- 输入输出和状态来源清楚
- 不硬编码 token / API key / password / prompt
- 页面无白屏 / 报错，核心操作可达
- API/CLI/脚本/数据处理/报告工具提供运行、测试、样例或验收证据

实现承载层不能替代 PRD、plan、skill-map 或 SKILL.md；功能、字段、接口、状态、报告结构变化时必须同步回正式事实源。

## Skills 一览

### 双轨共用入口

这些 skill 在两条主链路（研发产品轨 / Skill 元开发轨）都会用到。

| Skill | 用途 | 触发场景 |
|-------|------|---------|
| `/clarify` | 模糊需求澄清过滤器（最多 2 轮对话） | 需求模糊、无法分级时自动触发 |
| `/req` | 需求分析与 PRD 管理 | 复杂需求路线第1站 |
| `/plan` | 技术方案设计 / Skill 交付方案 | 复杂需求路线第2站 |
| `/review` | 验收复盘 | 双轨收尾 |

### 研发产品轨主流程（产出业务代码）

| Skill | 用途 | 触发场景 |
|-------|------|---------|
| `/dev` | 研发执行（含 commit/push 前置测试、5 关自测） | 所有研发任务 |

### Skill 元开发轨主流程（产出 skill 给别人用）

| Skill | 用途 | 触发场景 |
|-------|------|---------|
| `/create-skill` | 交互式引导生成标准结构的 Skill | 新建 skill（轻量也用主流程也用） |
| `/github-blueprint` | 创建 skill 前查公开蓝本 | 标准/复杂主链路建议；轻量可跳过 |
| `/darwin-skill` | Skill 评分、测试、优化（8 维 rubric） | 创建后或需要质量提升时 |
| `/eval-skill` | Skill 实证评估与回归复测 | 核心/高风险或缺少任务表现证据时（按需） |
| `/pack` | Skills 打包管理 | 准备分发时 |

### 独立调用 Skills（不在主流程，按需使用）

| Skill | 用途 | 状态 |
|-------|------|------|
| `/lint` | 代码规范化（/dev 第3关读取） | 已实现 |
| `/guard` | 偏离日志与 Override 管理（/dev 自动写入） | 已实现 |
| `/scaffold` | 脚手架搭建 | 已实现 |
| `/health` | 项目全局体检（8 维度，含安全风险+性能容错） | 已实现 |
| `/visualize` | 单文件 HTML 展示页生成（skill 介绍 / 操作指南 / 汇报展示） | 已实现 |
| `/Auto-Optimize` | 复杂任务迭代优化工作流 | 已实现 |
| `/handoff` | 会话交接卡管理（save/load/list/status） | 已实现 |
| `/carryover` | 任务级续接卡（半自动，跟 /dev 生命周期绑定，done+commit 或明说完成时自动软删） | 已实现 |
| `/taste` | 前端审美 brief 注入 + 项目一致性约束（事前注入设计意图，含过渡/时长/缓动/层级一致性） | 已实现 |

## 文档

- `OUTLINE.md` — 完整大纲设计（所有 Skill 的详细设计）
- `.skills/` — 运行时产出目录（**不入 git 仓库**，仅本地使用）
  - `.skills/[product]/docs/` — 说明性文档（PRD、功能书、方案、操作指南、验收报告等）
  - `.skills/guard/`、`tracemap/`、`changelog/`、`refactor/` — 过程性日志与数据
  - `.skills/templates/` — 可复用模板
- `.claude/skills/` — Skill 定义目录

## 安全规范

- `.skills/` 目录必须加入 `.gitignore`，不得提交到远程仓库
- API 密钥、prompt 模板等敏感内容统一放后端，前端通过后端代理调用
- `/dev done` 通过后、commit 前会自动执行安全检查（敏感文件拦截 + 前端暴露检查）
- 详见 `/dev` SKILL.md 的"commit/push 前置安全检查"章节

## 跨 Skill 数据协议

各 Skill 之间通过以下共享文件传递数据，任何 Skill 读写这些文件时必须遵守约定格式：

| 共享文件 | 写入方 | 读取方 | 格式约定 |
|---------|-------|--------|---------|
| `.skills/context.json` | `/req init`、`/req switch` | 所有 Skill | `{activeProduct, products: {name: {createdAt, prdVersion, phase, stage}}}` |
| `.skills/session.json` | `/dev start`、`/dev done`、`/dev abandon` | `/dev`（新会话恢复） | `{activeTask: {reqId, description, complexity, step, iteration, decisions}, lastAction, updatedAt}` |
| `.skills/{product}/docs/02-prd.md` | `/req finalize`、`/req update` | `/plan`、`/dev`、`/review`、`/guard` | 由 `req/templates/prd.md` 模板定义 |
| `.skills/{product}/docs/03-features.md` | `/req finalize` | `/dev`、`/review`、`/scaffold` | 由 `req/templates/features.md` 模板定义 |
| `.skills/{product}/docs/05-todo.md` | `/req finalize`、`/plan`、`/dev`、`/review`、commit 后置同步 | `/dev`（待办告知）、`/review` | 由 `req/templates/todo.md` 模板定义 |
| `.skills/{product}/docs/plan.md` | `/plan create`、`/plan tasks`、`/plan update` | `/dev start` | 由 `plan/templates/plan.md` 模板定义 |
| `.skills/{product}/docs/standards.md` | `/lint init`、`/lint rules add/delete/edit` | `/dev`（第3关）、`/scaffold`、`/plan` | 由 `lint/templates/standards.md` 模板定义 |
| `.skills/{product}/docs/review-{date}.md` | `/review check` | `/review report`、`/health`（参考） | 验收报告持久化，同日追加 |
| `.skills/{product}/test-context-cache.json` | `/dev`（commit/push/test 前置测试开始时） | `/dev`（push 前置测试 10 分钟内复用） | `{generatedAt, reqIds, businessSemantic, keyACs, upstreamDownstream, businessBoundaryValues, historicalIssues}` |
| `.skills/guard/{product}.log` | `/dev`（编码中自动写入） | `/guard`、`/review`、`/dev drift` | 每行：`[时间] [类型] \| [REQ-ID] \| [严重程度]\n  描述：...\n  处理：...` |
| `.skills/tracemap/{product}.json` | `/dev`（commit 后置同步） | `/dev`（回归排查）、`/review gap` | `{文件路径: [REQ-ID, ...]}` |
| `.skills/changelog/{product}.log` | `/req update`、`/req finalize` | `/review summary` | 每条：`[时间] v版本号 [变更类型] [描述]` |
| `.skills/{product}/docs/skill-map.md` | `/plan`、`/create-skill`、`/darwin-skill`、`/review`、`/pack` | 同上 | PRD 功能点到 skills 的映射和精确状态（仅 Skill 元开发轨用）。状态枚举：`planned/created/optimized/reviewed/packed/not-skill/deprecated` |
| `.skills/{product}/docs/blueprints/{skill-name}.md` | `/github-blueprint` | `/create-skill`、`/review` | GitHub 蓝本侦察报告。无 activeProduct 时降级到 `.skills/blueprints/{skill-name}.md` |
| `.skills/{product}/handoff/{YYYY-MM-DD-HHMMSS}.md` | `/handoff save` | `/handoff load`、新会话开头自动 | 会话交接卡（200-800 字结构化 md）。无 activeProduct 时降级到 `.skills/handoff/`。详见「会话边界协议」 |
| `.skills/{product}/carryover/{YYYY-MM-DD-HHMMSS}.md` | Claude 主动（/dev start 建卡，节点更新，done+commit 或明说完成时软删） | SessionStart hook `check-cards.js` + Claude 主动 Read | 任务级续接卡（半自动，≤800 字）。跟 /dev 生命周期绑定。软删除移到 `.skills/{product}/carryover/archive/`。无 activeProduct 时降级到 `.skills/carryover/`。详见 `/carryover` SKILL.md 和「会话边界协议」 |
| `.skills/archive/conversations/` | 操作员归档 `/export` 产物 | `Grep`（按需查询，禁止整个 Read） | 旧版 conversation export 档案区。不入 git，不作为常规交接载体 |
| `.claude/skills/eval-skill/artifacts/{target-skill}/` | `/eval-skill` | `/eval-skill`（回归复测）、`/darwin-skill`（参考） | 任务集 / trace / metrics / 报告。不入 zip 分发包 |
| `docs/visualize/{topic}.html` | `/visualize` | 操作员浏览 | 单文件 HTML 展示页（Linear / Anthropic 风格）。临时输出走 `.skills/visualize/` |

## 默认技术栈

- 前端：Vue 3 + Vite + Tailwind CSS 4.x + JavaScript
- 后端（轻量）：FastAPI (Python)
- 后端（重量）：Spring Boot (Java)
- 设计风格：Linear App 风格
- 完整规范见 `~/.claude/design-system.md`
