# OR Scheduling Reliability & Cost Exposure

**An end-to-end healthcare analytics project that turns perioperative data into procedure-level insights for scheduling review.** Built with Microsoft Fabric, PySpark, SQL, and Power BI, with a public interactive web dashboard.

### [▶ Open the live interactive dashboard](https://thrinesh13.github.io/OR-Scheduling-Reliability-Analytics/)

**No sign-in or Power BI license is needed to explore the web dashboard.**

[Dashboard guide](docs/DASHBOARD_GUIDE.md) · [Data quality](docs/DATA_QUALITY.md) · [Data lineage](docs/DATA_LINEAGE.md) · [Run the project](docs/SETUP.md)

![Power BI report overview](assets/OR_OVERVIEW.png)

> **What this measures:** Actual OR duration compared with each procedure’s **historical median duration—not its booked schedule**.
>
> **What the dollar figures mean:** Gross time-cost scenarios, **not confirmed losses, avoidable costs, or recoverable savings**.

## The business question

**Which procedures combine frequent duration differences with substantial accumulated time variation, and should be reviewed first?**

A procedure can accumulate high exposure because it is performed often, because its durations vary widely, or both. This project keeps **reliability** and **exposure** separate so stakeholders can see why a procedure warrants attention.

## Results at a glance

| Metric | Result |
|---|---:|
| Source records staged across four tables | **1,880,637** |
| Qualifying surgical cases | **48,118** |
| Procedures analyzed | **418** |
| Mean absolute difference from benchmark | **54.1 min** |
| Median absolute difference | **33.0 min** |
| Cases outside ±30 minutes | **53.28%** |
| Annualized absolute time variation | **452,335 min/year** |
| Annual gross exposure at $35/min | **$15.8M** |
| Annual gross exposure at $60/min | **$27.1M** |

**Only 46.72% of cases fall within ±30 minutes of the historical benchmark.** The mean exceeds the median, indicating that larger differences raise the overall average.

| Timing outcome | Cases | Share |
|---|---:|---:|
| More than 30 minutes below benchmark | 11,339 | 23.56% |
| Within ±30 minutes, inclusive | 22,481 | 46.72% |
| More than 30 through 60 minutes above benchmark | 5,077 | 10.55% |
| More than 60 minutes above benchmark | 9,221 | 19.16% |
| **Total** | **48,118** | **100%** |

The four buckets are mutually exclusive. Individually rounded shares sum to 99.99%.

## Explore the dashboard

- **Review focus:** Narrow the cohort to a review category.
- **Procedure selection:** Find a procedure and inspect its benchmark and reliability metrics.
- **Timing distribution:** Select a timing bucket to explore the corresponding cases.
- **Prioritization scatter:** Compare annualized time variation against the percentage outside ±30 minutes; bubble size represents case volume.
- **Procedure table:** Compare volume, historical benchmarks, and review context.

**The web dashboard is a self-contained HTML recreation of the Power BI overview using a fixed data snapshot.** It is not connected to a live Fabric refresh. See the [dashboard guide](docs/DASHBOARD_GUIDE.md) for filtering behavior and differences from Power BI.

## Data and analytical scope

