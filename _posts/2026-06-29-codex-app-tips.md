---
layout: post
title: "Codex app 官方文档拆解：从安装到进阶的 8 个核心机制"
date: 2026-06-29 21:25:04 +0800
author: "Jimmy"
catalog: true
tags:
---

## 正文

![Codex app 官方文档拆解：从安装到进阶的 8 个核心机制](/img/posts/2026-06-29-codex-app-tips/cover.png)

很多人把 Codex app 当成一个聊天框：输入需求，拿到代码，复制粘贴。这不叫用 Codex，这叫用了一个会写代码的搜索引擎。

Codex 真正的能力在于它是一套 agentic coding 系统——能读你的代码库、编辑文件、运行命令、管理多线程、自动执行定时任务。但前提是，你得开启那些你不知道存在的机制。

OpenAI 在 2026 年 Q1-Q2 密集更新了 Codex 产品线，从 2 月发布 app 到 3 月上线插件系统，功能快速扩展。以下是 8 个最值得掌握的核心机制，全部基于官方一手文档。

![Codex app 8 个核心机制：从项目配置到并行执行到自动化巡逻的完整工作流](/img/posts/2026-06-29-codex-app-tips/cover.png)

### 1. 四个入口：选对工具比努力更重要

Codex 不是单一产品，而是四个入口共享同一个 agent 核心：

| 入口 | 定位 | 适合场景 |
|---|---|---|
| **Codex app**（macOS/Windows） | 桌面指挥中心，多线程并行 | 多任务管理、长时间运行、automations |
| **Codex CLI** | 开源终端 agent（Rust 构建） | 本地快速迭代、CI/CD 集成、脚本自动化 |
| **IDE 扩展** | VS Code 内嵌 | 边写边问、cloud 与本地切换 |
| **Codex Cloud** | 云端隔离环境 | 重计算任务、PR 生成、无需本地环境 |

四个入口共享会话历史和配置。你在 app 里创建的 skills，在 CLI 和 IDE 扩展里也能用。ChatGPT Plus/Pro/Business/Edu/Enterprise 计划都包含 Codex 访问。

CLI 安装很简单：`npm install -g @openai/codex`，或 `brew install --cask codex`，首次运行用 ChatGPT 账号或 API key 登录。

### 2. AGENTS.md：Codex 的"项目说明书"

AGENTS.md 是 Codex 的项目指令文件。CLI 自动枚举 `~/.codex` 和从 repo root 到当前目录路径上的所有 AGENTS.md 文件，按顺序合并，后者覆盖前者。每个合并块作为独立的 user-role 消息注入对话。

**怎么写好 AGENTS.md：**

- 写构建命令和测试命令（Codex 不用每次猜）
- 写架构约定（比如"前端用 React，后端用 FastAPI"）
- 写审查清单（比如"改动后跑 typecheck"）
- 不写一次性的临时需求

一个细节：Codex 会自动将 `AGENTS.override.md` 复制到 managed worktree 中，你不需要手动配置。

### 3. Plan 模式：先想后做，但不能只停留在想

Plan 模式让 Codex 先规划方案再执行。在 app 中用 Shift+Tab 切换，或用 slash 命令切换。

官方 Prompting Guide 有一句关键要求：**"除非被要求只出计划，否则不要只以计划结束交互——计划指导编辑，交付物是工作代码。"**

这意味着 Plan 模式不是"只出方案不干活"，而是"先想清楚再干"。

**Plan closure 规则：** 结束前必须将每个 TODO 标记为：
- **Done** — 完成了
- **Blocked** — 受阻（附一句话原因和针对性问题）
- **Cancelled** — 取消（附原因）

不能以 in_progress 或 pending 结束。如果你创建了 todo，必须更新其状态。

### 4. Skills：可复用工作流，跨入口通用

Skills 是 Codex 的可复用工作流格式。你可以在 app 中创建，CLI 和 IDE 扩展中也能用。

**渐进式披露机制：** Codex 先加载每个 skill 的名称、描述和路径，只在决定使用时才加载完整的 SKILL.md 指令。这避免了上下文被大量 skill 描述塞满。

Skills 支持符号链接文件夹，方便在不同项目间共享。如果你想把 skill 分发给团队，可以打包进 Plugin。

### 5. Automations：从"随叫随到"到"主动巡逻"

Automations 是 Codex app 最被低估的功能。它让 Codex 在后台按计划自动执行任务，结果进入 Triage 收件箱。

**两种类型：**

| 类型 | 特点 | 适用场景 |
|---|---|---|
| **Standalone automation** | 每次独立运行，支持 cron 语法 | 定期检查 PR、扫描错误、更新文档 |
| **Thread automation** | 附着在线程上，保持上下文 | 轮询 Slack/GitHub、长命令监控、持续审查 |

Automations 可以结合 skills 使用 `$skill-name` 触发。例如，一个 PR 看护 skill 可以设置 recurring automation，定期检查 PR 状态并修复新审查反馈。

