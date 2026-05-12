# NMA Technical Preparation

针对Parexel / RTI / PHMR等以证据合成为核心的HTA statistician角色的技术面试和portfolio准备。

---

## Task 1: MAIC Demo（GitHub Portfolio补充）

**优先级**：高——这是目前最明显的方法论gap

**目标**：在GitHub portfolio里新增一个MAIC（Match-Adjusted Indirect Comparison）demo项目，用公开的oncology数据展示propensity reweighting逻辑。

**内容要求**：

- 用一个真实或公开模拟的RCT aggregate data + IPD场景
- 实现entropy balancing / IPW reweighting，让试验人群协变量分布匹配目标人群
- 输出：调整前 vs 调整后的treatment effect估计，并展示reweighting的影响
- 说明MAIC的局限性（不可测协变量、effective sample size缩减）
- 代码用R，有清晰README，GitLab/GitHub版本管理

**参考资料**：

- Signorovitch et al. (2010) — MAIC原始论文
- NICE DSU TSD 18 — Indirect comparisons without IPD
- R包：`maic`（CRAN）

**存放**：完成后放入GitHub repo的 `03_Evidence_Synthesis/` 或新建 `04_MAIC/` 子文件夹

---

## Task 2: NMA面试问答准备

**优先级**：高——Parexel technical interview核心考察点

**目标**：能在面试中清晰、有深度地回答NMA方法论选择问题，展示不只是"会用软件"，而是"理解方法论选择背后的逻辑"。

### 必须能流畅回答的问题

**Q1: 为什么选random effects model而不是fixed effects model？**

准备要点：

- Fixed effects假设所有研究估计同一个真实效应（只有sampling error）
- Random effects假设各研究的真实效应来自一个分布（heterogeneity的来源是临床/方法论差异）
- 实践中：如果研究间有明显的临床异质性（不同人群、不同用药方案），random effects更保守也更诚实
- Fixed effects的问题：如果heterogeneity存在但被忽视，credible interval会被低估，置信度虚高
- NICE倾向：NICE DSU通常推荐random effects，除非有充分理由相信真实homogeneity

**Q2: Network consistency怎么检验，发现inconsistency怎么处理？**

准备要点：

- 检验方法：node-splitting（把每条edge拆成直接证据和间接证据，比较是否一致）；loop inconsistency test
- 发现inconsistency后的选项：
  1. 调查来源（临床异质性？方法论差异？发表偏倚？）
  2. 做inconsistency model（放松consistency假设，如UME model）
  3. 排除造成inconsistency的研究（需要明确理由）
  4. 在report里如实呈现，说明结论的robustness受限
- 不能做的：发现inconsistency后假装没看到，只报consistency model结果

**Q3: 如何向non-statistician（如pharma的Market Access Manager）解释NMA结果？**

准备要点：

- 避免"credible interval"和"posterior distribution"——改说"我们有95%的把握这个药的疗效比对照药高X%"
- League table是最直观的展示工具：每对治疗的相对效果一目了然
- 强调不确定性：宽的CI不是失败，是诚实——NMA的局限是间接证据，要如实说
- 临床意义 > 统计显著性：HR=0.75的结果，要说"中位OS延长约X个月"而不是只说HR

### 补充准备资料

- NICE DSU TSD 2（决策模型里的evidence synthesis）
- NICE DSU TSD 4（Bayesian NMA方法论）
- Dias et al. (2013) — NMA tutorial series（Statistics in Medicine）

---

## 方法论全景图：Evidence Synthesis工具分类

### 分类框架

MAIC和ML-NMR不在Bayesian NMA"里面"，而是当NMA做不了时的替代方案。正确的分类关系：

```
Evidence Synthesis（证据合成）
├── NMA家族（网络连通时用）
│   ├── Standard Bayesian NMA
│   ├── Survival NMA（时间-事件数据专用）
│   ├── Meta-regression（NMA内部调整异质性）
│   ├── Component NMA（组合疗法专用）
│   └── IPD NMA（有个体数据时）
│
└── Population-adjusted indirect comparison（适用场景：己方有 IPD，竞品仅有 AgD）
    ├── MAIC（基于患者赋权：调整己方 IPD 的权重以对齐竞品基线）
    ├── STC（基于回归预测：用己方 IPD 建模型，代入竞品基线均值预测结局，有生态学偏倚）
    └── ML-NMR（基于多层回归：结合竞品基线联合分布对己方 IPD 模型进行数值积分，无偏）
```

---

### NMA家族内的核心工具（Standard NMA以外）

**1. Survival NMA（生存曲线NMA）**

Standard NMA处理单一效应量（HR、OR、MD）。但NICE越来越要求看完整生存曲线——因为经济模型需要分段的transition probability，一个HR不够用。

解决方案：用fractional polynomial（分数多项式）或Royston-Parmar spline在NMA框架里直接建模整条生存曲线，每个时间点都有hazard rate，不是常数HR。