The source is **[MOVER](https://doi.org/10.24432/C5VS5G)**, the Medical Informatics Operating Room Vitals and Events Repository from UC Irvine Medical Center. **Source access requires a data-use agreement; raw source files are not distributed here.**

| Source extract | Bronze rows | Use in this project |
|---|---:|---|
| Patient information | 65,728 | Current analysis |
| Patient history | 970,741 | Staged for future work |
| Procedure events | 640,223 | Staged for future work |
| Post-operative complications | 203,945 | Staged for future work |

**Only patient information contributes to the current dashboard.** The 1.88M staged records are not 1.88M surgical cases.

Silver contains **64,353** cleaned records. Gold retains qualifying cases with usable OR timestamps, durations of **10–720 minutes**, and procedures supported by **at least 30 cases**, producing the 48,118-case analytical cohort.

Reference: Samad et al. (2023), [MOVER: a public-access operating room database](https://doi.org/10.1093/jamiaopen/ooad084), *JAMIA Open*.

## How it was built

```mermaid
flowchart LR
    A[MOVER CSV extracts] --> B[Bronze: raw Delta tables]
    B --> C[Silver: clean and validate cases]
    C --> D[Gold: case facts and procedure baselines]
    D --> E[Power BI model and report]
    E --> F[Public HTML dashboard snapshot]
```

| Stage | Main work | Source |
|---|---|---|
| **Bronze** | Ingest four extracts and reconcile row counts | [01 — Ingestion](notebooks/01_bronze_ingest.ipynb) |
| **Silver** | Resolve duplicates, standardize procedures, validate and repair timestamps, retain quality flags | [02 — Cleaning](notebooks/02_silver_patient_information.ipynb) |
| **Gold** | Apply cohort rules, calculate procedure medians, derive case deviations, reconcile totals | [03 — Analytical tables](notebooks/03_gold.ipynb) |
| **Power BI** | Import Gold tables, define DAX metrics, and build the interactive report | [Power BI source](powerbi/) |
| **Web** | Present the report overview as a public interactive snapshot | [Dashboard](dashboard/index.html) |

**Technology:** Microsoft Fabric · Delta Lake · PySpark · Spark SQL · Power BI · DAX · PBIP/PBIR · TMDL · HTML/CSS/JavaScript · GitHub Pages.

## Metric definitions and interpretation

- **Benchmark:** Historical median OR duration for each qualifying procedure.
- **Signed difference:** Actual OR duration minus benchmark.
- **Absolute difference:** Magnitude of the signed difference, counting both early and late cases.
- **Annualized variation:** **2,600,928 total absolute deviation minutes ÷ 5.75 assumed years**.
- **Gross exposure:** Annualized variation multiplied by **$35/min** or **$60/min**.
- **Review categories:** Compare procedure exposure and reliability with fixed cohort medians; these are relative comparison groups, **not clinical performance targets**.

**Portfolio KPIs are calculated at case level.** Averaging procedure percentages would incorrectly give a small procedure group the same weight as a large one.

## Limitations and next steps

- **Retrospective benchmark:** Derived from the same cohort, with no independent holdout validation.
- **Shifted dates:** Patient-specific date shifting prevents valid cross-patient calendar analysis such as seasonality or year-over-year trends.
- **Restricted cohort:** Low-volume procedures and cases outside eligibility rules are excluded.
- **Scenario assumptions:** The 5.75-year divisor and cost-per-minute rates are fixed planning assumptions.
- **Descriptive findings:** The analysis identifies where variation occurs; it does not establish causes or demonstrate savings.

**Next steps:** Validate benchmarks on independent data, investigate relevant case characteristics, and incorporate actual booked durations before evaluating scheduling interventions.

## Open or reproduce the project

**For visitors:** [Open the live dashboard](https://thrinesh13.github.io/OR-Scheduling-Reliability-Analytics/).

**For Power BI users:** Download or clone the repository and open [`powerbi/OR_Scheduling_Reliability.pbip`](powerbi/OR_Scheduling_Reliability.pbip) in a current compatible Power BI Desktop version. Keep its adjacent report and semantic-model folders together.

**For refresh or rebuilding:** Follow [setup instructions](docs/SETUP.md). You need authorized source access and your own configured Fabric environment. **The Power BI cache is intentionally excluded**, so a fresh checkout needs a data refresh; the web dashboard works independently.

Notebook source and transformation logic are retained; saved outputs, execution state, and workspace attachment metadata are removed. Supporting CSV exports retain their original filenames and values. Updating those CSVs alone does not rebuild the web dashboard.

## Project structure

```text
OR-Scheduling-Reliability-Analytics/
├── README.md
├── .gitignore
├── .nojekyll
├── index.html                         # Live-site entry point
├── assets/
│   └── OR_OVERVIEW.png                # Power BI overview image
├── dashboard/
│   └── index.html                     # Self-contained interactive dashboard
├── dashboard-data/
│   ├── How often do case times miss the benchmark.csv
│   ├── Where should scheduling review begin.csv
│   ├── Which procedures deserve a closer look.csv
│   ├── README.md                      # Export scope and refresh limitations
│   └── OR-dashboard.html              # Redirect preserving the previous URL
├── docs/
│   ├── DASHBOARD_GUIDE.md
│   ├── DATA_LINEAGE.md
│   ├── DATA_QUALITY.md
│   └── SETUP.md
├── notebooks/
│   ├── 01_bronze_ingest.ipynb
│   ├── 02_silver_patient_information.ipynb
│   └── 03_gold.ipynb
└── powerbi/
    ├── OR_Scheduling_Reliability.pbip
    ├── OR_Scheduling_Reliability.Report/
    │   ├── .platform
    │   ├── definition.pbir
    │   ├── definition/               # Pages, visuals, and report settings
    │   └── StaticResources/          # Referenced theme
    └── OR_Scheduling_Reliability.SemanticModel/
        ├── .platform
        ├── definition.pbism
        ├── definition/               # TMDL tables, DAX, and relationships
        └── diagramLayout.json
```
