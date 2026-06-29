---
layout: post
title: "别把 Codex app 当聊天框：它其实是一套本地工程中控台"
date: 2026-06-29 21:25:04 +0800
author: "Jimmy"
catalog: true
tags:
---

很多人第一次打开 Codex app，会下意识把它当成一个“带文件读写能力的聊天框”：问一句，等它改点代码，再自己回 IDE 里收尾。

这样用当然也行，但有点浪费。

Codex app 真正有意思的地方，不是它能不能写出一段函数，而是它把几个原本分散的工程动作放进了同一个控制面板里：本地线程、云端任务、worktree、automation、skills、plugins、sandbox、handoff。

如果说 CLI 更像一把随手可用的扳手，IDE 扩展更像副驾驶，那 Codex app 更像一个工程驾驶舱。你不只是“让它写代码”，而是在调度一组 agent 工作流。

![Codex app：从聊天框到工程中控台](/img/posts/2026-06-29-codex-app-tips/cover.png)

下面不按“功能列表”讲，而按一个真实工程师一天里会遇到的几类场景讲。

### 第一件事：别急着提需求，先把工作台搭好

Codex 现在有几个主要入口：

| 入口 | 更像什么 | 适合什么时候用 |
|---|---|---|
| **Codex app**（macOS/Windows） | 工程驾驶舱 | 管多线程、看 diff、跑 automation、切 worktree |
| **Codex CLI** | 终端里的本地 agent | 快速修 bug、脚本化任务、CI/自动化 |
| **IDE 扩展** | 编辑器副驾驶 | 边看代码边问、把局部上下文交给 Codex |
| **Codex web / cloud threads** | 云端执行舱 | 让任务离开本机跑，生成 PR，处理并行工作 |

这几个入口不是简单的“同一个产品套了四层皮”。它们共享 Codex 的核心能力，也共享一部分本地配置层：比如 CLI、IDE extension 和 Codex app 都会读取 `~/.codex/config.toml`、项目里的 `.codex/config.toml`、`AGENTS.md`、skills、rules 等。

但不要误解成“所有入口完全共享会话历史”。更准确的说法是：**配置和能力可以复用，线程和运行环境要看你从哪里启动、连到哪台 host、选的是 Local 还是 Cloud。**

这点很关键。很多 Codex 问题本质不是模型问题，而是工作台没搭好：

- 工作目录选错了
- sandbox 权限太紧，导致它不能写文件或联网
- 本地依赖没装，测试跑不起来
- AGENTS.md 没写测试命令，它每次都在猜
- cloud thread 没拿到你本地未提交的上下文

所以，第一次认真用 Codex app，我建议先做三件事：

1. 确认项目目录和 Git 分支。
2. 打开配置文件，把默认模型、sandbox、approval、MCP、rules 调到适合你的项目。
3. 在仓库根目录写一个短而硬的 `AGENTS.md`。

### AGENTS.md 不要写成团队手册

`AGENTS.md` 是 Codex 的项目说明书。它可以放在全局 `~/.codex`，也可以放在仓库根目录或子目录。Codex 会从项目根目录一路读到当前目录，越靠近当前目录的说明优先级越高。

它最适合写三类东西：

- **怎么验证**：`npm test`、`pnpm typecheck`、`make test-payments`
- **怎么改**：目录结构、命名约定、不要碰哪些文件
- **怎么交付**：改完要跑哪些检查，PR 描述要包含什么

它最不适合写大段背景故事。

判断标准很简单：**这句话如果删掉，Codex 会不会更容易犯错？不会，就删。**

一个好的 `AGENTS.md` 应该像贴在工位旁边的操作卡，而不是一本入职手册。比如：

```md
# AGENTS.md

## Build and test

- Install dependencies with pnpm.
- Run `pnpm typecheck` after touching TypeScript files.
- Run `pnpm test -- --runInBand` before final handoff.

## Project rules

- API routes live in `src/server/routes`.
- Shared UI components live in `src/components`.
- Do not edit generated files under `src/generated`.
```

还有一个容易忽略的细节：如果你用 Codex-managed worktree，普通 `.gitignore` 里的本地文件默认不会跟过去。比如 `.env.local`、`config/secrets.json`。这时要用 `.worktreeinclude` 明确列出来。Codex 会自动复制被忽略的 `AGENTS.override.md`，不用你再写进 `.worktreeinclude`。

### 遇到复杂任务，先切 Plan，再让它动手

Codex 的 Plan mode 不是“让它输出一份漂亮方案”。它的价值是：先让 agent 读代码、问问题、拆步骤，再决定要不要动手。

