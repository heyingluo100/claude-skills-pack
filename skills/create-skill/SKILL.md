---
name: create-skill
description: 交互式引导生成标准结构的项目级 Skill，小功能点场景下替代 /req + /plan，生成的 SKILL.md 直接当 PRD 用
version: 1.2.0
status: active
---

# /create-skill — Skill 生成器

## 一、定位与职责

**是什么**：交互式引导工具，帮用户把项目中的小功能需求和流程转化为标准格式的 Skill 文件。生成的 SKILL.md 直接作为 PRD 使用，跳过 /req + /plan 进入开发流程。

**适用场景**：
- 功能点少（1-2 个）
- 追问后确认流程简单、容易完成
- 不需要复杂架构设计的工具型任务

**不适用**：
- 多页面、多模块的完整产品 → 走 /req → /plan → /dev
- 需要复杂架构设计的系统 → 走完整流程

**在流程中的位置**：
```
用户描述需求（小功能点）
    │
    ▼
判断：功能点 ≤ 2 个 且 流程简单？
    ├── 是 → /create-skill → 生成 SKILL.md（当 PRD 用）→ /dev
    └── 否 → /req → /plan → /dev
```

**不是什么**：
- 不是通用 Skill 平台，不做全局注册
- 不是从代码中自动提炼逻辑的工具
- 不自动修改 CLAUDE.md 或其他配置文件

**产出物**：`.claude/skills/[name]/SKILL.md` + `test-prompts.json`（及可选的 `scripts/`、`references/`、`assets/`、`agents/`）

**复用机制**：
- 生成的 Skill 可跨项目复用
- 复用时根据新项目场景做适配调整，不是原封不动搬
- 未来支持「从已有 Skill 派生」模式（当前版本暂不实现）

---

## 二、执行流程

### 触发判断

收到用户需求时，先评估：
1. 功能点数量：只有 1-2 个？
2. 追问流程复杂度：流程简单、步骤清晰、容易完成？

两个都满足 → 建议走 `/create-skill`，告知用户「这个需求比较轻量，建议先生成 Skill 再进入开发，可以吗？」等用户确认。

**衔接上游 /clarify**：如果上游 `/clarify` 已输出「规模预判：小功能点」或「规模预判：轻量单 skill」，**信任该预判，跳过本步二次评估，直接进入第①步前摸底**。避免和 clarify 的判断标准不对齐导致流程卡死。

### 第①步前 A：项目摸底（本会话未扫过时执行）

在收集 skill 基本信息之前，先快扫项目，避免生成的 SKILL.md 与项目栈脱节：

1. Read `package.json` / `pyproject.toml` / `pom.xml` / `Cargo.toml` 任一存在的清单文件
2. Glob `.claude/skills/*/SKILL.md` 看已有 skill 列表（避免重名 + 参考已有结构）
3. 输出一行：`[项目摸底] 类型:XX | 栈:XX | 已有 skill:N 个 → 继续`

摸底结果会影响第④步生成：
- Python 项目 → scripts/ 模板默认 `run.py`
- Node 项目 → scripts/ 模板默认 `run.js`
- 已有 skill 重名 → 第①步直接提示

### 第①步前 B：蓝本侦察检查（可选，仅 Skill 元开发轨标准/复杂场景建议执行）

为复杂或核心元开发任务创建 skill 时，建议先做蓝本侦察。轻量单 skill 可跳过此步，由本 skill 的本地查重承担。

执行规则：

1. **本地查重**（必做）：基于摸底已扫的 `.claude/skills/*/SKILL.md`，发现同名或同类 skill 时，说明复用、合并或新建理由
2. **优先读取完整蓝本报告**：
   - 有 activeProduct 时读取 `.skills/{product}/docs/blueprints/{skill-name}.md`
   - 没有 activeProduct 时读取 `.skills/blueprints/{skill-name}.md`
3. **如果存在报告**：摘要候选来源、许可证、可借鉴点、不采用点和本项目适配方式；后续设计只能借鉴结构、流程、边界和测试思路，不复制外部大段正文、脚本或模板
4. **如果不存在报告**：
   - 标准/复杂场景提示用户可先执行 `/github-blueprint`
   - 用户选择跳过时记录"未执行独立蓝本侦察：用户跳过"
   - 联网失败时记录原因并继续

输出蓝本状态：

```text
蓝本侦察：有报告 / 用户跳过 / 联网失败 / 未执行
报告路径：...
处理方式：...
风险：...
```

`/create-skill` 只消费蓝本报告或记录跳过原因，不负责在线搜索 GitHub；完整侦察由 `/github-blueprint` 执行。

### 第①步：基本信息

询问用户：
- **Skill 名称**：用于文件夹名和调用命令（kebab-case，如 `changelog-check`）
- **一句话描述**：这个 Skill 干什么

