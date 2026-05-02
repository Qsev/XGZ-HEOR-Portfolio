# 🦟 Project Case Study: "Stan Cannon vs. Mosquito"

*Demystifying the Inner Workings of Bayesian MCMC Sampling*

> **"To master complex Evidence Synthesis, one must first understand the friction between Prior belief and Data reality in its simplest form."**

---

## 🎯 Project Objective

In high-stakes HTA appraisals, we often use "heavy weaponry" like **Stan** and **HMC (Hamiltonian Monte Carlo)** for complex Network Meta-Analyses (NMA). However, the underlying mechanics can remain a "black box."

This project performs a **forensic deconstruction** of MCMC by applying these industrial-grade tools to a trivial problem: estimating a drug recovery rate $\theta$ based on a sample of **10 patients (7 successes, 3 failures)**. By comparing manual R-based samplers against Stan, we visualize the "gears" of Bayesian inference.

---

## 1. Establishing the Benchmarks: Frequentist vs. Exact Bayesian

Before launching the MCMC "robots," we establish the mathematical "Ground Truth."

### 1.1 The Frequentist Anchor (MLE)

Using **Maximum Likelihood Estimation (MLE)**, we find the $\theta$ that maximizes the probability of observing 7/10 cures.

* **Likelihood**: $\text{Binomial}(10, 7)$
* **Result**: $\hat{\theta}_{MLE} = 0.700$
* **Critique**: MLE is purely data-driven but highly sensitive to small sample sizes ($N=10$), often overestimating effects in "lucky" trials.

### 1.2 The Exact Bayesian Solution (Analytic Conjugacy)

By using a **Conjugate Prior**, we can calculate the "True" posterior distribution without any sampling.

* **Prior**: $\text{Uniform}(0,1)$, which is equivalent to $\text{Beta}(\alpha=1, \beta=1)$.
* **Likelihood**: $\text{Binomial}(n=10, y=7)$.
* **Posterior**: $\text{Beta}(\alpha + y, \beta + n - y) = \text{Beta}(8, 4)$.
* **Analytic Mean**: $8 / (8 + 4) = \mathbf{0.667}$.

> [!IMPORTANT]
> **Audit Observation: The "Pull" of the Prior**
> Notice the shift from **0.700 (MLE)** to **0.667 (Bayesian)**. Even a "non-informative" Uniform prior acts as a **structural anchor**, pulling the result toward 0.5. In HTA, this represents **Scientific Humility**—refusing to believe a 70% success rate entirely when the evidence base is sparse.

---

## 2. The "Bolt-Action Rifle": Manual Metropolis-Hastings (MH)

To understand how software like WinBUGS or JAGS works, I reverse-engineered a **Metropolis-Hastings** sampler from scratch in R.

### 2.1 The Algorithmic Walkthrough

1. **Random Walk**: The sampler starts at a random $\theta_{curr}$ and proposes a move to $\theta_{prop}$ with a small random "nudge" (Gaussian noise).
2. **The Acceptance Ratio**: It compares the "Height" (Posterior Density) of the two points:
    $$\text{Ratio} = \frac{\text{Likelihood}(\theta_{prop}) \times \text{Prior}(\theta_{prop})}{\text{Likelihood}(\theta_{curr}) \times \text{Prior}(\theta_{curr})}$$
3. **The "Coin Flip"**: If the new point is better, it moves. If it's worse, it may still move (stochastically) to ensure it explores the full "mountain" rather than just the peak.

**Technical Asset**: [`Manual_MH_Sampler.R`](./Manual_MH_Sampler.R)

---

## 3. The "Railgun": Stan & Hamiltonian Monte Carlo (HMC)

We then deploy **Stan**, which uses **HMC/NUTS** algorithms. Unlike the "blind walking" of MH, HMC uses **Gradients (calculus)** to slide down the probability surface like a ball on a curved track.

**Technical Asset**: [`Mosquito_Model.stan`](./mosquito.stan)

```stan
// A minimal Stan model for 10-patient recovery
data {
  int<lower=0> N; // 10
  int<lower=0> y; // 7
}
parameters {
  real<lower=0, upper=1> theta;
}
model {
  theta ~ beta(1, 1);       // Prior
  y ~ binomial(N, theta);   // Likelihood
}
```

---

## 4. Sensitivity Audit: The Impact of Informative Priors

A core task of an HEOR Modeller is to test the robustness of the evidence against different prior assumptions. We performed an experiment: **What if our prior knowledge matches the trial data?**

* **Scenario**: Change Prior from $\text{Beta}(1,1)$ to $\text{Beta}(7,3)$ (an anchor at 0.7).
* **Result**: The posterior mean shifted from **0.667** to **0.700**.
* **Visual Change**: The bell curve became significantly narrower (**Higher Certainty**).

| Method | Mean ($\theta$) with Weak Prior | Mean ($\theta$) with Strong Prior |
| :--- | :--- | :--- |
| **Exact Math** | 0.667 | 0.700 |
| **Manual MH** | 0.668 | 0.698 |
| **Stan (HMC)** | 0.667 | 0.699 |

> [!NOTE]
> **Senior Consultant Reflection**
> In HTA submissions for **Rare Diseases**, we often use **Informative Priors** derived from registries or expert elicitation. This project demonstrates that while strong priors can "shield" a model from noise, they also increase the "weight of the past." As an auditor, I always check the **Prior-Data Conflict** to ensure the drug's value is truly coming from the trial.

---

## 5. Summary of Findings: Why MCMC Matters

This exercise confirms that **MCMC is a search for balance**.

1. **Likelihood** tells us what the data says.
2. **Prior** tells us what clinical common sense says.
3. **MCMC** (especially via Stan) is the engine that finds the equilibrium point.

By mastering these simple mechanics, we ensure that our complex **ML-NMR** and **NMA** reconstructions are built on a foundation of statistical integrity rather than algorithmic black-boxes.

---
**Technical Case Study by**: Xiaoge Zhang, PhD (York)  
**Tooling**: R & Stan  
**Portfolio Hub**: [xgzhang.com](http://xgzhang.com)
