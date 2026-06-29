---
layout: post
title: "Claude Code 官方 Best Practices：90% 用户没启用的 7 个进阶机制"
date: 2026-06-29 15:13:54 +0800
author: "Jimmy"
catalog: true
tags:
---

## 正文

很多人把 Claude Code 当成一个聊天框：输入需求，拿到代码，复制粘贴。这不叫用 Claude Code，这叫用了一个会写代码的搜索引擎。

Claude Code 真正的能力在于它是一套 agentic coding 系统——能读你的代码库、编辑文件、运行命令、管理会话、自动执行工作流。但前提是，你得开启那些你不知道存在的机制。

Anthropic 在 2026 年 Q1-Q2 密集更新了官方文档和工程博客，系统梳理了 Claude Code 的 Best Practices。以下是 7 个最值得启用的进阶机制，全部基于官方一手文档。

![Claude Code 7 个进阶机制：从项目配置到并行执行到成本控制的完整工作流](/img/posts/2026-06-29-claude-code-tips/cover.png)

### 1. CLAUDE.md：项目记忆文件，但克制才是关键

CLAUDE.md 是放在项目根目录的 markdown 文件，Claude Code 每次会话开始时自动读取。你可以在里面写编码标准、架构决策、库偏好、审查清单。

但官方 Best Practices 指南有一句容易被忽略的话：**"如果删掉这行 Claude 会不会犯错？不会就删掉。"** 臃肿的 CLAUDE.md 反而会导致 Claude 忽略你真正的指令。

**怎么写好 CLAUDE.md：**

- 写构建命令和测试命令（Claude 不用每次猜）
- 写架构约定（比如"前端用 React，后端用 FastAPI"）
- 写审查清单（比如"改动后跑 typecheck"）
- 不写一次性的临时需求
- 不写大段背景介绍——Claude 会自己读代码

Claude 还会自动构建记忆（auto memory），保存构建命令和调试洞察。CLAUDE.md 是你写给它的，auto memory 是它自己记的。

一个有趣的细节：Claude 可以自行编辑 CLAUDE.md。在长时运行场景中，官方建议让 Claude 在工作过程中更新 CLAUDE.md，记录进展和发现，给后续会话留参考。

### 2. Skills：封装可复用工作流

如果你发现自己反复让 Claude 做同一种事（审查 PR、部署到 staging、生成测试用例），就该用 Skills 了。

Skill 是一个放在 `.claude/skills/` 目录下的 SKILL.md 文件，封装了一组可复用指令。Claude 可以自动调用，你也可以用 `/skill-name` 手动触发。

**三种调用模式：**

| 模式 | 人可调用 | Claude 可调用 | 适用场景 |
|---|---|---|---|
| 默认 | ✅ | ✅ | 大多数情况 |
| `disable-model-invocation: true` | ✅ | ❌ | 只想手动控制何时触发 |
| `user-invocable: false` | ❌ | ✅ | 后台自动触发的流程 |

**Skill 的隔离运行：** 在 frontmatter 中加 `context: fork`，Skill 会在独立子代理中运行，不访问你的会话历史。适合需要隔离上下文的调研类任务。

官方建议：把 CLAUDE.md 里只适用于某些场景的指令迁移到 Skills 中。CLAUDE.md 每次会话都加载，Skills 按需加载——这样可以减少 token 消耗。

### 3. Hooks：你不加 Hook，就在做人肉 Hook

Hooks 让你在 Claude Code 的工具事件前后自动运行 shell 命令。这不是可选项，而是团队协作的刚需。

**常用 Hook 事件：**

| 事件 | 触发时机 | 典型用途 |
|---|---|---|
| `PreToolUse` | 工具执行前 | 安全检查、命令过滤 |
| `PostToolUse` | 工具执行后 | 自动格式化、lint 检查 |
| `Stop` | Claude 准备停止时 | 跑测试、检查是否真的完成 |
| `SubagentStop` | 子代理完成时 | 子代理结果验证 |
| `PreCompact` / `PostCompact` | 上下文压缩前后 | 保留关键信息 |

