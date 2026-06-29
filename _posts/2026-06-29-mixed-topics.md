---
layout: post
title: "Hugging Face 分析 1781 条 Agent 运行记录：框架选择可能比模型更关键"
date: 2026-06-29 09:20:54 +0800
author: "Jimmy"
catalog: true
tags:
---

如果你想部署一个有实际产出的 AI Agent，你现在最该纠结的，可能不是先换哪个模型，而是先检查自己用了什么框架。

这不是随口说的——Hugging Face 联合 Braintrust 刚刚发布了一份大规模评估报告，分析了 1,781 条来自真实 Agent 运行过程的完整追踪记录。他们用回归分析控制了模型和任务变量后，发现了一个相当反直觉的结论：

**Agent 的工程框架（harness）对成功率的影响，在这组数据里约为模型选择的 7 倍。** 而且切换 harness 对 token 成本的影响很小。

![Hugging Face 分析 1781 条 Agent 运行记录：框架选择可能比模型更关键](/img/posts/2026-06-29-mixed-topics/cover.png?v=2)

先看一个足够直观的数字：

- Kimi K2.5 在 AppWorld 任务上，用 `smolagents_code` 框架成功率 **92%**。换成 `tool_calling`，只有 **12%**。

约 80 个百分点的波动。不是换模型，是换框架。

原文还提到 Claude 在 SWE-bench 上存在 `claude_code` 100% vs `tool_calling` 14% 的对比。不过从它后面的结果表看，Claude 的 14% 更像是 AppWorld 上 `tool_calling` 的结果，而不是 SWE-bench 的同基准对照。因此更稳妥的读法是：**harness 确实能带来很大的成功率差异，但具体数字要按同一个 benchmark、同一个模型组合来看。**

### Harness 到底是什么？跟 Agent 是什么关系？

很多人混用“Agent”和“Harness”这两个词，但它们不是一回事。

**Agent 是一个概念**——你希望 AI 不只是聊天，而是能自己完成任务：查数据、调 API、跑代码、做多步决策。这是“Agent”。

**Harness 是让 Agent 真正跑起来的那层工程代码。** 模型本身只做一件事：输入文本，预测输出文本。Claude、GPT、Gemini、DeepSeek、Kimi，再好再贵的模型，都不会天然自己调 API、读文件、决定“再做一轮”还是“可以停了”。

这些“把文本变成动作”的工作全靠 harness。它负责：

- 把任务和可用工具格式化成 prompt
- 解析模型输出里的动作指令
- 执行这些动作（调 API、读文件、跑代码）
- 把结果喂回给模型
- 管理执行循环、处理重试和错误
- 决定什么时候停下来

打个比方：**模型是引擎，harness 是整辆车**。引擎再强，没有传动、转向、刹车，也只是一台在原地轰鸣的机器。同一台引擎装在不同车上，跑出来的圈速可以差很多。

换句话说，**模型负责“想”，harness 负责“做”。** 模型当然重要，但在这组实验里，harness 是更容易被低估、也更高杠杆的变量。

这次评估覆盖了 5 种 harness：

| 框架 | 核心方式 |
|---|---|
| **claude_code** | Anthropic 原生 Agent 循环，用 XML 格式做工具调用 |
| **smolagents_code** | 让模型写 Python 代码来调用工具，然后执行 |
| **tool_calling** | 标准 JSON function-calling，一次一个工具 |
| **tool_calling_with_shortlisting** | 同上，但先做一轮工具筛选 |
| **openai_solo** | 最简 OpenAI 式封装，近乎裸跑 |

### 7 个值得记住的发现

**1. 回归分析显示：harness 是更高杠杆的变量**

对 1,780 条有效记录做线性概率回归，控制模型和任务基准后：harness 解释了约 5.3% 的成功率变异，模型只解释了约 0.7%。`claude_code` 平均比 `tool_calling` 高出 28 个百分点。

这里的重点不是“模型不重要”，而是：当你已经选定任务和模型后，harness 往往是一个更便宜、更容易被忽视的调优旋钮。

**2. 开放权重模型在编码任务上已经很能打**

在 SWE-bench 上使用 `claude_code` 框架：

- Claude Opus 4.5: 100%
- DeepSeek V3.2: 96%
- Kimi K2.5: 94%
- GPT-5.2: 93%
- Gemini 3 Pro: 87%

DeepSeek 和 Kimi 这类开放权重模型已经接近甚至超过部分闭源模型配置。而且它们有自托管空间。

**3. 成本差距很大**

开放权重模型每成功完成一个 SWE-bench 任务花费约 $0.73-1.27，闭源模型约 $4-5。也就是说，在部分编码任务上，开放权重模型不仅质量接近，单位成功成本也更低。

**4. 没有“最佳模型”**

