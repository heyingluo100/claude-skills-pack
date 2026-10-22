# /taste preflight — 提交前自查表

> 30 项检查清单。从 Taste 上游 55 项裁剪到适配 Vue + Linear 的部分。
> 用法：commit 前过一遍，未过项必须解释或修复。

---

## 设计纪律（3 项）

- [ ] Design Read 已写（类型 / vibe / dials / refs）
- [ ] dials 值已确认（默认 V7/M5/D4，或显式覆盖）
- [ ] 项目偏好层未被破坏（Inter / 紫色 accent / 紧凑间距 / 暗色 first）

## Hero（5 项）

- [ ] Headline ≤ 2 行
- [ ] Subtext ≤ 20 词（英文）或 ≤ 35 字（中文）
- [ ] Hero fit 100dvh（用 `min-h-[100dvh]` 不用 `h-screen`）
- [ ] Hero 上 padding ≤ pt-24
- [ ] Trust logos 在 Hero 下方，不在内部

## Layout（4 项）

- [ ] 8 节至少 4 种 layout 家族（不重复）
- [ ] Zigzag 连续 ≤ 2 段
- [ ] Eyebrow 每 3 节 ≤ 1 个
- [ ] Bento 格子数 = 内容数（无凑格子）

## 排版（4 项）

- [ ] 无 em-dash（英文输出场景；中文场景豁免）
- [ ] 无 `<br>` 拆 headline
- [ ] 无超大 H1 装饰（text-9xl 当装饰）
- [ ] 圆角刻度一致（一页一套）

## 色彩（3 项）

- [ ] 无纯黑 #000000 / 纯白 #ffffff（用 off-black / off-white）
- [ ] Accent 饱和度 ≤ 80%
- [ ] 主题一致（不分节切换主题）

## 内容（5 项）

- [ ] 无假人名（John Doe / Jane Smith）
- [ ] 无 Lorem ipsum 漏到 prod
- [ ] 无套路动词（Elevate / Seamless / Unlock / Empower / Transform）
- [ ] 无假精确数字（99.9% / 10x faster 无来源）
- [ ] 无 Section 序号 eyebrow（01 / 02 / 03）

## 技术（6 项）

- [ ] 无 `window.addEventListener("scroll", ...)` 直接监听
- [ ] 无 `window.scrollY` 灌进 ref/state
- [ ] 无 requestAnimationFrame 操作响应式状态
- [ ] 无 GSAP 依赖（用 Vue Transition + CSS）
- [ ] M > 3 时已加 `prefers-reduced-motion` 处理
- [ ] 动效只动 transform / opacity（无 width / height / top / left 动效）

---

## 汇总

总计：__ / 30 ✓

未过项：列出每项 + 决定（修复 / 项目例外 / 接受）
