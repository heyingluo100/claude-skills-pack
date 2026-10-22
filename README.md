# Claude Skills Pack — AI 辅助研发全流程工作流

一套面向 Claude Code 的 **Agent Skill 体系**：把「需求分析 → 方案规划 → 研发执行 → 代码审查 → 质量体检 → 会话交接」的完整研发流程沉淀为 20 个可复用的技能包，让 AI 编码助手按规范化流程交付产品，而不是随手写代码。

## 这是什么

大模型编码助手的常见问题是「拿到需求就直接写代码」，缺需求澄清、缺方案评审、缺质量约束。本项目用 Anthropic Agent Skill 规范（SKILL.md：frontmatter + 职责定位 + 执行流程 + 规则约束 + 错误处理）定义了一整套工作流技能，覆盖：

- **需求侧**：模糊需求分级澄清（/clarify）、需求结构化（/req）、技术方案规划（/plan）
- **研发侧**：脚手架（/scaffold）、开发主流程（/dev）、前端审美约束（/taste）
- **质量侧**：代码审查（/review）、规范检查（/lint）、项目体检（/health）、UI 质量检查
- **过程管理**：偏离日志（/guard）、会话交接（/handoff）、任务续接（/carryover）、打包分发（/pack）
- **自进化**：技能自主优化循环（darwin-skill）、复杂任务迭代优化（Auto-Optimize）、技能创建与评估（create-skill / eval-skill）

## 快速开始

```bash
# 1. 克隆
git clone https://github.com/heyingluo100/claude-skills-pack.git

# 2. 放置全局规范（Claude Code 全局规则目录）
cp claude-skills-pack/CLAUDE.md ~/.claude/CLAUDE.md
cp claude-skills-pack/design-system.md ~/.claude/design-system.md

# 3. 放置技能
mkdir -p ~/.claude/skills
cp -r claude-skills-pack/skills/* ~/.claude/skills/
```

## 目录结构

```
├── README.md              ← 本文件
├── CLAUDE.md              ← 全局用户规则（协作协议/中断处理/会话边界等）
├── project-CLAUDE.md      ← 项目级规则副本（按需放到项目根）
├── design-system.md       ← Vue 3 + Tailwind + Linear 风格前端设计规范
└── skills/                ← 全部技能（每个含 SKILL.md + test-prompts.json）
    ├── req/  plan/  clarify/  scaffold/  dev/  review/
    ├── lint/  health/  guard/  handoff/  carryover/  pack/
    ├── taste/  visualize/  github-blueprint/
    ├── create-skill/  eval-skill/  darwin-skill/  Auto-Optimize/
    └── ...
```

## 设计要点

1. **流程强制**：/dev 主流程内置多道关卡（需求澄清 → 方案 → 实现 → review → lint），跳步会被 /guard 记录为偏离
2. **会话边界协议**：四层载体（memory / session.json / carryover / handoff）各司其职，解决长任务跨会话断点续接
3. **自主解决优先**：明确「先读项目、再联网搜、后推断」的顺序，减少把问题甩回给操作员
4. **可评估**：每个技能附带 test-prompts.json，可用 darwin-skill 跑评估循环持续优化
5. **合规打包**：pack 技能内置打包配置，自动剔除 token、本地历史等敏感文件

## 技术栈

纯指令型 Skill（Markdown），不依赖运行时；darwin-skill 附带 HTML/SVG 图表资产，carryover/handoff 附带 JS 脚本。

---

个人作品集项目，展示 **AI 工作流设计能力**：如何把工程规范拆解为 AI 可执行、可评估、可持续进化的技能体系。