输出确认：
```
名称：/changelog-check
描述：发版前检查 changelog 是否已更新
确认？
```

等用户确认后进入下一步。

### 第②步：流程描述

引导用户描述这个 Skill 的具体执行步骤：
- 「这个 Skill 被调用后，具体要做哪些事情？按顺序描述。」
- 用户可以用自然语言描述，AI 整理为结构化步骤
- 整理完毕后输出步骤列表，等用户确认或调整

**追加一问 — 判断是否需要脚本**：

流程整理完后，必须问一句来区分 skill 类型：

> 「这个 skill 是 AI 读完说明书自己就能做（比如按流程检查代码、按规则改文档），还是需要**执行脚本**才能完成（比如调外部 API、启动浏览器抓网页、操作二进制文件）？」

- 回答"AI 自己做" → **指令型 skill**，第④步不创建 `scripts/`
- 回答"需要脚本" → **工具型 skill**，第④步自动创建 `scripts/` 并留入口模板（如 `run.py` 或 `run.js`）
- 用户拿不准 → 给例子：「像 /lint /health 这种是指令型；像"爬取某网站生成报告"是工具型。你的场景更像哪个？」

记录这个判断结果，传给第④步。

引导要点：
- 如果用户描述模糊，追问「这一步具体怎么判断？」「判断标准是什么？」
- 如果步骤过多（超过 10 步），建议拆分为多个 Skill 或使用子命令

**拆分判定**（步骤数之外的拆分信号）：

不只按步骤数拆，也按可确认产物、可复用能力、可归因边界和高成本执行点拆。当流程命中以下任意 **2 条**时，必须显式判断是否拆分；命中 **3 条以上**时强烈建议回到 `/plan` 拆分：

1. 包含两个以上独立能力（如"分析/识别"和"生成/执行"混在一起）
2. 中间产物本身有价值（候选方案、评分结果、结构化报告）
3. 中间产物需要用户确认后才能继续
4. 失败原因来自不同阶段，混在一起会难以归因
5. 前半段可复用到其他任务
6. 后半段依赖高成本模型/API、批量执行、覆盖文件或其他高风险操作
7. 流程虽短但提示复杂、约束密集、测试样例难覆盖
8. 输入输出开始变成多个状态文件、多个中间产物或多个报告

命中拆分判定时输出：

```text
[CREATE-SKILL] 拆分建议
候选单体：...
命中条件：...
建议拆分：skill-a → 确认中间产物 → skill-b
中间产物：...
保持单体风险：...
建议流程：回到 /plan 拆分 / 用户确认坚持单体后继续
```

用户坚持创建单体 skill 时，必须记录保持单体的理由、风险、中间产物处理方式和后续评估建议。

### 第③步：规则与约束

分两阶段引导：

**阶段 A — 确定范围**：
- 「这个 Skill 管什么？」（职责边界）
- 「不管什么？」（明确排除项）
- 「有没有前置条件？」（执行前需要什么文件/环境/状态）

**阶段 B — 填充规则**：
- 在已确定的范围内，引导用户列出具体规则
- 「在 [范围] 内，有哪些具体的检查规则/执行标准？」
- 如果用户说不清楚，给出同类 Skill 的规则示例作为参考

### 第④步：生成

根据前三步收集的信息，生成标准结构（对齐 Anthropic 官方 Agent Skill 规范）：

1. 创建文件夹 `.claude/skills/[name]/`
2. 生成 `SKILL.md`（**文件名必须大写，禁止 `xxx.skill.md` 或小写 `skill.md` 等非标准命名**），按标准格式填充内容（此文件直接作为 PRD 供 /dev 读取）
3. **固定生成 `test-prompts.json`**：即使是最小 skill，也生成一份至少 3 条触发词的模板（JSON 数组，每条含 `id`、`prompt`、`expected`）。全局 20 个 skill 里 17 个都有此文件（85%），把它作为约定固定文件，方便 skill 的 dispatch 命中测试和后续 `/darwin-skill` 评分。

4. **按需创建四个官方标准可选子目录**（空目录不创建，根据实际需要生成）：

   | 子目录 | 创建条件 | 内容 |
   |--------|---------|------|
   | `scripts/` | 第②步判断为"工具型 skill"（需执行脚本） | 生成入口模板（如 `run.py`、`run.js`），SKILL.md 执行流程中标注调用方式 |
   | `references/` | 用户提到参考资料、检查清单、深度文档，或 SKILL.md 正文 > 5000 字需要分拆 | 生成对应 `.md` 文件，SKILL.md 正文通过引用加载 |
   | `assets/` | 流程涉及固定格式产出物（报告模板、配置模板、图标、字体等静态素材） | 生成模板/素材文件 |
   | `agents/` | 需要给 UI 平台/agent 平台提供元数据（如 OpenAI GPT / 其他 agent 编排器识别用的 yaml） | 生成 `openai.yaml` 等平台适配文件 |

   **不生成 `input/`、`output/`、`templates/`、`tests/`、`examples/`**：`input/`、`output/` 是运行时数据通道属 skill 外部；`templates/` 已并入 `assets/`；`tests/`、`examples/` 非官方约定。生成任何这些目录 → skill 不合规。

