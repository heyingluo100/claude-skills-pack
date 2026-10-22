---
name: github-blueprint
description: 在创建 skill 前查找并评估 GitHub 或公开蓝本,输出候选来源、许可证、维护情况、可借鉴点和本项目适配方式。用于复杂 skill、标准主链路或用户明确要求先做外部参考侦察时。
argument-description: "可选参数:[skill-name|--from-plan]。指定拟创建 skill 名称,或按 plan 中的 skill-map 批量侦察。"
version: 1.0.0
status: active
---

# /github-blueprint — GitHub 蓝本侦察

## 定位

`/github-blueprint` 是创建 skill 前的外部参考侦察 skill。它帮助 Claude 在写 `SKILL.md` 前了解公开世界里是否已有可借鉴的 skill、agent workflow、prompt pack、automation recipe 或类似结构。

精准查询策略见 `references/query-strategy.md`,报告模板见 `references/report-template.md`。执行时只读取这两个直接引用文件,不需要继续深挖其他资料。

它的目标不是复制外部实现,而是借鉴:

- 触发条件
- 输入输出结构
- 工作流边界
- 测试 prompt 思路
- 错误处理方式
- 许可证处理方式

## 职责边界

负责:

- 解析拟创建 skill 的名称、目标、关键词、REQ-ID 或产品上下文。
- 扫描本仓库已有 `.claude/skills/*/SKILL.md`,避免重复设计。
- 查找 GitHub 或公开参考源。
- 对候选蓝本做相关性、许可证、维护情况、可迁移性和风险评估。
- 对候选应用硬门槛和评分表,避免把泛搜索结果误当成可用蓝本。
- 输出蓝本侦察报告。
- 联网失败时记录原因,并给出离线降级建议。

不负责:

- 创建或修改 `.claude/skills/{name}/SKILL.md`。
- 修改 `skill-map.md` 状态。
- 修改打包清单。
- 生成 slash command prompt。
- 执行 `/darwin-skill`、`/review` 或 `/pack`。
- 同步全局 `~/.claude/skills/`。

## 适用场景

触发场景:

- 用户直接执行 `/github-blueprint ...`。
- 用户说"查一下 GitHub 有没有类似 skill"。
- 用户说"创建 skill 前先看外部蓝本"。
- `/plan` 已经产出 planned skill,用户要求按 plan 做蓝本侦察。
- `/create-skill` 即将创建复杂 skill,但用户希望先查外部参考。

不触发场景:

- 微型文案、配置或路径调整。
- debug 当前已有 skill。
- 用户明确说"跳过蓝本侦察"。
- 用户明确要求跳过蓝本侦察的轻量单 skill 创建;此时由 `/create-skill` 做本地检查和跳过记录。

## 输入解析

优先解析以下信息:

| 字段 | 说明 | 必需 |
|---|---|---|
| skill 名称 | kebab-case,如 `report-review` | 否 |
| 目标描述 | 该 skill 要解决什么问题 | 是 |
| 关键词 | 中文或英文关键词 | 否 |
| REQ-ID | 来源需求编号 | 标准主链路必需 |
| activeProduct | 当前产品上下文 | 有 `.skills/context.json` 时读取 |

信息不足时,只问一个核心问题:

```text
你要为哪个拟创建 skill 查蓝本,它最终要解决什么问题?
```

## 前置检查

执行前:

1. 读取 `.skills/context.json` 获取 `activeProduct`(如存在)。
2. 如果用户要求"按 plan"或"按 skill-map",读取 `.skills/{product}/docs/skill-map.md`。
3. 扫描当前仓库 `.claude/skills/*/SKILL.md`。
4. 输出项目摸底:

```text
[蓝本摸底] activeProduct:XX/无 | 已有 skill:N 个 | 待侦察:M 个 → 继续
```

## 侦察流程

### 第 1 步:本地查重

检查:

```text
.claude/skills/*/SKILL.md
```

判断:

- 是否已有同名 skill。
- 是否已有同类 skill 可复用、扩展或合并。
- 是否存在命名或定位冲突。

如果发现已有同类 skill,必须在报告中写明复用或新建理由。

### 第 2 步:生成搜索简报

先把用户目标归一化,避免泛词跑偏。搜索简报必须包含:

```text
目标动作
对象
产物形态
核心关键词
英文关键词
必须命中
排除方向
```

示例:

```text
目标动作:review
对象:report
产物形态:SKILL.md / workflow / prompt pack
核心关键词:报告验收、文档审核
英文关键词:report review, document QA, acceptance review
必须命中:输入输出、错误处理、测试 prompt
排除方向:resume skills, job skills, game skills
```

详细规则见 `references/query-strategy.md`。

### 第 3 步:生成分层查询

根据中文目标生成中英文关键词。推荐组合:

```text
filename:SKILL.md {功能关键词}
claude skill {功能关键词}
agent skill {功能关键词}
SKILL.md {功能关键词}
codex skill {功能关键词}
workflow automation {功能关键词}
prompt pack {功能关键词}
automation recipe {功能关键词}
```

查询分三层:

1. 精准找 `SKILL.md` 或类似 skill 文件。
2. 查找相近的 agent skill、workflow、prompt pack。
3. 对候选 repo 做 repo 内证据查询,如错误处理、测试 prompt、输入输出和 docs/templates。

