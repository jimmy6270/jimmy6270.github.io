---
layout: post
title: "Agent Skills 火了：AI Agent 的下一步，不是更长提示词，而是可复用能力包"
date: 2026-07-02 12:10:31 +0800
author: "Jimmy"
catalog: true
tags:
---

## 正文

![Agent Skills 火了：AI Agent 的下一步，不是更长提示词，而是可复用能力包](/img/posts/2026-07-02-daily-topics/cover.png)

![重复任务触发 SKILL.md，SKILL.md 按需读取资源脚本，最终形成可复用能力。](/img/posts/2026-07-02-daily-topics/diagram.png)

*图：Agent Skills 把重复流程封装成可触发、可按需加载、可审计的能力包。*

如果你经常让 AI 做同一类任务，比如代码审查、整理会议纪要、生成研究卡、检查发布流程，最烦的不是它不会做，而是你每次都要重新交代规则。Anthropic 的 Agent Skills 想解决的就是这个问题：把重复流程变成一个可复用的能力包。

这件事的重点不在“又多了一个提示词文件”。

按 Anthropic 的官方说明，Skill 是一个目录，里面至少有一个 `SKILL.md`，还可以带 instructions、scripts、resources。Agent 会先看到每个 Skill 的名称和描述；当任务匹配时，再读取完整的 `SKILL.md`；如果还需要更细的资料，才继续读取 references、assets 或运行 scripts。

这叫 progressive disclosure。翻成工程语言，就是不要一开始把所有上下文塞进模型窗口，而是先放目录，再按需加载。

这也是 Agent Skills 和普通提示词库最大的区别。

提示词库解决的是“这段话下次还能复制”。Skills 解决的是“这套做事方法能不能被 agent 发现、加载、执行、审计、版本化”。前者像收藏夹，后者更像团队里的 runbook、模板库和自动化脚本的结合体。

一个典型 Skill 可以分成三层。

第一层是元数据。`name` 和 `description` 告诉 agent：这个 Skill 是干什么的，什么时候该用。Agent Skills 规范要求 `SKILL.md` 使用 YAML frontmatter，并把这两个字段列为必填项。

第二层是操作说明。这里写清楚任务步骤、判断标准、边界条件、常见错误。Claude Code 文档也明确说，Skills 可以自动按相关性触发，也可以用 `/skill-name` 直接调用。

第三层是外部资源和脚本。比如参考文档放在 `references/`，模板放在 `assets/`，确定性处理逻辑放在 `scripts/`。Anthropic 在工程文章里特别提到，有些事情交给代码执行，比让模型用 token 直接“想出来”更稳定，也更省上下文。

所以，Agent Skills 的真正价值，是把“我希望 AI 怎么做事”从聊天窗口里抽出来，变成一个可以维护的文件资产。

举个更具体的场景。

如果一个团队每天都要写技术文章，过去可能会把选题标准、来源规则、写作风格、审稿清单都写在一个长提示词里。每次开新会话，就复制一遍。问题是，这种方式很难复用，也很难审计：谁改了规则？哪条规则已经过期？哪些素材可以引用？哪些脚本会联网？都不清楚。

换成 Skills 思路，就可以把它拆成一个内容生产 Skill：`SKILL.md` 放主流程，`references/` 放来源规则和审稿规则，`templates/` 或 `assets/` 放文章模板，`scripts/` 放确定性检查脚本。Agent 用到时再加载，而不是每次都把全部材料塞进对话。

这就是它比“长提示词”更像工程方案的地方。

当然，也不要把 Agent Skills 神化。

第一，它不是 MCP 的替代品。MCP 更偏向外部工具和数据连接：让 agent 能访问什么。Skills 更偏向流程知识：教 agent 怎么做一类事。Anthropic 自己的表述也是未来探索 Skills 与 MCP server 互补，而不是互相取代。

第二，跨平台复用要谨慎看。Claude Code 文档说它遵循 Agent Skills 开放标准，同时也有 invocation control、subagent execution、dynamic context injection 等 Claude Code 扩展能力。也就是说，核心格式可以迁移，但具体平台特性未必无缝迁移。

第三，第三方 Skill 不是“装了就能放心用”。Anthropic 的安全提醒说得很直接：恶意 Skills 可能引入漏洞、诱导数据外传，或者让 agent 执行不该执行的动作。Anthropic 的公开 skills 仓库也强调，示例主要用于演示和教育，关键任务前要在自己的环境里充分测试。

所以，真正靠谱的用法不是到处下载 Skill，而是先从低风险、可验证的流程开始。

我建议开发者和团队按四步试：

第一，把你最常重复粘贴的流程找出来。不是一句背景知识，而是有步骤、有检查项、有输出格式的任务。

第二，先只写一个小 Skill。`description` 写清楚“什么时候该用”，正文写清楚“怎么做”和“不要做什么”。不要一开始就塞满所有资料。

第三，把长资料拆出去。稳定规则放 `references/`，模板放 `assets/`，确定性处理放 `scripts/`。让 agent 按需读取，而不是常驻上下文。

第四，像审计脚本一样审计 Skill。看它会不会读敏感文件，会不会访问外部网络，会不会执行不透明命令，会不会把不该发出的信息带出去。

Agent Skills 的信号很清楚：AI Agent 的竞争不只在模型本身，也在“能力如何被组织起来”。当模型越来越会用工具，真正拉开差距的，可能是你能不能把团队经验沉淀成一套可复用、可检查、可演化的能力包。

问题也留给你：你最想先做成 Skill 的重复流程是什么？代码审查、资料整理、发布检查，还是某个更具体的团队 SOP？

## 参考资料

- Equipping agents for the real world with Agent Skills — Anthropic，页面未提供精确日期（根据内容推断为 2025 年末至 2026 年初）。https://www.anthropic.com/engineering/equipping-agents-for-the-real-world-with-agent-skills
- Specification - Agent Skills — Agent Skills，持续更新规范，页面未提供精确发布日期。https://agentskills.io/specification
- Extend Claude with skills — Anthropic / Claude Code Docs，持续更新文档，页面未提供精确发布日期。https://code.claude.com/docs/en/skills
- Roadmap - Model Context Protocol — Model Context Protocol 官方，页面未提供精确日期（持续更新）。https://modelcontextprotocol.io/development/roadmap
- anthropics/skills: Public repository for Agent Skills — Anthropic，持续更新仓库，页面未提供精确发布日期。https://github.com/anthropics/skills
