---
layout: post
title: "AI 编码 Agent 总忘流程？Comet 用状态机把 Skill 串成一条线"
date: 2026-06-30 11:05:24 +0800
author: "Jimmy"
catalog: true
tags:
---

## 正文

![AI 编码 Agent 总忘流程？Comet 用状态机把 Skill 串成一条线](/img/posts/2026-06-30-comet-research/cover.png)

![Comet 5 阶段流水线机制图：Open、Design、Build、Verify、Archive 五个阶段依次流转，Guard 守卫在 Build 和 Verify 转换前验证退出条件。](/img/posts/2026-06-30-comet-research/diagram.png)

*图：Comet 5 阶段流水线：Open→Design→Build→Verify→Archive，Guard 脚本在每次阶段转换前验证退出条件，状态机保证流程可靠性。*

用 Claude Code 写过功能的开发者大概都遇到过这种情况：Agent 上来就写代码，跳过了需求分析；写到一半你让它停，回来后它不记得做到哪了；任务做完但 spec 文档没更新，下一个接手的人完全摸不着头脑。

Comet 就是为解决这些问题而生的。

## 参考资料

- rpamis/comet: Comet: agent skill harness phase-guarded automation from idea to archive — rpamis（GitHub 仓库 owner），仓库持续更新，最新版本 0.3.9。https://github.com/rpamis/comet
- comet/NEWS.md at master · rpamis/comet — rpamis，持续更新，最新条目对应 0.3.9。https://github.com/rpamis/comet/blob/master/NEWS.md
- obra/superpowers: An agentic skills framework & software development methodology — obra，持续更新，最新 release v6.0.3 (2026-06-18)。https://github.com/obra/superpowers
