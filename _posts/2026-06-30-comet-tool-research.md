---
layout: post
title: "Comet 不是又一个 AI 编码工具，它想解决的是 Agent 长任务失控"
date: 2026-06-30 22:44:45 +0800
author: "Jimmy"
catalog: true
tags:
---

## 正文

![Comet 不是又一个 AI 编码工具，它想解决的是 Agent 长任务失控](/img/posts/2026-06-30-comet-tool-research/cover.png)

![Comet 工作流左侧是想法和 Spec、设计任务、构建测试，右侧是状态 Guard、验证证据、归档变更，边线标注创建、拆解、实现、归档、约束和留痕。](/img/posts/2026-06-30-comet-tool-research/diagram.png)

*图：Comet 用阶段状态和 guard 把长任务拆成可恢复、可验证的流程。*

如果你经常让 AI agent 改一个跨文件、跨步骤的功能，最烦的往往不是“它会不会写代码”，而是它做到一半忘了需求、跳过测试、文档不同步，或者换个会话就接不上。Comet 这个项目想解决的正是这类长任务失控问题。

先说结论：Comet 不是单纯的代码生成工具。它更像一个 agent skill harness，把 OpenSpec、Superpowers、CodeGraph 和一组项目脚本串起来，让 AI 编码任务按 Open、Design、Build、Verify、Archive 五个阶段推进。这个判断来自项目 README、中文 README、package.json、Auto Transition 文档和 CHANGELOG。它的使用价值，也要放在“阶段化工作流”里看，而不是拿它和一个普通聊天窗口对比。

普通 AI 编码助手的流程通常是：你描述需求，模型读代码，给补丁，跑测试，结束。这个流程适合小修小补，但一旦任务变长，问题就会出现：需求文件在哪里？设计有没有确认？实现到哪个任务？验证证据是什么？这次改动怎么归档？如果这些状态只存在聊天上下文里，agent 一旦换会话或上下文压缩，可靠性就会下降。

Comet 的做法，是把这些过程变成项目内可追踪的阶段。

Open 阶段负责打开一个 OpenSpec change，把模糊想法变成可追踪的变更。Design 阶段偏向深入设计和任务拆分。Build 阶段执行实现和测试驱动。Verify 阶段强调验证证据。Archive 阶段把完成的变更归档。项目 README 把这条主线描述为从 idea 到 archive 的阶段化自动化；CHANGELOG 也显示，近期版本在 review_mode、phase-skip enforcement、hook guard、verification evidence、context compression 等方向持续补强。

实际怎么用？

第一步，准备环境。官方 README 写明需要 Node.js 20+、npm/npx、Git 和 Bash 兼容 shell。

第二步，全局安装：

```bash
npm install -g @rpamis/comet
```

第三步，在项目目录初始化：

```bash
cd your-project
comet init
```

`comet init` 会选择 AI 编码平台、安装范围、技能语言和可选依赖，并部署 Comet、OpenSpec、Superpowers、CodeGraph 相关能力。README 称它支持 29 个 AI 编码平台。这个数字来自项目官方 README，是否每个平台体验完全一致，还需要实际试用确认。

初始化后，几个 CLI 命令最常用：

- `comet status`：查看当前 active change、阶段和下一步。
- `comet dashboard`：打开本地只读 dashboard。
- `comet doctor`：诊断安装和环境问题。
- `comet update`：更新 Comet。
- `comet uninstall`：移除 Comet 管理的技能、规则和钩子。

Agent 侧主要用 `/comet` 作为主入口。它会根据当前 Spec 状态和 Comet 状态判断下一步。也可以分阶段使用 `/comet-open`、`/comet-design`、`/comet-build`、`/comet-verify`、`/comet-archive`。如果任务较小，README 还提供 `/comet-hotfix` 和 `/comet-tweak` 作为快捷路径。

给一个更具体的试用例子。

假设你有一个 Node.js demo 项目，里面已经有评论列表接口，现在想让 AI agent 增加“评论点赞”功能。这个任务不算大，但会涉及需求说明、接口变更、数据结构、测试和文档，正好适合观察 Comet 的完整流程。

你可以这样开始：

```bash
mkdir comet-demo && cd comet-demo
git init
npm init -y
npm install -g @rpamis/comet
comet init
comet status
```

然后在 AI 编码环境里发起需求：

```text
/comet-open
为评论系统增加点赞功能：每条评论可以被点赞一次，需要保存点赞数，补充接口测试，并更新 README 的 API 示例。
```

进入 Design 阶段后，不要急着让 agent 写代码。先让它明确几件事：点赞接口路径是什么，重复点赞怎么处理，点赞数存在哪里，已有测试框架怎么接入，README 要更新哪段。这个阶段的价值，是把“我要点赞功能”变成可执行的设计和任务清单。

接着进入 Build：

```text
/comet-build
按设计实现点赞接口，补充测试，保持现有接口兼容。
```

这时你重点看三类输出：代码补丁、测试结果、任务状态。普通聊天式开发经常只看补丁，但 Comet 的重点是把“做到了哪一步”和“验证证据在哪里”也留下来。

实现后再走 Verify：

```text
/comet-verify
检查点赞功能、重复点赞处理、测试结果和 README 示例是否完整。
```

最后归档：

```text
/comet-archive
```

