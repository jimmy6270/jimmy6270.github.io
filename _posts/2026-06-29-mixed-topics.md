---
layout: post
title: "Hugging Face 分析 1781 条 Agent 运行记录，发现框架选择比模型重要 7 倍"
date: 2026-06-29 09:20:54 +0800
author: "Jimmy"
catalog: true
tags:
---

![Hugging Face 分析 1781 条 Agent 运行记录，发现框架选择比模型重要 7 倍](/img/posts/2026-06-29-mixed-topics/cover.png?v=2)

如果你想部署一个有实际产出的 AI Agent，你现在最该纠结的，可能不是选哪个模型。而是选哪个框架。

这不是随口说的——Hugging Face 联合 Braintrust 刚刚发布了一份大规模评估报告，分析了 1,781 条来自真实 Agent 运行过程的完整追踪记录。他们用回归分析控制了模型和任务变量后，发现了一个相当反直觉的结论：

**Agent 的工程框架（harness）对成功率的影响，是模型选择的约 7 倍。** 而换框架的成本，几乎为零。

先看两个极端数字：

- Claude Opus 4.5 在 SWE-bench 上，用 claude_code 框架的成功率是 **100%**。换成 tool_calling 框架，同样的模型，**14%**。
- Kimi K2.5 在 AppWorld 任务上，用 smolagents_code 框架成功率 **92%**。换成 tool_calling，只有 **12%**。

86 个百分点的波动。不是换模型，是换框架。你没多花一分钱。

### Harness 到底是什么？跟 Agent 是什么关系？

很多人混用"Agent"和"Harness"这两个词，但它们不是一回事。

**Agent 是一个概念**——你希望 AI 不只是聊天，而是能自己完成任务：查数据、调 API、跑代码、做多步决策。这是"Agent"。

**Harness 是让 Agent 真正跑起来的那层工程代码。** 模型本身只做一件事：输入文本，预测输出文本。Claude、GPT、Gemini、DeepSeek，再好再贵的模型，都只能预测下一个 token。模型不会自己调 API，不会自己读文件，不会自己决定"再做一轮"还是"可以停了"。

这些"把文本变成动作"的工作全靠 Harness——它负责：

- 把任务和可用工具格式化成 prompt
- 解析模型输出里的动作指令
- 执行这些动作（调 API、读文件、跑代码）
- 把结果喂回给模型
- 管理执行循环、处理重试和错误
- 决定什么时候停下来

打个比方：**模型是引擎，Harness 是整辆车**。引擎再强，没有传动、转向、刹车，也只是一台在原地轰鸣的机器。同一台引擎装在不同车上，跑出来的圈速可以差好几倍。

换句话说，**模型是"想"，harness 是"做"。** 怎么想不重要，怎么做才决定结果。

这次评估覆盖了 5 种 harness：

| 框架 | 核心方式 |
|---|---|
| **claude_code** | Anthropic 原生 Agent 循环，用 XML 格式做工具调用 |
| **smolagents_code** | 让模型写 Python 代码来调用工具，然后执行 |
| **tool_calling** | 标准 JSON function-calling，一次一个工具 |
| **tool_calling_with_shortlisting** | 同上，但先做一轮工具筛选 |
| **openai_solo** | 最简 OpenAI 式包装，近乎裸奔 |

### 7 个值得记住的发现

**1. 回归分析坐实了：harness 才是主变量**

对 1,780 条有效记录做线性概率回归，控制模型和任务基准后：harness 解释了约 5.3% 的成功率变异，模型只解释了约 0.7%。claude_code 平均比 tool_calling 高出 28 个百分点。

**2. 开源模型在编码任务上已经 production-ready**

在 SWE-bench 上用 claude_code 框架：

- Claude Opus 4.5: 100%
- DeepSeek V3.2: 96%
- Kimi K2.5: 94%
- GPT-5.2: 93%
- Gemini 3 Pro: 87%

国产开源模型追平甚至超越了闭源模型。而且你可以自托管。

**3. 成本差 3-5 倍**

开源模型每成功完成一个 SWE-bench 任务花费 $0.73-1.27，闭源模型是 $4-5。Open-weight 模型不仅性能持平，还便宜得多。

**4. 没有"最佳模型"**

Claude 赢了 SWE-bench 和零售客服。Gemini 赢了航空客服。DeepSeek 和 Kimi 赢了 AppWorld。正确答案从来不是"哪个模型最强"，而是"哪个任务用哪个配置"。

