# 9amHealth Case Study — Deck Outline

**Deliverable:** 5–7 slides — analytical approach · key findings · visuals · strategic recommendations.
**Panel:** product · clinical · business. **Palette:** Cream `#FFFCF3` bg · Charcoal `#212121` text · Sunrise `#80AEFF` accent.
**Thesis (say it early, prove it in the middle):** *Weight loss is driven primarily by medication (GLP-1) + baseline weight + time in program. Engagement and education add a **real but smaller** independent effect — ~half of engagement's apparent benefit is confounding, the rest is genuine and, crucially, **modifiable**.*

Story arc: **Question → Approach → What happened (weight) → What happened (engagement) → Why (drivers, confound-adjusted) → So what (recommendations)** + appendix.

| # | Slide | Brief item | Visual | Status |
|---|---|---|---|---|
| 1 | Question + headline answer | Key Question | none / hero stat | build |
| 2 | Approach & data | Approach, Resp. 1–2 | CONSORT waterfall | ✅ built |
| 3 | Weight-change patterns | Objective 1 | responder bar by drug | ✅ coded |
| 4 | Engagement patterns | Objective 2 | engagement boxplot + hist | ✅ coded |
| 5 | Drivers (confound-adjusted) | Objective 3 | naive-vs-adjusted scatter | ✅ built |
| 6 | Recommendations | Objective 4, Resp. 5 | none / 3 stakeholder cols | build |
| 7 | Appendix: methods & limits | (backup) | — | write |

---

## Slide 1 — The question, answered
- **Purpose:** exec-first. Ask the question, give the one-line answer, don't bury it.
- **Content:** "What drives clinical weight improvement among 9amHealth members?" → **Mostly medication + starting weight + time in program; engagement & education add a real, smaller, modifiable boost.** Cohort n=825, Feb–Sep 2025.
- **Takeaway:** *The biggest lever is clinical — but the levers 9am controls (engagement, education) genuinely move the needle too.*

## Slide 2 — Approach & data
- **Purpose:** show rigor fast (Analytical approach; Responsibilities 1–2).
- **Content:**
  - Sub-questions/hypotheses (H1 regression-to-mean · H2 drug drives loss · H3–H5 engagement/modules/demographics add on top · H6 engagement×drug).
  - 4 datasets → member-level join → **CONSORT lock 865 → 827 (has weight) → 825 (active/finished)**.
  - Outcome = **% weight change**, success = **≥5% loss** (clinical bar). Method = baseline-adjusted regression + **LASSO** (prediction-parsimony screen) + **incremental HC3 inference** (which candidates are *really* independent) + robust (HC3) SE.
  - Assumptions callout (no age column; ≥5% threshold; cohort exclusions).
- **Visual (two, they pair):** (a) **CONSORT waterfall** `consort_waterfall.png` (865→827→825) — keep; a PI expects an attrition diagram. (b) **Table 1** `figures/demo-table.ods` — cohort description by member type. *This table pulls double duty:* it also **sets up the imbalance** the analysis has to handle — arm sizes 63/7/334/361/60 (GLP-1-Diab n=7), and baseline weight differing by arm (214–267 lb). Annotate those two facts; they foreshadow the collapse-to-`glp.all` decision and the power slide.
  - *Layout:* if both crowd the slide, keep the waterfall here and move Table 1 to its own slide (2b) or lead the appendix with it — don't shrink it to unreadable.
- **Takeaway:** *Locked population + clinical outcome + two selection lenses (prediction & inference) = defensible, not cherry-picked — and the cohort table already flags the imbalance we control for.*

## Slide 3 — Weight-change patterns (Objective 1)
- **Content:** overall median **1.3%** loss, **31% hit ≥5%** (254/825). Responder rate by drug class: **Coaching 5.3% · Generic 30.2% · GLP-1 (All) 61.9%**. Coaching-only median = 0.0%.
- **Visual (REPLACE the plain % bar):** **%-change distribution by drug class** — horizontal box + jittered points per arm (Coaching / Generic / GLP-1 All), vertical line at the **≥5% clinical threshold**, responder-% annotated on each arm. *Why:* one picture carries the whole story the bar hides — the **mixture** (Coaching centered ~0 with some members *gaining*; GLP-1 shifted right, wide spread), the **clinical bar**, and the **gradient**. A single median bar shows none of that.
  - *Alt if a bar is preferred:* **stacked response-category bar** (gained / 0–5% / ≥5%) by drug — shows the full response spectrum, not just the top slice.
  - *Precision note:* keep GLP-1-Diabetes folded into GLP-1(All); do **not** plot the n=7 arm as its own clean bar (85.7% on 7 people is noise — that's the power slide's job).
  - Data: `cohort$pct`, `cohort$glp.all`, `resp5`. Buildable in `deck_charts2.R` style.