这个例子的意义不在于点赞功能多复杂，而在于你可以观察 Comet 是否真的帮你回答这些问题：需求有没有被写成 change？设计有没有明确？任务有没有拆开？测试证据有没有记录？换一个会话后，`comet status` 能不能告诉你下一步？如果答案是肯定的，它才对你的真实项目有价值。

Comet 比较关键的机制，是它不只靠一句 prompt 约束 agent，而是把状态写进项目。研究卡里最值得注意的是 `.comet.yaml`：它用于记录 change、phase、任务进度、质量门禁、证据和归档状态。Auto Transition 文档还特别说明，`auto_transition` 只控制阶段推进后是否自动调用下一个 skill，不控制阶段推进本身；阶段推进由 guard 脚本 apply。这一点很重要，因为它说明 Comet 不是简单“自动一路跑到底”，而是把自动化和阶段门禁拆开。

这也是它适合的第一类场景：长周期 AI 编码任务。

比如你要让 agent 重构一个模块、补齐测试、更新文档、最后归档设计决策。这个任务不适合只靠一次对话完成。你需要知道它当前处于设计、实现还是验证；你也需要在中途接手、暂停、恢复。Comet 的状态文件、status 命令和 dashboard 正是为这类任务服务。

第二类场景，是团队想给 AI agent 加流程边界。

很多团队用 AI 编码工具后，会遇到一个现实问题：代码确实改快了，但需求、设计、测试记录、验证证据不一定跟上。Comet 把 OpenSpec 和 Superpowers 接进来，本质上是在告诉 agent：你不是只负责改代码，你还要按 spec、设计、任务、验证、归档来走。对团队来说，这比“大家各自写 prompt”更容易形成共同流程。

第三类场景，是想研究 skill/plugin 编排的人。

Comet 自己就是一个多组件编排样本。它不是一个模型，也不是一个编辑器插件，而是把多个 skill、CLI、shell 脚本、状态文件和平台适配层组合起来。对 OpenClaw、Codex、Claude Code、Cursor、OpenCode 这类生态的用户来说，它的参考价值可能不只在“拿来用”，也在“看别人如何把 agent workflow 做成可安装工具”。

但 Comet 不适合所有任务。

如果只是改三行配置、修一个 typo、写一个临时脚本，直接让 AI 助手动手通常更快。Comet 会引入 OpenSpec、Superpowers、多份配置、阶段状态和额外命令。对轻量任务来说，这些流程会变成摩擦。

如果团队本身不接受 spec-first，也不愿意维护设计和验证文档，Comet 的收益也会下降。它不是魔法按钮，而是一套流程约束。流程只有被执行，才有价值。

还有一个版本口径要注意。仓库 package.json 和 CHANGELOG 显示当前版本为 0.3.11，但 GitHub Releases 页面 latest 显示为 0.3.9，npm registry 当前 latest 这次没有核验成功。因此，正式安装前最好自己再跑一次：

```bash
npm view @rpamis/comet version
```

最后给一个实用判断：如果你的 AI 编码任务可以在一个会话里讲清楚、一次补丁解决、失败了也没太大成本，就不需要急着上 Comet。如果你的任务需要跨阶段推进、有人审查、需要验证证据、还可能隔天继续，那 Comet 值得试。

可执行建议：

1. 先不要在核心项目里试，建一个 demo repo 跑 `comet init`、`comet status`、`comet doctor`。
2. 用一个中等复杂度任务测试完整链路，比如“新增一个带测试的小功能并更新文档”。
3. 观察 `.comet.yaml`、OpenSpec change、验证记录和归档结果是否真的帮你减少上下文管理成本。
4. 如果只是个人轻量使用，优先试 `/comet-tweak` 或 `/comet-hotfix`，不要一开始就把所有任务都纳入完整流程。
5. 团队引入前，先约定什么任务必须走 Design/Verify，什么任务可以绕过完整流程。

我更看好 Comet 作为“AI 编码流程化”的样本，而不是把它包装成万能工具。AI agent 真正进入工程现场后，模型能力只是一部分，状态、门禁、验证和归档会越来越重要。Comet 正是在这个方向上给了一个很具体的实现。

## 参考资料

- GitHub - rpamis/comet: Comet: agent skill harness phase-guarded automation from idea to archive — rpamis/comet 项目维护者，页面显示 latest release 0.3.9 为 2026-06-18；README 页面未提供单独发布日期。https://github.com/rpamis/comet
- @rpamis/comet 中文 README — rpamis/comet 项目维护者，页面未提供。https://raw.githubusercontent.com/rpamis/comet/master/README-zh.md
- package.json — rpamis/comet 项目维护者，页面未提供。https://raw.githubusercontent.com/rpamis/comet/master/package.json
- CHANGELOG.md — rpamis/comet 项目维护者，页面未提供；条目覆盖 0.1.0 至 0.3.11。https://github.com/rpamis/comet/blob/master/CHANGELOG.md
- 自动流转（Auto Transition） — rpamis/comet 项目维护者，页面未提供。https://raw.githubusercontent.com/rpamis/comet/master/docs/AUTO-TRANSITION.md
- 上下文压缩（Context Compression） — rpamis/comet 项目维护者，文档内测试日期 2026-06-07；页面未提供发布日。https://raw.githubusercontent.com/rpamis/comet/master/docs/CONTEXT-COMPRESSION.md
- Releases · rpamis/comet — rpamis/comet 项目维护者，最新 GitHub release 0.3.9 为 2026-06-18。https://github.com/rpamis/comet/releases
