
# Power BI Dashboard Notes
## OR Scheduling Reliability & Cost Exposure

### Purpose

This report helps scheduling stakeholders understand how OR durations vary and identify procedures worth reviewing. It brings together three questions:

- How often do cases differ from their historical duration benchmark?
- How much time variation accumulates across procedures?
- What gross annual cost exposure does that represent under different cost assumptions?

The benchmark is each procedure’s **historical median OR duration**, not its originally booked time. “Early” and “late” therefore describe differences from that benchmark.

### Reading the dashboard

**Headline cards** summarize the selected cohort: case count, procedure count, average and median absolute time differences, annualized variation, and gross exposure.

**The timing-outcome bar** shows the share of cases in four groups: more than 30 minutes below benchmark, within ±30 minutes, more than 30 through 60 minutes above, and more than 60 minutes above. The groups are mutually exclusive, so each case is counted once.

**The scatter chart—“Where should scheduling review begin?”—** separates accumulated exposure from per-case reliability:

- Further right means more annualized absolute time variation.
- Higher up means more cases outside ±30 minutes.
- Larger bubbles mean greater case volume.

**The procedure table** provides the detail needed to compare procedures, including case volume, historical benchmark, variation rate, and review context.

Use **Review focus** to narrow the view by review category and **Find a procedure** to search for a particular procedure. Selecting a chart element or table row connects the overview with the relevant detail.

### Understanding the review categories

The scatter uses cohort medians of approximately **613 minutes/year** and **58.4% outside ±30 minutes** to organize procedures into review groups.

| Review category | Interpretation |
|---|---|
| Prioritize review | Higher accumulated variation and a higher frequency of differences outside ±30 minutes |
| Review exposure | Higher accumulated variation, with a lower frequency of differences outside ±30 minutes |
| Review variability | Lower accumulated variation, but a higher frequency of differences outside ±30 minutes |
| Monitor | Lower on both measures relative to the cohort medians |

These references stay fixed during selection. They compare procedures within this cohort; they are not performance targets.

A high-volume procedure can accumulate substantial exposure without having unusually poor reliability. The two axes preserve that distinction.

### Full-cohort findings

The report covers **48,118 cases across 418 procedures**.

| Finding | Result |
|---|---:|
| Average absolute difference from benchmark | 54.1 minutes |
| Median absolute difference | 33.0 minutes |
| Cases within ±30 minutes | 46.7% |
| Cases outside ±30 minutes | 53.3% |
| Annualized absolute time variation | Approximately 452,335 minutes |
| Annual gross exposure at $35/minute | $15.8 million |
| Annual gross exposure at $60/minute | $27.1 million |

Annualized variation is total absolute deviation divided by an assumed **5.75-year period**. Exposure multiplies that annualized amount by the selected cost assumption.

The dollar figures are gross scenarios, not measured financial losses or recoverable savings.

### Important design decisions

**Case-level calculations:** Portfolio averages and percentages must reflect individual cases. Averaging procedure percentages would give a small procedure group the same influence as a large one.

**Separate reliability and exposure:** The scatter avoids combining these into a single score, allowing users to see why a procedure warrants attention.

**Consistent selection:** Cards and supporting visuals follow the selected procedures, while cohort reference values remain stable for comparison. The timing bar uses case counts with native percentage stacking.

### Interpretation limits

The report describes variation against a retrospective benchmark, not accuracy against an actual schedule. Procedures with fewer than 30 qualifying cases are excluded.

Annual estimates depend on the fixed observation-period and cost assumptions. Source dates are shifted for privacy, so they should not be treated as the original hospital calendar for trend analysis.

### Future improvements

- Add an interactive cost-per-minute parameter.
- Explore variation by relevant case characteristics, such as anesthesia type or patient acuity.
- Test benchmarks on independent data.
- Compare actual and booked durations if scheduling data becomes available.