- 参考：NICE DSU TSD 14（生存分析在决策模型中的应用）
- 工具：R包`survHE`、`gemtc`扩展，或自写Stan模型
- 现状：oncology的NICE submission里已是标配

**2. Meta-regression（NMA框架内的效应修正调整）**

研究间人群差异（年龄、基线风险、疾病分期）导致异质性高时，在NMA模型里加入协变量解释这个异质性。

例："baseline risk越高的研究里，这个药效果越好"——用baseline risk作为协变量，调整后的间接比较更可靠。

与ML-NMR逻辑相似（都调整effect modifier），但meta-regression在NMA框架内用aggregate data做，ML-NMR用更严格的方法避免生态学偏差。

**3. Network Inconsistency检验（必要步骤，不是独立方法）**

任何credible的NMA都必须做。两个主要方法：

- **Node-splitting**：把每条edge的直接vs间接证据分开估计，看是否显著不同
- **UME模型（Unrelated Mean Effects）**：放松consistency假设，让每条edge自由估计，与consistency model对比

NICE ERG会直接问"检验过inconsistency吗"，没做是方法论缺陷。
工具：`gemtc`里的`nma.nodesplit()`，或自写WinBUGS/Stan代码。

**4. Component NMA（组合疗法专用）**

治疗方案是多个成分的组合时（A+B vs A vs B vs 安慰剂），假设成分效果可加，同时估计每个成分的单独效果。

oncology的combination therapy（免疫联合化疗、双靶联合）里越来越常见。
工具：`pcnetmeta`包，或自写模型。

**5. IPD NMA（Individual Patient Data NMA）**

能获得多个RCT原始个体数据时，在个体水平建模。可更精确调整effect modifier、做subgroup分析、处理competing risks。方法论最严格，但数据获取最难（需pharma共享IPD，通常通过YODA/CSDR平台申请）。

---

### Population-Adjusted Indirect Comparison 三种方法详解

网络断裂（disconnected network）时，不能用标准NMA，改用以下三种方法。三者都在解决同一个问题："我有药A vs 安慰剂的数据，和药B vs 安慰剂的数据，但两个试验的人群分布不同，怎么做可信的间接比较？"

**MAIC（Match-Adjusted Indirect Comparison）**

- **需要**：index trial的IPD（个体患者数据）+ target trial的aggregate data
- **做法**：对index trial的每个患者赋予权重（entropy balancing / IPW），让index trial人群的协变量分布"像"target trial人群，然后用reweighted数据做间接比较
- **局限**：不可测协变量无法调整；reweighting会缩减effective sample size（ESS），严重时置信区间会变得极宽
- **NICE态度**：接受，但会问ESS缩减多少、有哪些不可测的effect modifier
- **工具**：R包`maic`（CRAN）

**STC（Simulated Treatment Comparison）**

- **需要**：只需aggregate data，不需要IPD
- **做法**：用index trial的aggregate data拟合一个回归预测模型，然后把target trial人群的协变量均值代入，预测"如果index trial的人群换成target trial人群，效果会是多少"，再做间接比较
- **核心缺陷**：生态学偏差（ecological bias）——用组均值拟合个体级别的效应修正模型，当效应修正是非线性时会严重失真
- **NICE态度**：比MAIC更保留，通常要求说明为什么用STC而不是MAIC
- **工具**：无专用R包，通常手写回归模型

**ML-NMR（Multilevel Network Meta-Regression）**

- **需要**：只需aggregate data（但需要协变量的分布信息，不只是均值）
- **做法**：在个体水平建立效应修正模型，然后通过数值积分（numerical integration）把个体级别预测整合回总体——既避免了生态学偏差，又不需要完整IPD
- **为什么优于STC**：STC用组均值代入（有偏），ML-NMR建个体模型再积分（无偏）
- **局限**：需要知道协变量的分布形状（均值+方差，甚至更高阶矩），计算更密集
- **NICE态度**：方法论上最受认可，NICE DSU评价高
- **工具**：R包`multinma`（Phillippo开发，CRAN）
- **原始论文**：Phillippo et al. (2020), *Statistical Science*

**三者对比**：

| 方法 | 需要IPD | 避免生态学偏差 | 数据要求 | NICE接受度 |
|------|---------|--------------|---------|-----------|
| MAIC | 是（index trial）| 是 | IPD + aggregate | 高 |
| STC | 否 | 否（有偏） | Aggregate均值 | 中 |
| ML-NMR | 否 | 是 | Aggregate均值+方差 | 最高 |

---

### 情景→方法快速查表

| 情景 | 用什么 |
|------|-------|
| 网络连通，效应量是HR/OR/MD | Standard Bayesian NMA |
| 网络连通，需要完整生存曲线 | Survival NMA（fractional polynomial/spline）|
| 网络连通，研究间有明显effect modifier | Meta-regression |
| 网络连通，需验证直接vs间接证据一致 | Node-splitting / UME（必做） |
| 网络断裂，有IPD | MAIC |
| 网络断裂，只有aggregate data | ML-NMR（严格）/ STC（简单但有偏） |
| 组合疗法，成分效果可加 | Component NMA |
| 有多个RCT的IPD | IPD NMA |

