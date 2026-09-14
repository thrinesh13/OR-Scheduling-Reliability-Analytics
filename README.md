# OR Scheduling Reliability & Cost Exposure

> **From perioperative data to scheduling decisions.** I used Microsoft Fabric, PySpark, SQL, and Power BI to build a pipeline and interactive report that compare actual operating-room (OR) durations with historical procedure benchmarks. The result helps identify procedures that warrant scheduling review.

**[Explore the live dashboard](https://thrinesh13.github.io/OR-Scheduling-Reliability-Analytics/)** · [Explore the Power BI source and opening instructions](powerbi/README.md)

![Power BI dashboard overview](assets/OR_OVERVIEW.png)

## Why this project matters

OR time is limited and costly. Cases that take substantially more or less time than expected can complicate room use, staffing, and downstream planning. **The business question is: Which procedures vary most often, which accumulate the most time variation, and where should a review begin?**

The available data does not include the duration originally booked for each case. **“Expected” means the historical median OR duration for that procedure—not its actual scheduled slot.** This project measures predictability against history, not schedule adherence.

## What I built

I created a **Bronze → Silver → Gold data pipeline in Microsoft Fabric**, then a **Power BI semantic model and report** over the curated tables. A public HTML version of the report overview lets visitors explore the findings without a Power BI account.

The analysis keeps two questions distinct:

| Lens | What it shows | Why it matters |
|---|---|---|
| **Reliability** | Percentage of a procedure’s cases more than ±30 minutes from its historical benchmark | Shows how predictable a typical case is |
| **Exposure** | Total absolute time difference accumulated across cases, annualized | Shows where variation adds up at scale |

**High exposure does not automatically mean poor per-case reliability.** A frequently performed procedure can accumulate substantial variation even when its individual cases are relatively predictable.

## Data and why Fabric

The source is [MOVER](https://doi.org/10.24432/C5VS5G), a de-identified perioperative dataset from UC Irvine Medical Center. **Access requires a data-use agreement; raw source records are not published in this repository.** Four source tables totaling about **1.88 million records** were staged. **Only patient information feeds the current analysis**; the history, procedure-event, and complication tables are staged for possible future work.

Fabric keeps the processing and reporting path together:

1. **Bronze** preserves the four source extracts as Delta tables and checks ingestion counts.
2. **Silver** cleans patient-information records, resolves duplicates, standardizes procedure names, and validates or flags timestamp issues.
3. **Gold** applies eligibility rules and creates a case-level fact table and procedure-level benchmark table.
4. **Power BI** imports the Gold tables through the Fabric SQL endpoint; DAX measures and visuals support filtering and prioritization.

The final cohort has **48,118 qualifying cases across 418 procedures**. Procedures need at least **30 qualifying cases** to enter the comparison.

## Key findings

| Measure | Full-cohort result |
|---|---:|
| Cases within ±30 minutes of the procedure benchmark | **46.7%** |
| Cases outside ±30 minutes | **53.3%** |
| Mean absolute difference | **54.1 minutes** |
| Median absolute difference | **33.0 minutes** |
| Annualized absolute time variation | **452,335 minutes** |
| Annual gross exposure at $35–$60 per minute | **$15.8M–$27.1M** |

**More than half of cases differ from their historical procedure benchmark by over 30 minutes.** The mean exceeds the median, indicating that larger differences raise the average. **The dollar range is a gross planning scenario, not a measured loss or a savings forecast.** It uses total absolute deviation divided by an assumed **5.75-year** observation period, then applies $35 and $60 per minute.

## What to do with the findings

- **Start review with procedures that combine high exposure and low reliability.** Inspect case volume and the underlying timing distribution before changing a benchmark.
- **Test proposed benchmarks on independent cases.** A historical median built and assessed on the same cohort can look more useful than it will be on new cases.
- **Compare against booked durations when those data become available.** That is needed to evaluate actual schedule accuracy.
- **Use organization-specific cost assumptions.** The two displayed rates illustrate scale; they are not hospital accounting results.

## Limitations

**The benchmark is retrospective and has not been validated on a holdout cohort.** Cases outside the defined duration rules and procedures with fewer than 30 qualifying cases are excluded. MOVER shifts dates separately for each patient, so cross-patient calendar trends such as seasonality are not reliable. The analysis identifies **where** variation occurs; it does not establish **why** it occurs or whether it can be avoided.

## Explore the evidence

| Resource | What you will find |
|---|---|
| **[Dashboard guide](docs/DASHBOARD_GUIDE.md)** | How to read the visuals, use the filters, and interpret review categories and metrics |
| **[Data quality and feature engineering](docs/DATA_QUALITY.md)** | Duplicate handling, timestamp checks and repairs, cohort rules, and validation results |
| **[Data lineage](docs/DATA_LINEAGE.md)** | Source-to-Bronze-to-Silver-to-Gold flow, table dependencies, and metric origins |
| **[Setup and reproduction](docs/SETUP.md)** | How to open the PBIP project and what authorized source access is needed to refresh it |
| **[Transformation notebooks](notebooks/)** | The executable Bronze, Silver, and Gold logic |
| **[Power BI source](powerbi/README.md)** | What the report and model folders contain, plus how to open the project |

**The live dashboard is a fixed, self-contained snapshot.** Refreshing Fabric or replacing the three supporting CSV exports does not automatically update it.

## Tech stack and project flow

**Microsoft Fabric** (Lakehouse, Delta tables, SQL endpoint) · **PySpark and Spark SQL** · **Power BI and DAX** · **PBIP/PBIR and TMDL** · **HTML, CSS, JavaScript, and GitHub Pages**

```mermaid
flowchart LR
    A[MOVER extracts] --> B[Fabric Bronze]
    B --> C[Fabric Silver]
    C --> D[Fabric Gold]
    D --> E[Power BI model and report]
    E --> F[Public dashboard snapshot]
```

## Project structure

```text
OR-Scheduling-Reliability-Analytics/
├── README.md
├── index.html          # Opens the public dashboard
├── assets/             # Power BI overview image
├── dashboard/          # Interactive HTML dashboard
├── dashboard-data/     # Three Power BI CSV exports and old-URL redirect
├── docs/               # Guide, data quality, lineage, and setup
├── notebooks/          # Bronze → Silver → Gold transformations
└── powerbi/            # PBIP launcher, Report, and SemanticModel
```