- **Takeaway:** *Meaningful weight loss is concentrated: most of it sits with GLP-1 members; coaching-only is centered at zero.*

## Slide 4 — Engagement patterns (Objective 2)
- **Content:** 825/825 have engagement data. Median `volume_rep` **7 → 50 → 103** (Coaching→Generic→GLP-1); `mod.mean` 0.31 → 0.90 → 2.70. Engagement rises in the **same order** as responder rate.
- **Visual (DROP the volume histogram; keep + upgrade the by-drug view):** **co-movement chart** — median `volume_rep` by drug (bars) with **responder-% overlaid as points/line on a second axis**, arms in the same weak→strong order. *Why:* the histogram shows *shape*, not *story*; this shows engagement and response rising **together**, which is the exact question slide 5 answers ("is that real or just the drug?"). One chart, one bridge.
  - *Alt:* member-level **scatter of engagement vs %-change, colored by drug** — but that pre-empts slide 5; prefer the co-movement bars here.
  - Data: `tapply(volume_rep, glp.all, median)` + responder-% by arm. Adapts `deck_charts2.R` panel B.
- **Takeaway:** *Engagement isn't uniform — it tracks the medicated population, and it rises in lockstep with the responder rate. (Real lever, or just a marker of the medicated? → slide 5.)*

## Slide 5 — Drivers, confound-adjusted (Objective 3) — the centerpiece
- **Content:**
  - **Dominant drivers**, reported model `pct ~ first + glp.all + fl.cnt + volume_rep` (HC3, n=765, R²=0.35): GLP-1 **+3.0 pts** vs Coaching (p<0.001) and baseline **+0.011/lb** (p<0.001) are the dominant terms; Generic (+0.7) and exposure `fl.cnt` go **n.s.** once engagement enters. (Core-only, before `volume_rep`: GLP-1 +5.5, R²=0.33 — the drop to +3.0 is engagement absorbing part of the drug signal, same confound story as the scatter.)
  - **Engagement = a real but secondary driver.** `volume_rep` naive **+0.068/event → adjusted +0.0375/event, HC3 p<1e-5** (≈ **+3.3 pts** across its IQR). ~45% of the raw effect is confounding (drug + exposure + baseline); ~55% is genuine.
  - **Education also adds:** `mod.mean` +0.60/unit (p=0.009, ≈+1.4 pts across range), `breadth` p=0.011, `mod.core` p=0.035. Each small in R² (≤+2.5%) but significant and **modifiable**. `sex`, `tenure` n.s.
  - **Why LASSO looked like "nothing":** `lambda.1se` optimizes *predictive parsimony*, not inference — it drops small-but-precise coefficients. HC3 inference recovers them. Multiplicity note (control error rates): under Bonferroni only `volume_rep` is unambiguous; modules/breadth are suggestive.