官方文档里给的触发方式很直接：可以用 `/plan`，也可以用 Shift+Tab 切换。

我的建议是，下面几类任务默认先 Plan：

- 涉及多个模块的重构
- 需要迁移数据结构或 API 契约
- 你自己也说不清楚影响范围
- 需要先调查再决定怎么改
- 你准备让它开 worktree 或 cloud thread 并行做

但 Plan mode 有一个坑：不要让对话停在“计划写得很完整”。计划不是交付物，代码和验证才是。

更好的提示词是：

```text
先进入 plan 模式，读相关文件，列出风险和改动步骤。
等计划稳定后再执行。
执行完请汇报：改了哪些文件、跑了哪些验证、还有什么没完成。
```

如果你让 Codex 建了 TODO，也建议要求它结束前把每一项状态说清楚：完成、受阻、取消。这个不是为了形式感，而是防止 agent “差不多做完了”就停。

### 把重复动作封成 Skill，而不是每次复制 prompt

当你第三次输入同一类提示词时，就应该停下来想：这是不是一个 skill？

Skills 是 Codex 的可复用工作流格式。它可以是一份很短的 `SKILL.md`，也可以带脚本、参考资料和资源文件。Codex 会先只看到 skill 的名字、描述和路径，真正决定使用时才加载完整指令。这就是官方说的 progressive disclosure。

这点很重要：skill 不是“prompt 收藏夹”，而是“可复用操作规程”。

适合做成 skill 的东西：

- PR 审查：看 diff、跑测试、整理风险、给修改建议
- 发布前检查：版本号、changelog、构建产物、回滚说明
- 文档生成：按团队模板整理接口说明或迁移指南
- 安全扫描：按固定 threat model 看授权代码
- 数据分析：固定口径拉数据、出图、写结论

Skills 在 Codex CLI、IDE extension 和 Codex app 里都可用。想分发给团队，再把它打包进 plugin。

所以我的使用顺序通常是：

1. 临时任务：直接 prompt。
2. 重复 2-3 次：写成 skill。
3. 想给团队装：做成 plugin。

### Automation 不是定时提醒，而是后台值班

Codex app 里最容易被低估的功能是 Automations。

它不是“到点提醒你做事”，而是 Codex 自己到点醒来干活，结果进 Triage 收件箱。官方文档把它分成两类：

| 类型 | 怎么运行 | 适合什么 |
|---|---|---|
| **Standalone automation** | 每次从新 prompt 开始 | 每日扫描、定期检查、跨项目巡检 |
| **Thread automation** | 绑定当前线程，保留上下文 | 轮询 PR、盯部署、跟进长任务 |

我会这样用：

- 每天早上扫一遍最近失败的 CI
- 每小时检查一个 PR 有没有新 review
- 发布期间盯一个长命令或部署状态
- 定期让它看依赖升级、lint 报警、文档过期

但 automation 有一个安全边界必须说清楚：它是后台运行的，很多时候你不在场。

官方文档明确提醒：Automations 使用默认 sandbox 设置。`read-only` 下很多工具会失败；`workspace-write` 是比较合理的默认；如果你开 `danger-full-access`，后台任务就可能在你不看屏幕时改文件、跑命令、访问网络。

所以我建议：

- 先在普通线程里手动跑一遍 automation prompt。
- 确认输出可审查，再设成计划任务。
- 默认用 `workspace-write`。
- 真需要越权命令，用 Rules 精确放行，而不是全局放开。

### Worktree 是 Codex app 的分水岭

如果你只在 Local 里开一个线程，那 Codex app 和普通 IDE 聊天栏差别不大。

一旦开始用 worktree，味道就变了。

Worktrees 基于 Git worktree。你可以让多个 Codex 线程在同一个仓库里并行工作，每个线程有自己的 checkout，互不污染。

它适合这几种场景：

- 一个线程修 bug，另一个线程做重构
- 一个线程实验方案 A，另一个线程实验方案 B
- automation 在后台改文档，你继续在 Local 写代码
- 让 Codex 先在隔离环境里跑完，再 handoff 回 Local

Codex-managed worktree 默认是轻量、一次性的，通常一个线程一个 worktree，并且默认 detached HEAD。你想长期保留环境，可以创建 permanent worktree。

Handoff 是这套设计里很关键的一环。你可以把线程从 Worktree 移到 Local，也可以从 Local 移回 Worktree。Codex 会处理背后的 Git 操作，避免你手动搬 diff、切分支、撞上“同一个分支不能在两个 worktree 同时 checkout”的 Git 限制。