**一个官方示例：** 用 PreToolUse Hook 过滤测试输出，只显示失败的测试：

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/hooks/filter-test-output.sh"
          }
        ]
      }
    ]
  }
}
```

Hooks 还可以直接在 Skills 和 Subagents 的 frontmatter 中定义，作用域限定在组件生命周期内。

**Stop Hook 做确定性门禁：** 官方建议用 Stop Hook 运行检查脚本，阻止 Claude 在检查通过前结束回合。Claude Code 会在连续 8 次被阻止后覆盖 hook——这是一个安全阀，防止死循环。

### 4. Subagents：被严重低估的上下文管理利器

Subagents 不是简单的"分工"。它的核心价值是**上下文隔离**。

当 Claude 调研一个代码库时，它会读大量文件——每个文件都消耗你的上下文窗口。Subagent 在独立上下文中运行，读完后只报告摘要回来。你的主会话保持干净。

**三种常见模式：**

- **隔离高容量操作：** "用 subagent 跑测试套件，只报告失败的测试和错误信息"
- **并行研究：** "用三个独立 subagent 分别调研认证模块、数据库模块和 API 模块"
- **链式 subagents：** "先用 code-reviewer subagent 找性能问题，再用 optimizer subagent 修复"

**对抗性审查：** 官方推荐用一个验证 subagent 检查另一个 subagent 的结果——做工作的 agent 不做评分。这比让同一个 agent 自己检查自己可靠得多。

Subagents 支持自定义模型、工具、权限、MCP 服务器、Hooks、内存、最大轮次等配置。你可以给不同 subagent 分配不同模型——比如用 Haiku 跑简单任务，用 Opus 跑复杂分析。

### 5. Worktrees：并行跑多个 Claude 会话

`claude --worktree feature-auth` 在隔离的 git checkout 中运行 Claude 会话。多个会话的编辑不会互相冲突。

这适合的场景：
- 同时推进多个不相关功能
- 在一个会话跑实验，另一个会话继续正式开发
- 让多个 Claude agent 并行处理不同模块

官方还提供 `--worktreeinclude` 文件来控制 worktree 包含哪些文件，避免不必要的文件被复制。

### 6. Plan 模式与 Auto Mode：先想后做 vs 放手让它跑

**Plan 模式：** `claude --permission-mode plan` 或 Shift+Tab 切换。Claude 先规划方案，不执行任何修改。适合复杂任务——涉及超过两个文件时，先 plan 再执行。

**Auto Mode：** 跳过权限确认，Claude 自主执行。适合信任度高的个人项目或 CI/CD 环境。官方同时发布了安全机制来限制 Auto Mode 的风险。

官方还提供了一个中间方案：用 `/goal` 条件设置检查目标，一个独立的评估器在每轮后检查目标是否达成，Claude 持续工作直到目标满足。

**一个值得注意的教训：** 2026 年 3 月，Anthropic 将 Claude Code 默认推理努力从 high 降为 medium 以减少延迟。结果用户反馈质量下降，4 月 7 日回退。这说明——在 AI 编码工具中，"想得少"省下的时间，往往被"做错了"的返工时间抵消。

### 7. 成本管理：token 不是免费的

官方成本管理指南给出了具体策略：

**上下文管理：**
- 用 `/usage` 查看当前 token 使用量
- 用 `/compact` 压缩会话（可指定重点：`/compact Focus on code samples and API usage`）
- 用 `/clear` 清空会话重新开始
- 每 20-30 条消息执行一次 `/compact`

**模型选择：**
- 用 `/model` 切换模型——简单任务用 Haiku，复杂任务用 Opus
- 在 `/config` 中设置默认模型

**减少 MCP 开销：**
- 用 `/context` 查看哪些 MCP 服务器在消耗 token
- 用 `/mcp` 管理不活跃的服务器
- `gh`、`aws`、`gcloud`、`sentry-cli` 这类 CLI 工具的 MCP 服务器特别占上下文

**用 Hooks 过滤输出：** 在 PreToolUse 中过滤命令输出，只保留关键信息，减少进入上下文的 token 量。

**团队速率限制建议：**

TPM = Tokens Per Minute（每分钟 token 用量上限），RPM = Requests Per Minute（每分钟请求次数上限）。Anthropic 建议按团队规模为每个用户设置速率限制，避免个别用户耗尽团队配额：

| 团队规模 | 每用户 TPM | 每用户 RPM |
|---|---|---|
| 1-5 人 | 200k-300k | 5-7 |
| 5-20 人 | 100k-150k | 2.5-3.5 |
| 20-50 人 | 50k-75k | 1.25-1.75 |
| 50-100 人 | 25k-35k | 0.62-0.87 |
| 100-500 人 | 15k-20k | 0.37-0.47 |
| 500+ 人 | 10k-15k | 0.25-0.35 |

### 总结：从"用"到"用好"的差距

这 7 个机制不是锦上添花，而是 Claude Code 从"聊天工具"变成"工程平台"的关键：

1. **CLAUDE.md** 让每个会话不用从零开始
2. **Skills** 让团队经验可复用
3. **Hooks** 让质量门禁自动化
4. **Subagents** 让上下文不爆炸
5. **Worktrees** 让并行不冲突
6. **Plan / Auto Mode** 让控制力度可选
7. **成本管理** 让 token 不白花

每个机制单独看都不复杂，但组合起来就是一个完整的 AI 编程工作流。差距不在于你用不用 Claude Code，而在于你用了它多少机制。

### 一个值得想的问题

如果这些机制已经成为官方推荐的标准实践，那未来会不会出现一个"Claude Code 配置即代码"的生态——团队共享 CLAUDE.md 模板、Skills 包、Hooks 脚本，就像今天共享 CI/CD 配置一样？

## 参考资料

- Overview - Claude Code Docs — Anthropic，页面未提供（持续更新的官方文档）。https://docs.anthropic.com/en/docs/claude-code/overview
- Best practices for Claude Code — Anthropic，页面未提供（持续更新的工程博客）。https://www.anthropic.com/engineering/claude-code-best-practices
- Long-running Claude for scientific computing — Anthropic，2026-03-23。https://www.anthropic.com/research/long-running-Claude
- Extend Claude with skills - Claude Code Docs — Anthropic，页面未提供（持续更新的官方文档）。https://docs.anthropic.com/en/docs/claude-code/skills
- Hooks reference - Claude Code Docs — Anthropic，页面未提供（持续更新的官方文档）。https://docs.anthropic.com/en/docs/claude-code/hooks
- Create custom subagents - Claude Code Docs — Anthropic，页面未提供（持续更新的官方文档）。https://docs.anthropic.com/en/docs/claude-code/sub-agents
- Common workflows - Claude Code Docs — Anthropic，页面未提供（持续更新的官方文档）。https://docs.anthropic.com/en/docs/claude-code/common-workflows
- Manage costs effectively - Claude Code Docs — Anthropic，页面未提供（持续更新的官方文档）。https://docs.anthropic.com/en/docs/claude-code/costs
- An update on recent Claude Code quality reports — Anthropic，2026-04-23。https://www.anthropic.com/engineering/april-23-postmortem
- Effective harnesses for long-running agents — Anthropic，2025-11-26。https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents
