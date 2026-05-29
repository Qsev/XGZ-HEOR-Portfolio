---
name: KM Pseudo-IPD Reconstruction via Image Analytics (HTA Audit Grade)
description: 专门针对 HTA/HEOR 场景，将 PDF 内的生存曲线（K-M 曲线）通过 CV + Guyot 2012 算法高度自动化记录并逆向为原始个体层面数据 (IPD) 的完整审计工作流。
---

# 🕵️‍♂️ KM Pseudo-IPD Reconstruction via Image Analytics (HTA Audit Grade)

## 📖 背景与目的 (Background & Purpose)

在药物经济学 (HEOR) 与技术评估 (HTA) 的审计过程中，由于缺乏原始个体层面数据 (IPD)，必须通过 Kaplan-Meier (K-M) 曲线位图进行高精度逆向。

**本 Skill 的使命：**
利用计算机视觉 (CV) 技术从高分辨率位图中精准提取生存坐标，结合官方公布的 **Number at Risk (NAR)** 矩阵，运用 **Guyot 算法 (2012)** 还原出符合审计标准的 Pseudo-IPD。

**最高准则：**
- **严禁**使用平滑曲线拟合；
- **严禁**为了对齐 Median OS 而篡改事件数；
- **必须**严格遵循 Guyot (2012) 算法与在险人数 (NAR) 约束。

---

## 🛡️ 避坑指南 (The Pitfalls & Battle Lessons)

| 陷阱 | 应对战场经验 (HTA Hardened) |
| :--- | :--- |
| **插值斜线陷阱** | **绝对禁止**在没有点位的地方进行跨度巨大的线性插值。采取“水平维持”逻辑补坑。 |
| **强制单调性的毁灭** | 如果首点像素带噪声导致 Survival 偏低，强制单调会将整条线“压死”在谷底。必须先用中值过滤杀掉离群噪点，再做单调检查。 |
| **Y轴抗锯齿污染** | 扫描时必须跳过 $X \approx 0$ 的像素带，否则 Y 轴的黑色像素会被识别为坐标点，瞬间拉低 $Time=0$ 的生存率。 |
| **手感 vs 像素感** | WebPlotDigitizer 手动取点极其容易在平滑区误差达到 5个月以上且 HR 反向。**坚决信任精密 HSV 像素扫描。** |
| **红蓝重合断裂** | 在重合区，红色像素常被蓝色覆盖。算法必须具备“记忆填充”功能。 |
| **抢跑与门控失效** | **强硬门控约束**：Phase 3 图像数字化完成后，只允许输出 Validation.png 叠加图让用户进行视觉核对。在用户确认对齐前，**绝对禁止**生成最终 CSV 或执行 Phase 4 IPD 重建。 |
| **虚线检测斜线失真** | **虚线提取黄金法则**：对于有其他实线交叉干扰的虚线 K-M 曲线，优先使用 Strict HSV mask + Column-sweep + last_y inheritance（严格 HSV 掩膜 + 逐列扫描 + 上值继承），避免使用极易被陡峭斜率（因像素高度超标而被尺寸过滤）干扰的连通域质心滤波法。 |
| **置信区间 (CI) 阴影污染** | **高饱和度剥离法 + 人工锚点门控**：当实线与 CI 阴影色相 (Hue) 接近时，利用实线的高饱和度 (Saturation > 150) 特征进行隔离掩膜。同时必须要求引入人工绘制的极端异色锚点（如纯黑/品红）来动态构建 Y 轴垂直搜索边界，彻底阻断越界噪点。 |

---

## 🛠️ Phase 0: 高精度物理采样与人工锚定 (High-Res Sampling & Manual Anchoring)

- **物理裁图 (Mandatory Crop)**: 用户**必须**提供纯净的曲线区域截图，排除 NAR 表格、图例和标题。
- **图像格式**: 必须是 600 DPI 以上的 PNG。
- **强制人工锚点标定 (Mandatory Anchor Annotation)**: 针对有置信区间 (CI) 阴影遮挡或存在起点抗锯齿污染的复杂曲线，用户**必须**在原图上使用与全图色彩完全冲突的特殊纯色（如 **纯黑 `#000000`** 或 **品红 `#FF00FF`**）绘制实心圆点（直径约3-5像素），精确标定：
  1. 曲线的绝对起点 (Time=0)
  2. 曲线的绝对终点
  3. 曲线中部的核心阶跃式骤降拐角
  （注：这些异色锚点将被算法用于构建动态 Y 轴边界围栏，强制屏蔽 CI 阴影干扰并锁定物理原点。）

---

## 👁️ Phase 1: VLM 临床元数据与 NAR 提取 (Meta-Data Extraction)

- **Action**: 识别 NAR 矩阵、中位 OS 真值、HR 真值。

---

## 📐 Phase 2: 精准 HSV 诊断 (HSV Diagnostic)

- **Step 1**: 生成 3-panel 诊断图（原图、Mask_A、Mask_B）。
- **Step 2**: 检查白线是否连续。若断裂，考虑红蓝重合逻辑。

---

## 🕵️‍♂️ Phase 3: 像素级收割 (Pixel-to-Pixel Harvest)

- **Action**: 使用扫列 (Column-sweep) 取中值。
- **Gap-filling**: 若某列缺失像素，继承/借用并行曲线或前序点。

---

## ➗ Phase 4: Guyot 重构 (Guyot Reconstruction)

- **Action**: 运行 R 脚本，将坐标与 NAR 矩阵合并。
- **目标**: 还原出符合 100% NAR 约束的 `Pseudo_IPD.csv`。

---

## 🏆 Phase 5: 统计审计 (Statistical Validation)

1. **Median OS 对齐**: 误差应 < 10%。
2. **HR 对齐**: 计算所得 HR 必须与原图方向一致且接近。

---

# TA1092 Addendum for `km_pseudo_ipd_reconstruction` Skill

This addendum records the detailed TA1092 / KEYNOTE-868 workflow developed during the dMMR and pMMR PFS digitisation and pseudo-IPD reconstruction. It is written to be appended to:

`/Users/xiaogezhang/AntigravityLocal/CareerTransferZXG/.agent/skills/km_pseudo_ipd_reconstruction/SKILL.md`

The key lesson is that **visual digitisation fidelity** and **event-structure fidelity** are not the same thing. A raw digitised Kaplan-Meier curve can visually overlay the published figure very well, while a Guyot-style pseudo-IPD reconstructed from it can still deviate from the published curve if the event-drop and censoring structure is not handled carefully.

## Core Principles

1. **Separate image digitisation from pseudo-IPD reconstruction**
   - Image digitisation answers: does the extracted curve sit on top of the published KM curve?
   - Pseudo-IPD reconstruction answers: can we generate individual event/censor records that reproduce the curve, number at risk, reported event totals, medians and HR?
   - These are related but not identical problems.

2. **Do not enter Guyot reconstruction before user visual confirmation**
   - Generate validation figures first.
   - Let the user inspect overlays.
   - Revise the extracted curve if the user marks missed segments.
   - Only after explicit confirmation should pseudo-IPD reconstruction begin.

3. **Number at risk (NAR) mainly becomes useful at the reconstruction stage**
   - NAR does not directly help HSV image extraction.
   - NAR is essential when allocating events and censoring in the pseudo-IPD.
   - NAR should also be used as a hard validation check after reconstruction.

4. **Raw digitised drops are not automatically true event drops**
   - Anti-aliasing, censor tick marks, thick curves, colour overlap and manual annotation can create micro-drops.
   - These micro-drops may be visually acceptable but can inflate event counts if treated as true events.

5. **Always preserve auditability**
   - Keep raw points, step segments, revised segments, pseudo-IPD, event allocation, censor allocation and validation figures.
   - If event-drop cleaning is used, output a table showing which raw drops were kept, merged or removed.

## Phase 0: User Image Preparation

The user should provide a clean crop of the KM plot:

- The plot area should include x/y axes and the curve.
- It may include tick labels if they help calibration.
- It should exclude the NAR table, title, caption and unnecessary surrounding page content where possible.
- The original curve colours should be preserved.

For difficult plots, ask the user to annotate the image using extreme, non-native colours:

- Use different colours for different arms if needed.
- Mark start, end and key turning/drop points.
- If the validation overlay is imperfect, the user may mark the validation PNG directly. This worked well in TA1092 when the user marked missed pembro/placebo segments using yellow or magenta.

Important instruction for the user:

> You do not need to redraw the full curve. Mark only the sections where the extracted overlay should cover the published curve better.

## Phase 1: Axis Calibration