我的理解是：**Local 是前台，Worktree 是后台。Handoff 是把任务从后台搬到前台验收的传送带。**

### Sandbox 和 Rules：别在安全和效率之间二选一

Codex 的权限不是只有“全信任”和“全不信任”两档。

官方常见 sandbox 模式是：

| 模式 | 含义 | 适合场景 |
|---|---|---|
| `read-only` | 只能看，不能改，很多命令需要审批 | 调研、审查、不希望写文件 |
| `workspace-write` | 可在工作区内读写，越界需审批 | 日常开发默认值 |
| `danger-full-access` | 没有 sandbox 边界 | 高信任本地项目，谨慎使用 |

真正好用的是 Rules。它允许你对特定命令做精确放行、提示或禁止。比如：

- 允许 `npm test`
- 允许 `pnpm typecheck`
- 对 `gh pr view` 提示确认
- 禁止危险删除命令

这比“为了让测试能跑，把所有权限都打开”要健康得多。

尤其是配合 automations 时，Rules 很有价值：你可以让后台任务稳定执行必要命令，同时不把整台机器交出去。

### Plugins：团队分发的单位，不是炫技包装

Skill 解决的是“我怎么复用一个流程”。Plugin 解决的是“团队怎么安装一套能力”。

一个 plugin 可以包含：

- Skills
- App 集成，例如 GitHub、Slack、Google Drive
- MCP servers
- 相关资源和配置

所以 plugin 不只是“高级 skill”。它更像一个可安装的工作流包。

例如团队可以做一个“PR 值班 plugin”：

- 一个 skill 负责读 PR、跑测试、整理 review
- 一个 GitHub app 或 MCP 负责拿评论和检查状态
- 一个 automation 每隔一段时间唤醒
- Rules 只允许它跑测试、查 PR、更新指定文件

这时 Codex 就不再是个人工具，而是团队基础设施的一部分。

### 一套更实际的 Codex app 使用姿势

如果把上面这些机制串起来，我会这样用 Codex app：

1. **新项目第一次接入**：写短 `AGENTS.md`，设置 `config.toml`，确认 sandbox。
2. **复杂需求进来**：先 Plan，确认影响范围。
3. **不确定方案**：开 Worktree，让 Codex 在隔离环境里试。
4. **重复流程**：沉淀成 Skill。
5. **团队共用流程**：打包成 Plugin。
6. **需要持续关注**：设 Automation，结果进 Triage。
7. **要进主线**：Handoff 回 Local，自己验收、测试、提交。

这套流程和“打开聊天框问它怎么改”完全不是一个层级。

前者是在使用一个工程系统；后者只是把 AI 当成更快的 Stack Overflow。

### 最后：Codex 和 Claude Code 的差别在哪里？

Codex 和 Claude Code 的功能表面上越来越像：都有项目指令、skills、worktrees、subagents、权限控制。

但我觉得它们的气质不一样。

Claude Code 更像一个很强的终端工程师，擅长在一个会话里深挖、执行、反复修。

Codex app 更像一个调度台：它强调多入口、多线程、后台 automation、worktree handoff、plugins、远程 host。它的重点不是“我能不能让一个 agent 更聪明”，而是“我能不能把很多 agent 工作流管起来”。

所以选择问题也不该只问“谁写代码更强”。更好的问题是：

**你的工作流更像单兵深入，还是多线程调度？**

如果是前者，你会喜欢 Claude Code 的直接和强势。

如果是后者，Codex app 的驾驶舱感会越来越明显。

## 参考资料

- Codex app — OpenAI，持续更新的官方文档。https://developers.openai.com/codex/app
- Codex CLI — OpenAI，持续更新的官方文档。https://developers.openai.com/codex/cli
- Codex web — OpenAI，持续更新的官方文档。https://developers.openai.com/codex/cloud
- Custom instructions with AGENTS.md — OpenAI，持续更新的官方文档。https://developers.openai.com/codex/guides/agents-md
- Agent Skills — OpenAI，持续更新的官方文档。https://developers.openai.com/codex/skills
- Automations — OpenAI，持续更新的官方文档。https://developers.openai.com/codex/app/automations
- Worktrees — OpenAI，持续更新的官方文档。https://developers.openai.com/codex/app/worktrees
- Sandboxing — OpenAI，持续更新的官方文档。https://developers.openai.com/codex/concepts/sandboxing
- Rules — OpenAI，持续更新的官方文档。https://developers.openai.com/codex/rules
- Plugins — OpenAI，持续更新的官方文档。https://developers.openai.com/codex/plugins