**Sandbox 注意事项：** Automations 使用默认 sandbox 设置。read-only 模式下写操作会失败，建议用 workspace-write 模式。full access 模式下后台 automation 风险很高——Codex 可能改文件、跑命令、访问网络，而你不在场。

**官方建议：** 先用普通线程测试 automation prompt，确认输出可审查后再排计划。

### 6. Worktrees：并行不冲突，Handoff 是独门设计

Worktrees 基于 Git worktree，让多个 Codex 线程在同一项目并行工作而不互相干扰。创建线程时选 Worktree，Codex 会基于你选择的分支创建一个独立的工作目录。

**Handoff 机制是 Codex 独有的设计：** 你可以把一个线程从 Worktree 移到 Local，或从 Local 移到 Worktree。Codex 自动处理 Git 操作，安全地在线程间移动工作。

**两种 worktree 类型：**

- **Codex-managed worktree** — 轻量一次性，专属于一个线程，默认 detached HEAD
- **Permanent worktree** — 长期存在，可启动多个线程，不会自动删除

**.worktreeinclude：** 如果你的项目有 `.env`、`config/secrets.json` 等被 .gitignore 忽略的文件，worktree 默认不会包含它们。在项目根目录创建 `.worktreeinclude` 文件，列出需要复制的被忽略路径，Codex 创建 worktree 时会自动复制。

### 7. Plugins：打包分发团队工作流

Plugins 于 2026-03-25 上线，是 Codex 从个人工具走向团队基础设施的关键一步。

一个 Plugin 是一个包含 `.codex-plugin/plugin.json` manifest 的文件夹，可以打包：
- 一个或多个 Skills
- App 集成（如 GitHub、Slack、Linear）
- MCP server 配置

**安装方式：** 从官方插件目录安装 curated 插件，或用内置 `@plugin-creator` skill 脚手架本地插件，通过 workspace 级或 home 级 marketplace 测试后分发给团队。

Plugins 在 app、CLI 和 IDE 扩展中通用。

### 8. Sandbox 权限：安全 vs 效率的权衡

Codex 有三种 sandbox 模式：

| 模式 | 能做什么 | 风险 |
|---|---|---|
| **read-only** | 只读文件，不能写、不能联网 | 最安全，但大部分工具调用会失败 |
| **workspace-write** | 可写工作区内文件，不能联网、不能操作其他 app | 推荐，平衡安全和功能 |
| **full access** | 完全访问：写任意文件、跑命令、联网 | 最高效，但需要信任 |

可以用 Rules 选择性放行特定命令——比如允许 `npm test` 但不允许 `rm -rf`。

**Automations 特别注意：** 后台 automation 如果用 full access 模式，Codex 可能在你不在场时改文件、跑命令、访问网络。官方建议将 automation 的 sandbox 设为 workspace-write，用 Rules 放行需要的特定命令。

### 总结：从"用"到"用好"的差距

这 8 个机制不是锦上添花，而是 Codex 从"聊天工具"变成"工程平台"的关键：

1. **四入口** 让你在正确场景用正确工具
2. **AGENTS.md** 让 Codex 不用每次从零开始猜你的项目
3. **Plan 模式** 让复杂任务先想清楚再动手
4. **Skills** 让团队经验可复用
5. **Automations** 让 Codex 从被动响应变成主动巡逻
6. **Worktrees** 让并行不冲突，Handoff 让切换灵活
7. **Plugins** 让工作流可打包分发
8. **Sandbox 权限** 让安全可控

每个机制单独看都不复杂，但组合起来就是一个完整的 AI 编程工作流。差距不在于你用不用 Codex，而在于你用了它多少机制。

### 一个值得想的问题

Codex 和 Claude Code 在功能集上越来越趋同——都有 Skills、项目指令文件、Subagents、Worktrees。当功能差异缩小后，什么决定了你该选哪个？是模型能力、生态集成、还是你对 agent 行为的信任程度？

## 参考资料

- Introducing the Codex app — OpenAI，2026-02-02（2026-03-04 更新 Windows 可用）。https://openai.com/index/introducing-the-codex-app
- Codex CLI — OpenAI，持续更新的官方文档。https://developers.openai.com/codex/cli
- Introducing upgrades to Codex — OpenAI，页面未提供（约 2025-2026）。https://openai.com/index/introducing-upgrades-to-codex
- Codex Prompting Guide — OpenAI（Noah MacCallum, Brian Fioca），2026-02-25。https://developers.openai.com/cookbook/examples/gpt-5/codex_prompting_guide
- Agent Skills – Codex — OpenAI，持续更新的官方文档。https://developers.openai.com/codex/skills
- Automations – Codex app — OpenAI，持续更新的官方文档。https://developers.openai.com/codex/app/automations
- Worktrees – Codex app — OpenAI，持续更新的官方文档。https://developers.openai.com/codex/app/worktrees
- Codex changelog — OpenAI，持续更新（2026-01 至 2026-06）。https://developers.openai.com/codex/changelog