### 第 4 步:查找公开蓝本

优先入口:

- Anthropic Skills 官方示例。
- OpenAI Codex sample skills 或官方示例。
- Composio awesome-codex-skills。
- addyosmani agent-skills。
- 主题相近的公开 workflow、prompt pack、automation recipe。

要求:

- 尽量比较 2-3 个候选。
- 如果只能找到 0-1 个候选,说明原因。
- 不因没有候选而阻塞后续创建。
- 工具支持精确 qualifier 时优先使用 `filename:`、`repo:`、`path:` 等过滤;工具不支持时,在候选筛选阶段手动剔除跑偏结果。
- 当前环境没有可用联网搜索能力时,直接进入联网失败处理,不伪造在线结果。

### 第 5 步:候选硬门槛

候选进入"候选对比"表前,至少满足:

- 有明确 URL。
- 能看到 license,或明确标记为 `未知` / `无许可证`。
- 有 `SKILL.md`、README、workflow 文档、prompt pack 或脚本说明之一。
- 能提取至少 1 个可借鉴点。
- 能说明至少 1 个不直接采用的理由。

不满足硬门槛的结果只进入"查询记录"或"未纳入候选的结果",不进入"候选对比"。

### 第 6 步:评估候选

每个候选至少评估:

| 维度 | 检查内容 |
|---|---|
| 相关性 | 是否解决相近问题 |
| 结构 | 是否有清晰触发条件、输入、输出、边界 |
| 许可证 | MIT / Apache / BSD / 未知 / 无许可证 |
| 维护情况 | 最近提交时间、issue 活跃度、star 仅作辅助 |
| 可迁移性 | 是否能转成 Claude skill 流程 |
| 风险 | 是否依赖私有 API、登录态、服务常驻、不可复制内容 |

许可证未知时,只能标记为"灵感参考",不能作为直接来源。

候选按 100 分评分:

| 维度 | 权重 |
|---|---:|
| 相关性 | 35 |
| 结构完整度 | 20 |
| 许可证清晰度 | 15 |
| 维护情况 | 15 |
| 本项目可迁移性 | 15 |

输出时必须写"候选评分"和"命中证据"。star 只能作为维护情况辅助,不能主导排序。

### 第 7 步:搜索质量检查

出现以下情况时,报告中的 `搜索质量` 标为 `有限` 或 `不足`:

- 只找到 0-1 个候选。
- 所有候选许可证未知。
- 候选都不是 skill/workflow/prompt 形态。
- 结果明显跑偏到职业技能、游戏技能、课程或简历。
- 只能找到封闭平台、登录态或服务常驻方案。

搜索质量不足不阻塞后续 `/create-skill`,但必须在风险中写明。

### 第 8 步:生成报告

默认写入:

```text
.skills/{product}/docs/blueprints/{skill-name}.md
```

没有 activeProduct 时写入:

```text
.skills/blueprints/{skill-name}.md
```

`.skills/` 是运行时目录,不入 git、不入 zip。

只有用户明确要求长期保留时,才可另行确认后写入:

```text
.claude/skills/{skill-name}/references/github-blueprint.md
```

正式报告模板见 `references/report-template.md`。

## 联网失败处理

如果当前环境无法访问 GitHub 或缺少可用联网搜索能力,不中断流程。必须生成降级记录:

```text
在线侦察状态:未完成
原因:网络不可用 / GitHub 无法访问 / 联网搜索能力不可用 / 权限受限
降级处理:仅完成本地查重与离线结构建议
后续风险:未对公开蓝本做许可证与结构对比
```

后续 `/create-skill` 可以继续,`/review` 需要提示风险。

## 用户跳过处理

如果用户明确要求跳过:

```text
在线侦察状态:用户跳过
原因:用户明确要求跳过 GitHub 蓝本侦察
后续风险:未对公开蓝本做结构、许可证和维护情况对比
```

## 报告模板

报告模板不直接维护在本文内,避免 `SKILL.md` 过长。生成报告前读取:

```text
references/report-template.md
```

## 与其他 skills 的交接

### `/plan`

`/plan` 可在方案中标记哪些拟建 skill 建议执行 `/github-blueprint`。

### `/create-skill`

`/create-skill` 优先读取蓝本报告;没有报告时可继续轻量创建,但必须记录:

```text
蓝本侦察:有报告 / 用户跳过 / 联网失败 / 未执行
报告路径:...
处理方式:...
```

### `/review`

`/review` 检查蓝本报告、跳过记录或联网失败记录。默认不因缺少蓝本报告阻塞验收;如果 `plan.md` 明确要求完整蓝本侦察而没有任何记录,应列为中等风险。

## 安全规则

- 不复制外部仓库大段正文、脚本、模板或测试用例。
- 不把外部仓库作为本项目权威源。
- 不跳过许可证检查。
- 不写入项目外路径。
- 不把 token、credentials、日志或 `.skills/` 报告加入分发包。

## 输出格式

执行完成后输出:

```text
[GITHUB BLUEPRINT]

目标 skill:...
报告路径:...
在线侦察:完成 / 未完成 / 用户跳过
候选数量:N
采用策略:...
风险:...
下一步:/create-skill ...
```
