# OR Scheduling Reliability & Cost Exposure

**An end-to-end healthcare analytics project that uses Microsoft Fabric, PySpark, SQL, and Power BI to turn perioperative data into an interactive dashboard. It measures how actual operating-room durations differ from historical procedure benchmarks, helping identify procedures that warrant scheduling review.**

**[Explore the live interactive dashboard](https://thrinesh13.github.io/OR-Scheduling-Reliability-Analytics/)** · [View the Power BI project](powerbi/OR_Scheduling_Reliability.pbip)

![Power BI dashboard overview](assets/OR_OVERVIEW.png)

## Business case

OR time is expensive and limited. If a case takes much longer or less time than expected, it can make staffing and room planning harder. Leaders need a way to see **how often durations vary, how much variation accumulates, and which procedures deserve closer review**.

**This project compares each case’s actual OR duration with the historical median duration for its procedure.** That median is a planning benchmark, **not the time originally booked on a schedule**. The analysis measures predictability against history; it does not measure actual schedule adherence.

## Solution

I built a data pipeline and an interactive Power BI report that move from raw perioperative records to two views of the problem:

- **Reliability:** The share of a procedure’s cases more than 30 minutes from its benchmark.
- **Exposure:** The total absolute time difference accumulated across that procedure’s cases, annualized for comparison.

Keeping these measures separate helps distinguish a frequently performed procedure from one with less predictable individual cases. The report supports filtering by review category, timing outcome, and procedure. The [public web dashboard](https://thrinesh13.github.io/OR-Scheduling-Reliability-Analytics/) makes the overview available without a Power BI sign-in.

## Data and why Fabric

The project uses [MOVER](https://doi.org/10.24432/C5VS5G), a de-identified perioperative dataset from UC Irvine Medical Center. **Access to the underlying source data requires a data-use agreement**, so raw extracts are not included in this repository.

Four source tables were staged, totaling about **1.88 million records**. **Only the patient-information table contributes to the current findings**; the history, procedure-event, and complication tables are staged for possible future analysis. After cleaning and eligibility rules, the analytical cohort contains **48,118 cases across 418 procedures**.

**Microsoft Fabric provides one place to ingest, clean, and model the data before reporting.** Fabric Lakehouse and Delta tables hold the Bronze, Silver, and Gold layers. PySpark and Spark SQL notebooks transform the data, validate timestamps and duplicates, and calculate case-level differences and procedure benchmarks. Power BI imports the Gold tables through the Fabric SQL endpoint to provide the semantic model, DAX measures, and report.

The three notebooks run in order: [Bronze ingestion](notebooks/01_bronze_ingest.ipynb) → [Silver cleaning](notebooks/02_silver_patient_information.ipynb) → [Gold analytical tables](notebooks/03_gold.ipynb).

## Key findings

| Finding | Result |
|---|---:|
| Cases and procedures analyzed | **48,118 cases · 418 procedures** |
| Cases within ±30 minutes of the historical benchmark | **46.7%** |
| Cases outside ±30 minutes | **53.3%** |
| Mean and median absolute difference | **54.1 min · 33.0 min** |
| Annualized absolute time variation | **452,335 min/year** |
| Annual gross exposure at $35–$60 per minute | **$15.8M–$27.1M** |

**More than half of cases differ from their procedure benchmark by over 30 minutes.** The mean difference is higher than the median, showing that larger differences pull up the average. Exposure is spread across procedures, so prioritization should consider both case volume and reliability.

**The dollar values are planning scenarios, not measured financial losses or guaranteed savings.** They apply $35 and $60 per minute to total absolute deviation annualized over an assumed 5.75-year period.

## Limitations

- **Historical benchmark:** It is calculated from the same cases being evaluated; it has not been tested on an independent holdout sample.
- **No booked-duration data:** The analysis cannot say whether a case finished earlier or later than its actual schedule.
- **Privacy-shifted dates:** Cross-patient calendar trends, such as seasonality and year-over-year changes, are not reliable.
- **Defined cohort:** Procedures with fewer than 30 qualifying cases and cases outside the duration rules are excluded.
- **Scenario costs:** The annualization period and cost-per-minute values are assumptions. Variation is not necessarily avoidable.

## Recommendations

1. **Review procedures with both high exposure and low reliability** before changing scheduling benchmarks.
2. **Validate proposed benchmarks on later or independent cases** to test whether they improve predictions.
3. **Compare with actual booked durations when available** before making claims about schedule accuracy or savings.
4. **Use local OR cost assumptions** before applying the exposure figures to operational planning.

## Tech stack

**Microsoft Fabric** (Lakehouse, Delta tables, SQL endpoint) · **PySpark and Spark SQL** · **Power BI and DAX** · 


## Project structure

```text
OR-Scheduling-Reliability-Analytics/
├── README.md
├── index.html                  # Opens the public dashboard
├── assets/                     # Power BI overview image
├── dashboard/                  # The actual interactive HTML dashboard
├── dashboard-data/             # Three Power BI CSV exports and an old-URL redirect
├── docs/                       # Dashboard guide, data quality, lineage, setup
├── notebooks/                  # Bronze → Silver → Gold transformations
└── powerbi/                    # PBIP launcher, Report, and SemanticModel
```