Record calibration explicitly in a JSON file. Example output:

```json
{
  "axis_calibration": {
    "x_ticks_pixels": [103, 334, 562, 791, 1021, 1251, 1480],
    "x_ticks_months": [0, 6, 12, 18, 24, 30, 36],
    "x_months_per_pixel": 0.02615,
    "x_intercept_months": -2.7048,
    "y_surv1_pixel": 25,
    "y_surv0_pixel": 890
  }
}
```

Recommended file:

```text
*_extraction_summary.json
```

Calibration must allow pixel coordinates to be transformed into:

```text
time_months
survival
```

## Phase 2: HSV Digitisation

For each arm:

1. Build HSV masks for the original curve colour.
2. If the user added manual marks, detect the user-mark colour separately.
3. Use masks to guide or constrain extraction.
4. Produce diagnostic figures before generating final data.

Required diagnostic outputs:

```text
*_HSV_diagnostic.png
*_HSV_summary.json
*_full_overlay.png
*_curve_points_validation.png
```

The `curve_points_validation.png` should show extracted points on the original plot, so the user can visually confirm whether the pixel extraction followed the published KM curve.

## Phase 3: Column-Sweep Curve Harvest

Use a column-sweep approach:

1. Iterate over x columns.
2. Locate curve-colour pixels within that column.
3. Use median or trimmed median y position to reduce anti-aliasing noise.
4. Ignore axis pixels and text contamination.
5. Use local inheritance only for short gaps, and make gaps visible in validation.

Raw point CSV columns:

```text
arm,x_pixel,y_pixel,time_months,survival
```

Recommended naming:

```text
{subgroup}_{endpoint}_{arm}_raw_curve_points.csv
```

## Phase 4: Step Compression

Raw HSV points are too granular for Guyot-style reconstruction. Convert them into KM step segments.

Output:

```text
*_step_segments.csv
*_step_vertices.csv
*_step_coordinate_validation.png
```

Step segment columns:

```text
arm,start_time_months,end_time_months,survival
```

Step vertex columns:

```text
arm,time_months,survival
```

The validation figure should overlay the compressed step curve on the original figure. This is the second major user confirmation point.

## Phase 5: Human-in-the-Loop Step Revision

TA1092 showed that this is essential. The user may notice small but important gaps between the compressed step overlay and the published curve.

Recommended revision workflow:

1. Generate `*_step_coordinate_validation.png`.
2. Ask user to mark missed or over-covered sections directly on the PNG.
3. Regenerate an unmarked validation image from the current data.
4. Compare marked vs unmarked images to isolate annotation regions.
5. Adjust only the affected arm/segments.
6. Preserve already accepted arms and previous versions.

Revision outputs:

```text
*_step_segments_revised.csv
*_step_vertices_revised.csv
*_step_coordinate_validation_revised.png
```

If there are multiple revision rounds, use suffixes such as:

```text
*_revised2.png
*_revision2_summary.json
```

Important rule:

> Do not rerun or overwrite accepted curves unnecessarily. If pembro is accepted and only placebo is marked, revise placebo only.

## Phase 6: NAR and Published Constraint File

Before pseudo-IPD reconstruction, create a NAR JSON file for every subgroup and endpoint.

Example from dMMR PFS:

```json
{
  "endpoint": "PFS",
  "subgroup": "dMMR",
  "time_months": [0, 6, 12, 18, 24, 30, 36],
  "arms": {
    "pembro_chemo": {
      "label": "Paclitaxel-carboplatin + pembrolizumab",
      "n": 112,
      "events_reported": 26,
      "median_reported_months": null,
      "nar": [112, 80, 44, 22, 9, 8, 2]
    },
    "placebo_chemo": {
      "label": "Paclitaxel-carboplatin + placebo",
      "n": 113,
      "events_reported": 59,
      "median_reported_months": 7.6,
      "nar": [113, 62, 24, 8, 4, 2, 0]
    }
  }
}
```

Example from pMMR PFS:

