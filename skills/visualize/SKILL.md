---
name: visualize
description: 将用户提供的文字、方案、问题分析、流程说明或 skill 定义整理成结构清晰的单文件 HTML 可视化展示页。用于生成 skill 介绍页、操作指南、汇报展示页、流程图页面和评审说明页。输出必须限定在当前项目目录内。
version: 1.0.0
status: active
---

# /visualize - 内容可视化展示页生成器

## 定位

`/visualize` 把一段原始内容变成结构清晰、图文并茂的单文件 HTML 页面。页面内嵌 CSS 和 SVG,零外部依赖,可直接在浏览器中打开。

在当前 Skills 项目中,优先用于:

- 生成 skill 介绍页。
- 生成 skill 操作指南。
- 生成工作流、方案、验收报告的展示页。
- 把复杂文字内容转成流程图、对比图、时间线或多维度说明页。

## 触发条件

用户表达以下意图时触发:

- "可视化"
- "做个展示页"
- "做个演示页"
- "帮我画个图讲清楚"
- "做个汇报页面"
- "做成网页展示"
- "生成 skill 介绍"
- "生成操作指南"
- "visualize"

即使用户没有明确说"可视化",只要目标是把文字内容变成图文并茂的展示页面,也可以触发。

## 输入来源

支持两类输入:

- 直接输入:用户在对话中粘贴文字、方案、流程或分析内容。
- 文件输入:用户提供 `.md`、`.txt`、`SKILL.md` 等路径时,必须先读取文件内容,再生成页面。

如果用户只给了模糊主题,例如"帮我做个可视化讲一下 XX",先问一个核心问题:

```text
你希望这个页面主要讲清楚什么内容?
```

如果用户明确说"内容你定,不要问我",可基于主题自拟内容,但必须标注"我推断"。

## 输出路径规则

所有输出必须在当前项目目录内。

默认正式文档输出:

```text
docs/visualize/{topic}.html
```

临时或运行时输出:

```text
.skills/visualize/{topic}.html
```

禁止默认写入桌面、下载目录、`C:\`、`C:\tmp`、`C:\temp` 或其他项目外路径。

生成后不要默认打开浏览器。只需要告诉用户 HTML 文件路径;如果用户明确要求打开,再按当前环境权限处理。

## 工作流程

### Phase 1: 获取内容

1. 判断输入是直接文本还是文件路径。
2. 如果是路径,先读取文件;读取失败则说明原因。
3. 提取主题、目标读者、核心信息和需要解释的关系。
4. 如果信息不足,只问一个关键问题;不要追问技术选型、目录结构或脚本语言。

### Phase 2: 判断展示结构

根据内容选择最适合的结构:

| 结构类型 | 适用内容 | 页面组织 |
|---|---|---|
| 问题-方案型 | 有现状痛点和解决办法 | 问题区 -> 方案区 -> Before/After 对比 |
| 流程说明型 | 有阶段、步骤、先后顺序 | SVG 流程图 + 分步说明 |
| 对比分析型 | 有 A/B、优劣、取舍 | 左右对比图 + 总结表 |
| 多维度展示型 | 有多个并列模块 | 模块矩阵 + 关系图 |
| 时间线型 | 有演进阶段或版本变化 | 时间轴 + 节点详情 |
| Skill 指南型 | 有 `SKILL.md` 或 skill 说明 | 定位 -> 触发 -> 输入 -> 流程 -> 输出 -> 注意事项 |

结构明显时直接选择;存在多个合理结构时,用一句话说明选择依据。

### Phase 3: 选择视觉风格

如果用户明确指定风格,按用户要求执行。

风格别名:

| 用户说法 | 对应风格 |
|---|---|
| "Linear 风格""SaaS 风""Dashboard 风""产品汇报风" | Linear 风格 |
| "Anthropic 风格""Claude 风格""学术风""书卷风""米色风" | Anthropic 风格 |

如果用户未指定风格,默认根据内容选择:

- 产品、流程、方案、对比、操作指南:优先 Linear 风格。
- 长文、复盘、方法论、学术化说明:优先 Anthropic 风格。

选择默认风格时,在结果说明中写明选择理由。不要为了风格选择反复打断用户。

### Phase 4: 生成单文件 HTML

要求:

- 只生成一个 `.html` 文件。
- CSS、SVG 全部内嵌。
- 不使用外部 CDN、远程字体、远程脚本或图片。
- 不使用 emoji。
- SVG 中不要使用 `<foreignObject>`。
- SVG 节点必须有真实含义,禁止空洞占位。
- 页面必须有清晰标题、摘要、主体图表、关键说明和 footer。

### Phase 5: 保存并汇报

1. 保存到项目内目标路径。
2. 汇报文件路径。
3. 简述页面结构和图表类型。
4. 如未运行浏览器预览,明确说明未打开浏览器。

## Linear 风格规范

适合产品汇报、流程说明、操作指南和多模块展示。

视觉特征:

- 页面底色 `#f5f6f8`。
- Header 使用深色渐变。
- 内容区使用白色卡片。
- 用蓝、绿、橙、红、紫等语义色区分信息类型。
- SVG 使用圆角矩形、箭头、浅色填充和清晰标签。