5. **SKILL.md 内部路径合规扫描**（新 skill 必过硬门槛）：用 `Grep` 扫 SKILL.md，检查任何指向 skill 内部子目录（`scripts/`、`references/`、`assets/`、`agents/`）的引用是否**只用 skill 内部相对形式**。违规写法：

   | 违规模式 | 举例 | 修正方向 |
   |---------|------|---------|
   | 带 `.claude/skills/{name}/` 绝对前缀 | `.claude/skills/foo/scripts/run.py` | 去前缀，改成 `scripts/run.py` |
   | 带 `.codex/skills/{name}/` 或其他运行时位置前缀 | `.codex/skills/foo/references/prompt.md` | 去前缀，改成 `references/prompt.md` |
   | 用 `..` 跨出 skill 边界 | `../other-skill/xxx` | 禁止跨 skill 引用，重新设计依赖 |

   全部通过 → 继续；命中违规 → 用 `Edit` 全部修正到相对形式后重新扫描。**不通过 → 直接拒绝生成，不允许放行**。此规则的意义：让每个 skill 是"自持独立"的——拷到任何位置（项目内、分发包、其他项目）都能被识别、能被跑起来。

6. **安全扫描**（进入开发前必须通过）：用 `Read` 读取生成的 SKILL.md，逐项检查：

   | 检查项 | 风险 | 不通过处理 |
   |--------|------|-----------|
   | 流程中是否涉及读写敏感文件（.env、credentials、密钥文件） | 信息泄露 | 标记风险，建议改为环境变量引用 |
   | 流程中是否有不受限的 Bash 命令（rm -rf、chmod 777 等） | 破坏性操作 | 改为安全替代或加确认步骤 |
   | 规则中是否硬编码了 API 密钥、token、密码 | 密钥暴露 | 移除，改为占位符说明 |
   | 流程中是否缺少用户确认就执行写入/删除操作 | 误操作 | 在关键步骤前加确认检查点 |
   | 产出物是否可能包含用户隐私数据 | 隐私风险 | 加脱敏步骤或提醒 |

   全部通过 → 继续；有风险项 → 用 Edit 修正后重新检查

7. **独立自持验证**（**工具型 skill 必过，阻塞门槛；指令型 skill 跳过**）：把生成的 skill 目录当独立包对待，验证不依赖任何外部路径也能被解析：

   1. `cd .claude/skills/{name}/` 作为 cwd
   2. 跑主入口脚本的自检命令（Python: `python scripts/run.py --help`；Node: `node scripts/run.js --help`；Shell: `bash scripts/run.sh --help`）
   3. 命令能正常打印 help/usage → 通过
   4. 命令报"找不到 xxx 文件 / ModuleNotFoundError / 相对路径无法解析" → **失败，阻塞**

   失败的处理：读 traceback 定位是哪个路径引用不合规（通常是脚本里写死了 `.claude/skills/{name}/` 或项目根路径），改回 skill 内部相对形式（用 `Path(__file__).parent` 系列）后重新验证。**验证不通过不算 skill 创建成功。**

8. 输出生成结果摘要，让用户确认
9. 确认后提示：「Skill 已生成，直接进入 /dev 开发。」并**自动将生成的 SKILL.md 路径传递给 /dev 作为 PRD 来源**，不走 /req

10. **skill-map 状态推进**（仅 Skill 元开发轨且存在 activeProduct 时）：
    - 读取 `.skills/{product}/docs/skill-map.md`
    - 找到对应条目（按 skill 名匹配），状态从 `planned` 改为 `created`
    - 填入实际 skill 名称和路径
    - 不回退已经是 `optimized/reviewed/packed` 的状态
    - 没有 activeProduct 或没有 skill-map 时跳过此步，不阻塞

11. **分发注册预检**（可选，询问用户）：
    - 询问"是否需要将该 skill 纳入当前分发包？"
    - 不需要 → 输出"未纳入分发，后续 /pack 不会包含它"
    - 需要 → 展示影响范围（manifest 改动、README 列表更新等），等用户确认后由 `/pack register` 执行注册
    - 注册不替代 `/review` 验收；skill-map 状态保持 `created`，等待后续 `/darwin-skill`、`/eval-skill`（按需）、`/review` 推进
    - 没有打包清单时跳过此步