Claude 赢了 SWE-bench 和部分客服任务。Gemini 赢了航空客服。DeepSeek 和 Kimi 赢了 AppWorld。正确答案从来不是“哪个模型最强”，而是“哪个任务用哪个配置”。

**5. 工具多未必好**

`tool_calling_with_shortlisting`（工具预筛选）不仅没有稳定提升性能，反而在多个组合中拖了后腿。原文的解释是：缩小工具集合可能会移除有用工具，或者引入额外的路由错误。

这也提醒我们：不要一股脑把所有 API 都暴露给 Agent。工具越多，决策空间越大，选错工具、漏掉关键步骤、绕远路的概率也越高。

**6. 低成本模型要小心“假省钱”**

`gpt-4.1` 在 token 成本上看起来比 Claude 便宜 10-100 倍。但深入分析发现：它在困难任务上便宜，有时是因为它很早就失败或放弃了。

成本低但没有成功，不是省钱，只是更便宜地失败。

**7. 最可怕的失败模式是“做了一半说自己做完了”**

Braintrust Topics 自动聚类出 11 种失败模式。前三是：

- 不完全的多步执行（32.2%）：少做了一步
- 截断的任务完成（13.7%）：没做完就停了
- **虚假成功确认（10.9%）**：Agent 明明白白只做了半拉子工作，然后输出 `finish(success)`

最后一种尤其危险。它没有报错，没有崩溃，只是让你误以为任务已经完成。

### 但也别过度解读

这份报告很重要，但它有边界：

- **数据集不均衡。** DeepSeek 和 Kimi 主要跑了 AppWorld 和 SWE-bench，GPT-4.1 主要跑了 TAU2。直接跨模型对比可能产生辛普森悖论。报告已通过 benchmark-balanced averaging 修正，但小样本组合的置信区间仍然很宽。
- **评估方法有局限。** 原始数据集没有官方 verdict，评分依赖 LLM-as-judge。SWE-bench 评分相对可靠，因为 judge 能看到 diff 和测试输出；AppWorld 和 TAU2 看不到隐藏数据库状态或隐藏评分规则；BrowseComp+ 连标准答案都没有。
- **5.3% 的变异解释量绝对值不高。** 这说明还有很多未解释因素：任务难度差异、模型与特定 harness 的适配度、运行环境差异等。
- **`claude_code` 的适配深度很重要。** 它不是一个完全中性的 wrapper。很多干净对比都经过 `claude_code`，因此结论更应该理解为“模型 + harness 的组合效果”，而不是简单地给所有 harness 排绝对名次。

### 你可以做什么

**1. 先做 harness 对照实验，再纠结模型升级**

在稳定任务定义后，拿同一个模型测试不同 harness。用 10-20 个真实任务跑一轮，统计成功率、成本和失败类型。你可能不需要先换模型。

**2. 认真考虑开放权重 + 自托管路线**

如果你的 Agent 做的是编码类任务，DeepSeek V3.2 或 Kimi K2.5 加上合适的 harness，可能用更低成本拿到接近闭源模型的质量。

**3. 砍工具——从最少的工具开始**

不要一股脑把所有 API 都暴露给 Agent。从 2-3 个核心工具开始，跑通后再判断是否真的需要加。每加一个工具，都在增加 Agent 的决策空间和犯错概率。

**4. 加入多步完成校验**

Agent 完成任务后，用规则或二次 LLM 校验是否真的完成了所有步骤。报告里 32.2% 的失败来自“不完全的多步执行”，10.9% 来自“虚假成功确认”。这两类失败可以在 harness 层面拦截。

**5. 按任务做选型矩阵，不搞一刀切**

一个团队可能需要在不同场景用不同配置：编码任务用开放权重模型加代码执行型 harness，客服任务用更擅长对话和工具调用的闭源模型，简单对话用低成本模型。没有一套配置能吃遍所有场景。

### 一个值得想的问题

如果 harness 在真实 Agent 任务里确实这么关键，那 Anthropic、OpenAI、Google 未来竞争的焦点，会不会从“谁模型更强”逐渐扩展到“谁的 Agent 工程框架更可靠”？

当模型性能逐渐收敛，Agent 工程能力可能会变成新的护城河。

## 参考资料

- [How to actually evaluate AI agents at scale](https://huggingface.co/blog/darubberduckiee/using-braintrust-to-eval-agentic-setups) — Hugging Face，2026-06-24
- [Exgentic/agent-llm-traces](https://huggingface.co/datasets/Exgentic/agent-llm-traces) — Multi-Benchmark LLM Agent Traces，约 2026-06-07
- [Agent Harness for Large Language Model Agents: A Survey](https://huggingface.co/datasets/GloriaaaM/LLM-Agent-Harness-Survey) — GloriaaaM，2026-04-09
- [Agent Harness：2026年AI工程的核心范式](https://cloud.tencent.com/developer/article/2698416) — 腾讯云开发者社区，约 2026-04