基础 CSS:

```css
body {
  margin: 0;
  font-family: -apple-system, BlinkMacSystemFont, "Microsoft YaHei", "PingFang SC", sans-serif;
  background: #f5f6f8;
  color: #20242a;
}
.page { max-width: 1200px; margin: 0 auto; padding: 32px; }
.header {
  background: linear-gradient(135deg, #1a1a2e 0%, #16213e 50%, #0f3460 100%);
  color: #fff;
  padding: 44px;
  border-radius: 16px;
}
.card {
  background: #fff;
  border: 1px solid #e7e9ee;
  border-radius: 12px;
  padding: 28px;
  margin-top: 24px;
  box-shadow: 0 2px 12px rgba(0,0,0,0.06);
}
```

## Anthropic 风格规范

适合方法论、复盘、长文说明和克制的概念展示。

视觉特征:

- 页面底色 `#F0EEE6`。
- 主文字 `#181818`。
- 唯一强调色 `#CC785C`。
- 标题和正文使用衬线字体。
- SVG 使用线条式图形,不使用渐变和多色块。
- 章节之间用分隔线和大留白,不依赖卡片堆叠。

基础 CSS:

```css
body {
  margin: 0;
  font-family: "Iowan Old Style", "Charter", Georgia, "Songti SC", serif;
  background: #F0EEE6;
  color: #181818;
  line-height: 1.65;
  font-size: 17px;
}
.page { max-width: 1080px; margin: 0 auto; padding: 64px 32px 96px; }
.mono {
  font-family: ui-monospace, "SF Mono", Menlo, Consolas, monospace;
  letter-spacing: 0.04em;
}
.section {
  border-top: 1px solid #D9D5C8;
  padding-top: 36px;
  margin-top: 72px;
}
.accent { color: #CC785C; }
```

## Skill 介绍页内容要求

当输入是 `SKILL.md` 或用户要求生成 skill 介绍/指南时,页面必须覆盖:

- Skill 名称和一句话定位。
- 适用场景和触发语。
- 输入来源。
- 核心流程。
- 输出产物。
- 安全边界和禁止事项。
- 与当前项目主链路的关系。

如果批量生成当前项目 skills 的介绍页,索引页必须包含:

- skills 总数。
- 每个 skill 的名称、简介和入口。
- 当前主链路顺序。
- 分发包纳入状态。

## 禁止事项

- 禁止把输出默认写到项目外。
- 禁止默认打开浏览器。
- 禁止使用外部依赖。
- 禁止硬编码 token、API key、密码。
- 禁止为了视觉效果编造不存在的功能。
- 禁止修改源 `SKILL.md` 内容,除非用户明确要求。