---

## 三、规则与约束

### 范围

**管什么**：
- Skill 文件夹结构的标准化
- SKILL.md 内容的格式规范
- 引导流程的完整性
- 触发条件的判断（功能点数量 + 流程复杂度）

**不管什么**：
- 不管生成后的 Skill 怎么执行（那是 Skill 自己的事）
- 不管 Skill 之间的依赖关系
- 不管 CLAUDE.md 的注册和配置
- 不管开发流程（生成完交给 /dev）

### 生成规范

**文件夹结构标准**（对齐 Anthropic Agent Skill 官方规范）：
```
.claude/skills/[skill-name]/
├── SKILL.md              # 必须（文件名固定大写，不允许 xxx.skill.md）
├── test-prompts.json     # 必须（触发词测试用例，至少 3 条）
├── scripts/              # 可选 — 工具型 skill 的可执行脚本
├── references/           # 可选 — 深度文档/边界说明（SKILL.md > 5000 字时也拆到这里）
├── assets/               # 可选 — 固定产出物的模板、图标、字体等静态素材
└── agents/               # 可选 — UI/agent 平台元数据（如 openai.yaml）
```

**禁止生成的目录**：
- 不生成 `input/` `output/`：这是调用时的运行时通道，属 skill 外部
- 不生成 `templates/`：已并入 `assets/`，保持与官方命名一致
- 不生成 `tests/`、`examples/`：非官方必备项，按需由开发者手动加

**SKILL.md 内部路径引用规范**（硬约束）：

SKILL.md 里任何指向本 skill 内子目录的引用（`scripts/`、`references/`、`assets/`、`agents/`）必须用**skill 内部相对形式**，即从 skill 根开始算的路径：

| 正确 | 错误 |
|------|------|
| `python scripts/run.py --help` | `python .claude/skills/foo/scripts/run.py --help` |
| `` 参考 `references/prompt.md` `` | `` 参考 `.codex/skills/foo/references/prompt.md` `` |
| `[配置](assets/config.yaml)` | `[配置](.claude/skills/foo/assets/config.yaml)` |

为什么：让每个 skill 目录**自持独立**——拷到任何位置（项目 `.claude/skills/`、分发 zip 里、别的项目、`~/.claude/skills/` 全局）都能被识别、能被执行。带绝对前缀的写法会让 skill 死死绑在特定项目路径上，无法分发、无法迁移。

**Progressive Disclosure 三层加载约定**：
| 层 | 加载时机 | 对应内容 |
|----|---------|---------|
| 1. 元数据 | 启动时常驻 | YAML frontmatter（`name` + `description`） |
| 2. 核心 | Claude 判断相关时 | `SKILL.md` 正文 |
| 3. 详情 | 按需拉取 | `references/*.md`、`scripts/*`、`assets/*`、`agents/*` |

要点：`SKILL.md` 正文控制在 5000 字以内，超出部分拆到 `references/`。

**SKILL.md 格式标准**：

```markdown
---
name: [kebab-case 名称]
description: [一句话描述]
version: 1.0.0
status: active
---

# /[name] — [显示名称]

## 一、定位与职责（必须）
- 是什么 / 不是什么 / 产出物

## 二、执行流程（必须）
- 编号步骤，每步说清楚做什么、怎么判断

## 三、规则与约束（必须）
- 范围（管什么、不管什么）
- 具体规则

## 四、错误处理（必须）
- 常见失败场景及应对方式

## 五、子命令（可选）
- 表格：子命令 | 用途 | 参数 | 说明

## 六、输出规范（可选）
- 产出物格式，引用 assets/ 中的模板

## 七、与其他 Skill 的协作（可选）
- 读写哪些共享文件、跟哪些 Skill 有交互
```

### 命名规则

- 文件夹名：kebab-case，全小写，用连字符分隔（如 `changelog-check`）
- 与已有 Skill 不能重名
- 名称应能一眼看出用途

### 质量约束

- 每个必须章节不能为空
- 执行流程至少有 2 个步骤
- 规则与约束必须先有范围再有规则，不能只列规则不定范围
- 错误处理至少覆盖 1 个失败场景

---

## 四、错误处理

| 场景 | 处理方式 |
|------|---------|
| 用户给的名称已存在 | 提示已存在，询问是覆盖还是换名 |
| 用户描述过于模糊 | 追问具体细节，给出示例引导 |
| 流程步骤超过 10 步 | 建议拆分，询问用户意见 |
| 用户中途放弃 | 确认是否保存已有内容为草稿 |
| 生成的文件写入失败 | 报告具体错误，建议检查目录权限 |
| 误判触发条件 | 用户说"这个需要走完整流程"时，立即切换到 /req |