```json
{
  "source": "KEYNOTE-868 / NRG-GY018 NEJM Figure 2B pMMR PFS",
  "time_months": [0, 6, 12, 18, 24, 30, 36],
  "arms": {
    "pembro_chemo": {
      "label": "Paclitaxel-carboplatin + pembrolizumab",
      "nar": [290, 150, 45, 20, 7, 3, 0],
      "events_reported": 89,
      "median_months_reported": 13.1,
      "median_ci_reported": [10.5, 18.8]
    },
    "placebo_chemo": {
      "label": "Paclitaxel-carboplatin + placebo",
      "nar": [292, 129, 33, 10, 2, 1, 0],
      "events_reported": 133,
      "median_months_reported": 8.7,
      "median_ci_reported": [8.4, 10.7]
    }
  },
  "target_hr_pembro_vs_placebo": 0.54,
  "target_hr_ci": [0.41, 0.71]
}
```

NAR validation after reconstruction should have columns:

```text
time_months,published_nar,reconstructed_nar,difference
```

The target is usually `difference = 0` at every published NAR time.

## Phase 7: Basic Guyot-Style Reconstruction

Minimum input:

- Accepted or revised step segments.
- NAR array.
- Reported event total.
- Published median and HR for validation.

Basic reconstruction logic:

1. Identify downward drops from step segments.
2. Estimate raw event weights from the survival ratio:

```text
raw_events approximately equals number_at_risk * (1 - S_after / S_before)
```

3. Round event weights.
4. Adjust total events to match the reported event total.
5. Allocate censoring within each NAR interval so that the next NAR count is matched.
6. Censor anyone remaining at the final NAR point.

Required outputs:

```text
{arm}_{subgroup}_{endpoint}_pseudo_ipd.csv
{arm}_event_allocation.csv
{arm}_censor_allocation.csv
{subgroup}_{endpoint}_pseudo_ipd_combined.csv
{subgroup}_{endpoint}_guyot_style_validation.json
```

Pseudo-IPD columns:

```text
id,arm,time,status
```

where:

- `status = 1` means event
- `status = 0` means censored

## Phase 8: Validation of Pseudo-IPD

Run survival validation in R, preferably with `survival`.

Check:

- N per arm.
- Events per arm.
- NAR at all published time points.
- Median survival/PFS.
- Cox HR and 95% CI.

Recommended output:

```text
*_statistical_validation_R.csv
*_reconstructed_nar_from_R.csv
```

Example TA1092 pMMR PFS event-constrained validation:

```text
NAR: exact at all published time points
pembro events: 89 / 89
placebo events: 133 / 133
HR: 0.554 vs target 0.54
95% CI: 0.423-0.725 vs target 0.41-0.71
Median PFS: pembro 13.01 vs target 13.1; placebo 8.41 vs target 8.7
```

## Phase 9: Reconstructed KM Overlay

Do not only plot a clean R KM chart. The most useful validation figure overlays the reconstructed KM on the original published plot.

Recommended style:

- Use the original published KM image as the background.
- Overlay reconstructed pembro KM in magenta.
- Overlay reconstructed placebo KM in cyan.

Recommended naming:

```text
*_reconstructed_KM_validation.png
*_reconstructed_KM_validation_trialN.png
*_reconstructed_KM_validation_km_focused.png
```

This figure is different from:

- `*_curve_points_validation.png`, which validates HSV raw points.
- `*_step_coordinate_validation.png`, which validates step compression.

The reconstructed KM overlay validates whether the pseudo-IPD reproduces the published curve.

## Phase 10: Diagnosing Mismatch Between Digitised KM and Reconstructed KM

If the reconstructed KM does not visually match the published KM, do not immediately assume Guyot is impossible. Diagnose the source.

### Test 1: KM-focused reconstruction

Purpose:

- Prioritise matching the digitised KM curve.
- Keep NAR fixed.
- Do not force reported event total initially.

Interpretation:

- If the curve matches but events exceed reported events, the raw digitised curve has too many effective event drops.
- In TA1092, KM-focused reconstruction matched the curve better but inflated events substantially.

### Test 2: Event-constrained reconstruction

Purpose:

- Force NAR and reported event totals.
- Check visual fit to the digitised curve.

Interpretation:

- If HR/events/NAR match but visual curve does not, event-drop cleaning or censor allocation needs improvement.

### Key TA1092 observation

For dMMR and pMMR PFS, the user-confirmed digitised curves visually covered the published curves. However, direct event-constrained reconstruction could still deviate. This showed that:

> The digitised curve was visually accurate, but its micro-drop structure was not yet analysis-ready for pseudo-IPD reconstruction.

