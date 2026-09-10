# OR Scheduling Reliability & Cost Exposure

## Why I Built This

Operating room schedules are built around an estimate of how long each procedure will take. This project asks a narrower question than "are we good at scheduling": how much does *actual* OR time differ from what a procedure's own history predicts, how often, and what does that add up to across a year?

The benchmark throughout is each procedure's **historical median duration**, computed from its own past cases — not a scheduled or booked time slot. I didn't have access to what was actually booked, so this measures *predictability against history*, not schedule adherence.

## Data and Scope

The data comes from **MOVER** (Medical Informatics Operating Room Vitals and Events Repository), a public perioperative dataset from UC Irvine Medical Center — not the UCI Machine Learning Repository, which is simply where it's hosted. The full repository covers adult surgeries from 2015–2022, roughly 58,800 patients and 83,000 surgeries ([Samad et al., *JAMIA Open*, 2023](https://academic.oup.com/jamiaopen/article/6/4/ooad084/7320357); dataset via [UCI ML Repository](https://doi.org/10.24432/C5VS5G)). Access requires a signed data use agreement; the data is HIPAA de-identified under IRB approval, including shifted dates (*Limitations*).

My analytical cohort is a curated subset staged in a Fabric warehouse: **48,118 cases across 418 procedures**, spanning **November 2017 to August 2023** in the shifted date range — about 5.75 years, narrower than the full repository window simply because my extract starts later in it. I restricted the cohort to procedures with at least 30 cases — an inclusion threshold to exclude procedures too thin to compute a benchmark from, not a guarantee of statistical reliability.

## How the Dashboard Works

A headline row establishes scale: cases and procedures analyzed, average/median time deviation, and the annual cost exposure implied. A timing-outcome chart splits cases into four buckets — early 30+ min, within 30 min, late 30–60 min, late 60+ min. The centerpiece is a scatter plot placing each of the 418 procedures by annualized deviation (a cost/volume proxy) against its share of cases outside a 30-minute window (a predictability proxy), backed by a sortable, searchable table ranking procedures the same way.

Two slicers scope the page: one filters by a plain-language review category (for example, "high exposure and unreliable" vs. "low exposure and reliable"), the other searches for a specific procedure by name. Beyond that, selecting a row in the table, a bubble in the scatter, or a bar in the timing chart filters the other visuals to match, so a viewer can move from the overall picture to one procedure's detail without losing context. The scatter's two reference lines — the cohort's median deviation and median miss-rate, each computed once across all 418 procedures — stay fixed regardless of selection, so they work as a stable comparison point rather than one that moves with whatever is selected.

## What the Results Show

The mean absolute error across all cases is 54.1 minutes, well above the median of 33.0 minutes. A mean this far above the median indicates a right-skewed distribution, pulled up by cases with larger misses, since the mean is more sensitive to large deviations — I haven't examined the distribution's shape, so I can't say how many cases or how extreme. Roughly 47% of cases land within 30 minutes of their benchmark.

The annualized deviation translates to a gross exposure of roughly $15.8M at $35/minute of OR time, or $27.1M at $60/minute — a scenario estimate, not recoverable savings or proof it's avoidable. Also worth separating: a procedure can carry a lot of deviation simply by being performed often, independent of whether it's unpredictable per case. High exposure alone doesn't establish poor reliability, which is why the scatter keeps the two axes separate rather than combining them into one score.

## Challenges and Design Decisions

I was most careful about **weighting**. Averaging each procedure's own percentage into a portfolio-wide figure would treat a 900-case procedure the same as a 30-case one, overweighting low-volume procedures. The headline statistics above come directly from the 48,118-row case table, not averaged up from per-procedure numbers — the same logic behind keeping reliability and exposure as two separate axes rather than one score.

The two grains of data here — individual cases and per-procedure rollups — also made consistent cross-filtering harder to get right than expected. Separately, while preparing this document I confirmed, via a live query against the model, that the timing-outcome chart's own on-screen percentages sum to about 100.7% rather than 100%, caused by a bidirectional relationship that narrows the chart's comparison base slightly differently per category. The underlying case counts are correct — they sum to exactly 48,118 — and the percentages quoted above use those counts, not the chart's own display, which still shows the affected figures as a known, unresolved issue.

## Limitations

The benchmark is retrospective, drawn from the same window being analyzed, so it describes what typically happened, not an independent target. The 5.75-year annualization basis is one fixed assumption applied uniformly, not case-by-case. The cohort excludes any procedure with fewer than 30 cases. MOVER's dates are shifted by a random, patient-specific offset, consistent within one patient's records but not aligned across patients — so this data can't support calendar-time analysis: seasonality, day-of-week effects, and year-over-year trends aren't recoverable. Nothing here demonstrates deviation was avoidable, that costs are recoverable, or what causes a procedure to run long or short — this describes *where* the variation is, not *why*.

## Where This Could Go Next

Reasonable next steps, not assumptions I'm making now: testing whether attributes like patient acuity, anesthesia type, or inpatient/outpatient status correlate with the misses, as hypotheses rather than confirmed drivers; splitting the extract into an earlier and later portion to check whether benchmarks from one hold up against the other — compatible with the date-shifting, since it relies only on within-patient timing, not calendar alignment; and, if ever available, comparing against actual booked schedule times, moving from "how predictable is this procedure" to "how accurate was this schedule."

---

*Built with Power BI Desktop against a Fabric-hosted warehouse; the model, report, and this document are in this repository.*
