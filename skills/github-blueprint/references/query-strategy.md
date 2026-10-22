# GitHub 蓝本查询策略

本文件定义 `/github-blueprint` 的精准搜索策略。执行时先生成"搜索简报",再分层查询,最后按证据门槛和评分表筛选候选。

## 1. 搜索简报

搜索前先把需求归一化,避免泛词跑偏。

```markdown
## 搜索简报

目标动作:review / audit / generate / compare / sync / classify / extract / other
对象:report / video / image / skill / workflow / prompt / document / other
产物形态:SKILL.md / README / workflow / prompt pack / script / template / unknown
核心关键词:...
英文关键词:...
必须命中:触发条件 / 输入输出 / 错误处理 / 测试 prompt / 许可证
排除方向:Alexa skill / 游戏技能 / 简历 skills / 课程 skills / 泛职业技能
```

如果用户只给中文目标,应补 3-6 个英文关键词。示例:

| 中文目标 | 英文关键词 |
|---|---|
| 视频质量审核 | video quality review, video audit, media QA |
| 报告验收 | report review, document QA, acceptance review |
| 图片相似度判断 | image similarity, visual comparison, duplicate image detection |

## 2. 分层查询

### 第 1 层:精准找 skill 文件

优先找"文件形态像 skill"的结果。

```text
filename:SKILL.md "{core keyword}"
filename:SKILL.md "agent" "{core keyword}"
filename:SKILL.md "workflow" "{core keyword}"
"# /{possible-command}" "SKILL.md"
```

### 第 2 层:找相近生态

当第 1 层结果不足时,再找相近 workflow 或 prompt pack。

```text
"claude skill" "{core keyword}"
"agent skill" "{core keyword}"
"codex skill" "{core keyword}"
"prompt pack" "{core keyword}"
"workflow automation" "{core keyword}"
"automation recipe" "{core keyword}"
```

### 第 3 层:候选 repo 内深挖

对已经进入候选池的 repo,再查证据。

```text
repo:{owner}/{repo} "error handling"
repo:{owner}/{repo} "test prompt"
repo:{owner}/{repo} "input" "output"
repo:{owner}/{repo} path:skills
repo:{owner}/{repo} path:docs
repo:{owner}/{repo} path:templates
```

## 3. 排除词

当关键词过宽时,记录排除方向,避免误收结果。

```text
-alexa
-game
-resume
-course
-job
-minecraft
-roblox
-linkedin
```

说明:不同联网搜索能力对排除语法支持不一致。当前环境不支持时,在候选筛选阶段手动剔除。

## 4. 候选硬门槛

候选进入"候选对比"表前,至少满足:

- 有明确 URL。
- 能看到 license,或明确标记为 `未知` / `无许可证`。
- 有 `SKILL.md`、README、workflow 文档、prompt pack 或脚本说明之一。
- 能提取至少 1 个可借鉴点。
- 能说明至少 1 个不直接采用的理由。

不满足硬门槛的结果只进入"查询记录",不进入"候选对比"。

## 5. 候选评分

候选按 100 分评分。star 只能作为维护情况的辅助,不能主导排序。

| 维度 | 权重 | 评分说明 |
|---|---:|---|
| 相关性 | 35 | 是否解决同类问题,是否命中目标动作和对象 |
| 结构完整度 | 20 | 是否有触发条件、输入、输出、边界、错误处理 |
| 许可证清晰度 | 15 | 许可证明确且允许参考得高分;未知或无许可证低分 |
| 维护情况 | 15 | 最近提交、issue 活跃度、README 完整度,star 仅辅助 |
| 本项目可迁移性 | 15 | 是否能转成 Claude skill,是否避免服务常驻、登录态、私有 API |

输出时保留评分和一句证据:

```text
候选评分:82
命中证据:filename:SKILL.md + 有 input/output + README 包含 error handling
```

## 6. 搜索质量检查点

出现以下情况时,不要强行得出"已找到好蓝本"的结论:

- 只找到 0-1 个候选。
- 所有候选许可证未知。
- 候选都不是 skill/workflow/prompt 形态。
- 结果明显跑偏到职业技能、游戏技能、课程或简历。
- 只能找到封闭平台、登录态或服务常驻方案。

处理方式:

```text
搜索质量:不足
原因:...
降级结论:仅作为灵感参考 / 建议继续本地设计 / 建议用户提供更具体关键词
是否继续:默认继续,但在报告风险中标记
```

如果用户在线等待结果,先给短结论再继续深挖;如果用户要求快速创建,记录原因后交给 `/create-skill`。