- **Visual (REPLACE the added-variable scatter — it's opaque to a mixed panel):** **coefficient / forest plot of the locked model** — each driver's effect **across a meaningful range** (IQR for continuous, level vs reference for factors) with **95% CI**, ordered by magnitude: GLP-1 and baseline weight clearly off zero; `volume_rep` positive; Generic, exposure, `sex` straddling zero. *Why:* this is the standard way to hand a multivariable model to non-statisticians — direction, magnitude, and uncertainty in one read, and it *shows* the significant-vs-null split instead of asserting it.
  - **Confound point as a small inset, not the AV plot:** **two bars — naive +0.068 vs adjusted +0.038** for `volume_rep` (≈55% survives). Same message as the residual scatter, readable in one second.
  - Data: `coeftest(m.pct.final, vcovHC(...,"HC3"))` → estimate ± 1.96·SE, scaled by IQR; naive slope from `lm(pct ~ volume_rep)`.
- **Takeaway:** *Medication + baseline dominate; engagement is a genuine, modifiable lever (~half its raw signal is real) — the part of the outcome 9am actually controls. (Note: on the continuous %-scale, GLP-1's adjusted +3.0 is comparable to engagement's IQR swing; the drug's **dominance is clearest on the responder rate**, 62% vs 5%.)*

## Slide 6 — Recommendations (Objective 4, Responsibility 5)
- **Purpose:** per-stakeholder, actionable.
- **Content (3 columns):**
  - **Clinical:** GLP-1 is the dominant lever; set realistic expectations for coaching-only (~5% respond). Prioritize medication access/titration.
  - **Product:** engagement (logging volume, breadth) and module completion are **real, modifiable secondary levers** — invest in the highest-yield ones. **But** the effect is observational and may partly reflect drug adherence; **run a causal test (RCT/matched)** to size the true effect before over-investing.
  - **Business:** segment on drug class for responder economics; forecast by medication mix, with engagement/education as an incremental, controllable upside.
- **Takeaway:** *Fund the clinical lever first; fund engagement/education as the modifiable upside — and measure it causally.*

## Slide 7 — Appendix: methods, limitations & power (backup)
- Cohort exclusions, no age column, ≥5% threshold rationale, HC3 SE, LASSO (prediction) vs HC3 (inference) — why they disagree, multiplicity/Bonferroni note, **causal caveat** (observational — associations, engagement may proxy adherence), 2-timepoint limit, RF confirmatory (optional).
- **Endpoint limitation (new):** raw body weight / %-change can't separate fat loss from lean-mass change → coaching's ~0 may be **recomposition**, not a null; recommend capturing waist/BIA. Forward rec, not a reanalysis (no height in the data).
- **Power / precision (new):** the class comparison is answerable only for the large arms — **GLP-1-WL vs Coaching resolves 2.7 lb** (powered); Generic (6.2 lb) and GLP-1-Diab (**20.2 lb, n=7**) are not. To resolve a 5-lb class gap prospectively: **~98/arm** (80%). Do **not** report post-hoc/observed power (Hoenig & Heisey 2001).
- **Visual:** `power_precision.png` — per-arm mean±95% CI forest (the n=7 CI is the point) + n/arm-vs-gap curve. ✅ built (`power.R`).

---

### Visuals — plan & rationale

**Principle:** one dominant visual per slide. It must advance the argument, read in ~5s for product/business, and hold up for the PI. **Table** for exact values (cohort, model coefficients); **chart** for pattern / distribution / uncertainty. Prefer dropping a chart over keeping a decorative one.

| Slide | Current | Verdict | Recommended | Why |
|---|---|---|---|---|
| 1 | hero stat | keep | **no chart** — 3 hero numbers (31% ≥5%; 62% vs 5% GLP-1 vs coaching) | exec-first; a chart dilutes one number |
| 2 | CONSORT | keep + pair | **CONSORT waterfall + Table 1** (`demo-table.ods`) | rigor + the imbalance setup |
| 3 | responder % bar | **replace** | **%-change distribution by drug** (box+jitter, ≥5% line) | shows mixture + threshold + spread, not one median |
| 4 | box + histogram | **drop hist** | **co-movement: median engagement + responder-% by drug** | bridges to the confound question |
| 5 | AV scatter | **replace** | **forest/coefficient plot of locked model** (+ tiny naive-vs-adjusted 2-bar inset) | model direction/magnitude/uncertainty a non-statistician can read |
| 6 | 3 columns | keep | optional **sample-size mini** in the business column | turns "confirm causally" into a number (~100/arm) |
| 7 | text | keep | **`power_precision.png`** (arm-CI forest + n/arm curve) | answers the PI's power question; parks the n=7 caveat |

**Charts to build (all from existing pipeline objects):** — all ✅ built in `deck_charts3.R` + `power.R`
1. S3 `pct_distribution_by_drug.png` — ✅ box+jitter by `glp.all`, ≥5% line, responder-% annotated.
2. S4 `engage_response_comove.png` — ✅ median `volume_rep` bars + responder-% red line (co-move).
3. S5 `driver_forest.png` — ✅ locked-model effect×IQR ± HC3 95% CI + naive-vs-adjusted inset. **Note:** the forest shows engagement IQR (+3.4) ≈ GLP-1 (+3.0) on the %-scale → confirms the S5 wording call (lead responder-rate dominance, not the coefficient).
4. S7 `power_precision.png` — ✅ (`power.R`).

**Charts to retire:** `confound_scatter.png` (S5, opaque), the volume histogram half of `engagement_by_drug.png` (S4). Keep `consort_waterfall.png`, `responder_by_drug.png` as fallbacks.

### Open decisions for Luis
- 7 slides as-is, or split Table 1 to a 2b so slide 2 isn't crowded.
- S5 narrative: with GLP-1 adjusted **+3.0** ≈ engagement's IQR **+3.3**, "engagement is *smaller*" no longer holds on the continuous scale. Lead drug **dominance on the responder rate** (62% vs 5%) and frame engagement as **comparable + modifiable** on the %-scale — decide the exact wording.
- How hard to lean on the engagement lever given it's observational (may proxy adherence) — recommend: real + modifiable, paired with the "confirm causally / power it at ~100/arm" ask.