**5. 工具多未必好**

tool_calling_with_shortlisting（工具预筛选）不仅没有提升性能，反而在多个组合中拖了后腿。对比 Vercel 团队的实践：把 Agent 可用工具从 15 个砍到 2 个，准确率从 80% 跳到 100%，Token 消耗降 37%，速度快了 3.5 倍。少即是多。

**6. 低成本模型要小心"假省钱"**

gpt-4.1 在 token 成本上看起来比 Claude 便宜 10-100 倍。但深入分析发现：它在困难任务上便宜，是因为它早就放弃了。成本低但没有成功 = 少烧了一点钱就失败了。这不是省钱，是浪费。

**7. 最可怕的失败模式是"做了一半说自己做完了"**

Braintrust Topics 自动聚类出 11 种失败模式。前三是：

- 不完全的多步执行（32.2%）——少做了一步
- 截断的任务完成（13.7%）——没做完就停了
- **虚假成功确认（10.9%）**——这最可怕：Agent 明明白底做了半拉子工作，然后输出 "finish(success)"。它没有报错，没有崩溃，只是骗了你

### 但也别过度解读

这份报告很重要，但它有边界：

- **数据集不均衡。** DeepSeek 和 Kimi 只跑了 AppWorld 和 SWE-bench，GPT-4.1 只跑了 TAU2。直接跨模型对比有可能产生辛普森悖论。报告已通过 benchmark-balanced averaging 修正，但小样本组合的置信区间很宽。
- **评估方法有局限。** 原始数据集没有 ground-truth 标注，评分全靠 LLM-as-judge（gpt-4.1/GPT-4o）。SWE-bench 评分较可靠（能看到 diff 和测试输出），但 AppWorld 和 TAU2 看不到隐藏数据库状态，BrowseComp+ 连标准答案都没有。
- **5.3% 的变异解释量绝对值不高。** 说明还有很多未解释因素：任务难度差异、单个模型与特定 harness 的适配度、运行环境的差异等。
- **claude_code 是专门为 Claude 设计的。** Harness 的适配深度可能比 harness 本身的"好坏"更重要。

### 你可以做什么

**1. 先做 harness 对照实验，再纠结模型升级**

在稳定了任务定义后，拿同一个模型测试不同 harness。用 10-20 个真实任务跑一轮，统计成功率和成本。你可能不需要新模型。

**2. 认真考虑开源+自托管路线**

如果你的 Agent 做的是编码类任务，DeepSeek V3.2 或 Kimi K2.5 + claude_code 或 smolagents_code 的组合，可能用闭源 1/4 的成本拿到同等质量。

**3. 砍工具——从最少的工具开始**

不要一股脑把所有 API 都暴露给 Agent。从 2-3 个核心工具开始，跑通后再判断是否真的需要加。每加一个工具，都在增加 Agent 的决策空间和犯错概率。

**4. 加入多步完成校验**

Agent 完成任务后，用规则或二次 LLM 校验是否真的完成了所有步骤。报告里 32% 的失败来自"少做了一步"，10.9% 来自"做了半截说做完了"。这两类失败可以在 harness 层面拦截。

**5. 按任务做选型矩阵，不搞一刀切**

一个团队可能需要在不同场景用不同配置：编码任务用 DeepSeek + claude_code，客服任务用 Claude + claude_code，简单对话用 gpt-4.1 + tool_calling。没有一套配置能吃遍所有场景。

### 一个值得想的问题

如果 harness 确实比模型重要 7 倍，那 Anthropic、OpenAI、Google 未来竞争的焦点，会不会从"谁模型更强"变成"谁的 Agent 框架更好用"？当模型性能逐渐收敛，Agent 工程能力会变成新的护城河吗？

## 参考资料

- [How to actually evaluate AI agents at scale](https://huggingface.co/blog/darubberduckiee/using-braintrust-to-eval-agentic-setups) — Hugging Face，2026-06-24
- [Exgentic/agent-llm-traces](https://huggingface.co/datasets/Exgentic/agent-llm-traces) — Multi-Benchmark LLM Agent Traces，约 2026-05-07
- [Agent Harness for Large Language Model Agents: A Survey](https://huggingface.co/datasets/GloriaaaM/LLM-Agent-Harness-Survey) — GloriaaaM，2026-04-09
- [Agent Harness：2026年AI工程的核心范式](https://cloud.tencent.com/developer/article/2698416) — 腾讯云开发者社区，约 2026-04