## Phase 11: Event-Drop Cleaning / Analysis-Ready KM Curve

Event-drop cleaning is not redigitising the image. It is a post-digitisation step that converts the raw step curve into a more plausible event process.

The question changes from:

> Does this line sit on the published curve?

to:

> Should this small drop be treated as a true event drop, or is it likely a visual artefact / micro-step / merged part of a larger drop?

### Cleaning workflow

For each arm:

1. Read the accepted step segments.
2. Identify all downward drops.
3. For each drop, record:
   - drop ID
   - interval
   - time
   - raw target survival
   - raw drop size
4. Allocate integer events across drops under reported event total.
5. Allow some raw drops to receive zero events.
6. Mark zero-event drops as `removed_or_merged`.
7. Allocate censors before or between drops to match NAR and improve survival fit.
8. Minimise RMSE between reconstructed KM and raw digitised step curve.

Required output:

```text
*_event_drop_cleaning_trialN.csv
```

Recommended columns:

```text
drop_id,
interval,
time_months,
raw_target_survival,
raw_drop,
allocated_events,
censors_before_drop,
reconstructed_survival_after_drop,
survival_error,
cleaning_action
```

### TA1092 dMMR pembro trial2

This was the first successful small-step test.

Input:

- Curve: dMMR pembro PFS.
- Raw drops: 28.
- Reported events: 26.
- NAR: `[112, 80, 44, 22, 9, 8, 2]`.

Cleaning result:

- Cleaned event drops: 18.
- Events: 26 / 26.
- NAR: exact at all time points.
- RMSE vs raw digitised step: about 0.010.

Files generated:

```text
pembro_chemo_dMMR_PFS_event_drop_cleaning_trial2.csv
pembro_chemo_dMMR_PFS_pseudo_ipd_clean_trial2.csv
pembro_chemo_dMMR_PFS_clean_trial2_report.json
pembro_chemo_dMMR_PFS_clean_trial2_overlay.png
```

Interpretation:

> Event-drop cleaning can materially improve the reconstructed KM overlay while retaining reported event totals and NAR. This proves the optimisation is not wasted effort, but it must remain auditable.

## Phase 12: Human Discussion and Decision Points

After each reconstruction trial, show the user:

1. The reconstructed KM overlay.
2. NAR validation.
3. Event totals.
4. HR/median validation if both arms are reconstructed.
5. The event-drop cleaning table if cleaning was used.

Ask the user to decide whether the overlay is acceptable.

Possible decisions:

- Continue cleaning the same arm.
- Apply the same method to the comparator arm.
- Accept the current version as adequate for educational replication.
- Keep both versions in the QMD as evidence of public-data reconstruction limitations.

## Phase 13: HTA / EAG Interpretation

This workflow is directly relevant to NICE / EAG critique.

Public KM reconstruction can support:

- Educational survival modelling.
- Demonstration of survival extrapolation.
- Sensitivity analysis around public evidence.
- Transparent discussion of uncertainty.

Public KM reconstruction cannot fully replace:

- Company IPD.
- CSR/TLF-derived exact event/censor data.
- The exact survival dataset used in a company economic model.

In a QMD case study, explicitly state:

> The reconstructed pseudo-IPD is an approximate public-data reconstruction. It is suitable for demonstrating survival modelling and EAG-style critique of assumptions, but it is not the company’s original IPD or a definitive replication of the company model.

This is an important professional point in HEOR consulting: the goal is not to pretend public data can reproduce everything, but to show that you understand both the technical workflow and the evidentiary limitations.

## Minimal Audit Checklist

For each subgroup and endpoint, preserve:

```text
raw input image
HSV diagnostic PNG
HSV summary JSON
raw curve points CSV
curve points validation PNG
step segments CSV
step vertices CSV
step coordinate validation PNG
revised step segments, if used
revised step validation PNG, if used
NAR JSON
pseudo-IPD CSV
event allocation CSV
censor allocation CSV
NAR validation CSV/JSON
statistical validation CSV
reconstructed KM overlay PNG
event-drop cleaning table, if used
cleaning report JSON, if used
```

User confirmation log should answer:

1. Were raw curve points accepted?
2. Were step coordinate overlays accepted?
3. Was reconstructed KM overlay acceptable?
4. If not, was the issue visual digitisation, event-drop structure or censor allocation?
5. What assumptions were introduced to resolve the issue?