---

---

## 灵活生存分析：经济模型参数估计

生存外推（survival extrapolation）是把有限follow-up的KM曲线向长期推断，为Markov/PSM模型提供转移概率。这是HEOR statistician的核心日常技能，与Survival NMA不同——Survival NMA估计相对效果，这里估计的是绝对生存概率。

### 方法层次

**1. 标准参数模型**

| 分布 | Hazard形状 | 适用场景 |
|------|-----------|---------|
| Exponential | 常数 | 早期探索、基准 |
| Weibull | 单调递增或递减 | 最常用，最灵活 |
| Gompertz | 单调递增 | 老年肿瘤、随年龄增长的风险 |
| Log-normal | 先升后降 | 部分感染性疾病 |
| Log-logistic | 先升后降（更对称）| 加速失效场景 |
| Gamma | 灵活，先升后降 | 不常用，但有时拟合更好 |

选择原则：AIC/BIC是统计指标，但NICE ERG同等重视**临床合理性**。一条在第20年仍预测有30%生存率的曲线，即使AIC最优也会被质疑。

工具：`flexsurv` R包，`flexsurvreg()` 函数。

**2. 灵活参数模型（FPM / Royston-Parmar模型）**

用受限三次样条（restricted cubic spline）拟合log cumulative hazard，不预设特定hazard形状。当KM曲线形状复杂（S形、免疫治疗plateau、早期毒性期后平台）时，FPM通常比任何标准参数模型都拟合更好。

工具：`flexsurv::flexsurvspline()`，用`k`参数控制内部节点数（通常1-3个）。

**3. Landmark analysis（里程碑分析）**

在某个时间点（landmark time）把生存曲线分段，对每段用不同模型外推。典型应用：免疫治疗checkpoint inhibitors的三阶段模式——

- 早期（0→landmark）：治疗相关毒性/无效期，hazard较高
- 中期（landmark→plateau起点）：生存分离期
- 晚期：plateau期，部分患者长期生存（用cure fraction模型或平坦的Exponential拟合）

**4. 非比例风险（NPH）处理**

当treatment effect随时间变化（crossing curves、delayed separation）时，常数HR假设失效：

- **RMST（Restricted Mean Survival Time）**：在t*时间内的平均生存时间，不依赖PH假设。公式：∫₀ᵗ* S(t)dt。NICE和HTA机构越来越接受RMST作为primary endpoint。
- **FPM with time-varying treatment effect**：在Royston-Parmar框架里加入treatment×time交互项，允许HR随时间变化。
- **Piecewise exponential model**：把时间轴分段，每段内假设常数hazard，段与段之间hazard可以跳变。

### 和Survival NMA的区别与联系

| | 灵活生存分析（单trial）| Survival NMA（多trial网络）|
|--|------|------|
| 目的 | 估计绝对生存概率，外推到长期 | 估计治疗间的相对效果 |
| 输出 | OS/PFS survival curve → 转移概率 | HR或survival difference矩阵 |
| 用途 | 经济模型参数 | 间接比较，network synthesis |
| 典型工具 | `flexsurv` | `gemtc`, Stan, `survHE` |

**实际工作流**：Survival NMA估计relative treatment effect + anchor trial的absolute survival曲线 → 将relative effect叠加到anchor → 得到所有比较药物的absolute survival曲线 → 进入经济模型。

### 参考文献

- **NICE DSU TSD 14**（生存分析在决策模型中的应用）——这是UK HTA的权威参考，详细说明各种外推方法和NICE的期望
- Royston & Parmar (2002) — FPM原始论文
- Jackson (2016) — `flexsurv`包方法论论文（*Journal of Statistical Software*）

---

## 待办：逐项深挖

上面所有方法都只是框架级别的介绍。下一步把每一个方法掰开揉碎，一个一个细抠：

- [ ] Standard Bayesian NMA：prior选择、MCMC诊断、fixed vs random effects的判断逻辑
- [ ] Network inconsistency：node-splitting的数学逻辑、UME model的实现、发现inconsistency后的处理决策树
- [ ] Survival NMA：fractional polynomial vs spline的选择、如何把结果对接进economic model
- [ ] Meta-regression：effect modifier的识别、aggregate vs IPD level的回归差异
- [ ] Component NMA：可加性假设的验证、适用边界
- [ ] IPD NMA：数据获取路径（YODA/CSDR）、与aggregate NMA的方法论差异
- [ ] MAIC：entropy balancing vs IPW的区别、ESS诊断、sensitivity analysis
- [ ] STC：生态学偏差的来源和量化、什么情况下STC仍然是唯一选择
- [ ] ML-NMR：数值积分的直觉理解、`multinma`包的实操、与MAIC的适用边界比较（参考：Phillippo et al. 2020, *Statistical Science*；`multinma` CRAN包）
- [ ] 灵活生存分析实操：用`flexsurv`拟合6种标准参数模型 + FPM，生成AIC/BIC比较表 + 外推图，加入portfolio
