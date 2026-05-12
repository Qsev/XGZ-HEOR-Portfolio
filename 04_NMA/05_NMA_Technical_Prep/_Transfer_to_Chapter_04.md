# Transfer Document: Handover from 03_Survival_NMA to 04_Component_NMA

This section summarizes the progress made on Survival NMA and outlines the plan for the next session focusing on Component NMA.

## 1. What We Have Accomplished

In file `03_Survival_NMA.qmd`, we successfully built a comprehensive portfolio piece for **Survival Network Meta-Analysis (Survival NMA)**:

- **Dual-Approach Implementation**: Covered both Contrast-Based NMA (using aggregate HRs) and Arm-Based Parametric NMA (using IPD).
- **Stan Likelihood Customization**: Wrote a manual likelihood accumulation block in Stan (`target +=`) for Weibull survival data, handling both event and censored contributions.
- **Dynamic Result Display**: Used inline R expressions (`as.matrix` and `median`) to safely extract posteriors and calculate real Hazard Ratios from logHRs in the text.
- **Pedagogical Annotations**: Applied Quarto code annotations and HTML audit points to explain complex concepts like the failure of Proportional Hazards and manual likelihood accumulation.

## 2. What We Will Do Next

### Next Big Step (Core of Chapter 04)

Implement **Component NMA (CNMA)**. This is used when treatments are combinations of distinct components (e.g., Drug A + Drug B vs Drug A). We will cover:

- How to model the additive or synergistic effects of components.
- Setting up the connectivity matrix for components.
- Writing the Stan model for CNMA.

---

## 3. Writing Standards & Requirements (Derived from QMD02)

To maintain the quality and consistency of the technical portfolio, the following standards must be enforced in the next conversation:

### Document Structure & Formatting

- **Language**: The entire document (including rendered text, table headers, and code comments) must be in **English only**. No Chinese should be visible in the rendered output or code comments.
- **Collapsible Outputs**: Wrap all R execution blocks and their generated outputs (like long Stan or JAGS summaries) in collapsible callout blocks:

  ```markdown
  ::: {.callout-note collapse="true"}
  ## Click to view [Description]
  ```{r}
  # Code here
  ```

  :::

  ```
- **Audit Points**: Use HTML comments with the prefix `<!-- Audit Point: ... -->` to provide deep pedagogical or strategic explanations for complex choices (e.g., why a specific prior was chosen, what a parameter physically represents).

### Content Depth

- **Intuitive Explanations**: Complex statistical metrics (like SUCRA or Inconsistency Factor $\Omega$) must be explained using physical/intuitive analogies (e.g., the race track example for SUCRA) in the text or Audit Points.
- **Anti-Hallucination**: Data, parameters, and references must be strictly aligned with source materials (like NICE DSU documents if referenced).
- **No Full Rewrites**: When modifying files, do not rewrite the whole file. Use targeted line edits to preserve cursor position and file history.

### Communication Style

- **Zero Flattery**: The AI must maintain an objective, technical, and zero-flattery tone. Do not use pleasantries like "You are right" or "Great observation."
- **Next Step Protocol**: Every AI response must conclude with the exact phrase: "**我们下一步如何进行？**" (What is our next step?) to keep the user in full control of the workflow.

---
**Prepared by**: Antigravity (Advanced Agentic Coding)
