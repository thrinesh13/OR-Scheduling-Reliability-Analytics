# Operating Room Scheduling Accuracy

Measuring, locating and pricing the gap between scheduled and actual surgical case duration across 48,117 operations at a US academic medical centre.

**[View the live Power BI report →](REPORT_URL_HERE)**

Built end to end in Microsoft Fabric: lakehouse ingestion, PySpark transformation, medallion architecture, Import-mode semantic model, published Power BI report.

---

## The problem

Operating room time costs a hospital roughly $35 to $60 per minute. The surgical schedule is built on duration estimates, and those estimates are wrong about half the time. Cases that run long generate overtime and bump the cases behind them. Cases that finish early leave a fully staffed room idle.

Most analyses of this problem measure overruns only. This one measures both directions, and prices them.

## Key findings

**Fewer than half of all cases land within 30 minutes of their expected duration.** 29.7% run more than 30 minutes long, 23.6% finish more than 30 minutes early, and 53.3% miss in one direction or the other. Median absolute error is 33 minutes; mean absolute error is 54.1 minutes.

**The error is worth $15.8M to $27.1M a year.** 452,331 misallocated OR minutes annually, priced at the industry range of $35 to $60 per minute. This is total scheduling error rather than recoverable waste, so the report also models a conservative recoverable share.

**Procedure identity drives duration; patient acuity does not.** Mean duration across ASA physical status classes spans only 181 to 202 minutes, while CABG averages 429 minutes against 167 for a laparoscopic cholecystectomy. Scheduling models built on patient characteristics are solving the wrong problem.

**There are two distinct problem classes requiring different interventions.** High-variability procedures such as Exam Under Anesthesia, Diagnostic Laparoscopy and Cystoscopy carry a coefficient of variation near 0.8 and need buffer strategies. High-volume procedures such as Exploratory Laparotomy and Laparoscopic Cholecystectomy consume thousands of OR hours each and need estimate refinement.

**16.1% of the operative population is structurally unschedulable.** 9,230 cases sit on 1,286 procedures performed too rarely to support a stable historical baseline. Structural name normalization was tested against the full name population and could recover at most 9% of them. This is an operational constraint, not a data quality defect.

## Data quality

The dataset required substantial remediation before any figure above could be trusted. Every rule below was sized against the full population before adoption, never against the sample that suggested it.

**Duplicate records.** `LOG_ID` is not unique in the source. 1,374 duplicated IDs, of which 99.3% are byte-identical row copies from a duplicated load. The 10 genuine conflicts were inspected individually; all had identical OR durations, making the deterministic tiebreak provably neutral to every published metric. 65,728 rows resolve to 64,354.

**A misdocumented timestamp format.** The source specification recorded a four-digit year. A digit-shape inventory across all 57,952 values showed the year is two digits in every case. PostgreSQL accepted the strings silently; Spark's strict parser refused them, which is how the defect surfaced. A permissive parser setting would have silently assigned an arbitrary century.

**Corrupt timestamps invisible to range filters.** OR timestamps were cross-validated against independently recorded anesthesia timestamps, which normally agree to the minute (median discrepancy 0, p99 4 minutes across 56,931 records). Twelve records were repaired across two defect patterns, a one-day offset on OR exit and AM/PM inversions on OR entry, and two were excluded. Each repair was verified against the anesthesia record rather than asserted.

**Nine extreme cases confirmed as genuine.** The same cross-check proved that nine operations exceeding 21 hours, including free flap breast reconstructions, a pelvic exenteration and a Whipple procedure, were real. A duration threshold alone would have discarded them as errors.

**Keys damaged upstream.** 0.12% of records carry identifiers destroyed by numeric coercion in the published dataset, written back in scientific notation with no inverse. Confirmed as upstream by checking a source file unmodified since 2022. These rows are flagged and retained for duration analysis, and excluded only from the joins that need a valid key.

**Findings are robust to all of it.** Headline figures shifted by less than 0.2% after every correction above. That is a measured demonstration rather than an assumption.

**Negative results reported as findings.** Mechanical name normalization merged one procedure name out of 1,768. Truncating qualifier clauses was rejected after median durations diverged more than 30% in both directions across affected procedures, confirming that qualifiers carry duration-relevant clinical content. A selective variant was rejected as circular, since it would have chosen merges using the variance metric it was meant to feed.

## Architecture

```
CSV source files
      │
      ▼
  bronze/     Raw landing. Explicit all-string schema, no type inference.
              Row counts verified against source to the record.
      │
      ▼
  silver/     Deduplicated, typed, corrected. Raw columns retained
              alongside derived ones for audit. Every cast null-accounted.
      │
      ▼
  gold/       Curated star schema. fact_cases (48,117 rows) joined to
              procedure_baseline (418 procedures). The join enforces the
              analysis cohort, so the filter exists in exactly one place.
      │
      ▼
  Import-mode semantic model → Power BI report
```

The cleaning happens inside the pipeline rather than before it. Data arrives in the lakehouse in its original state, and every transformation is reproducible by rerunning a notebook from the layer below.

## Repository

```
notebooks/
  01_bronze_ingest.ipynb              CSV to Delta, all-string, row counts verified
  02_silver_patient_information.ipynb Dedup, type casting, timestamp remediation
  03_gold.ipynb                       Procedure baselines and case fact table
sql/
  gold_views.sql                      SQL analytics endpoint views
docs/
  cleaning_rules.md                   Every rule, its evidence, and rules rejected
  metric_definitions.md               How each published metric is calculated
screenshots/
```

## Metric definitions

| Metric | Definition |
|---|---|
| OR Duration | OR exit minus OR entry, in minutes |
| Expected Duration | Median OR duration by procedure, a proxy for booked time |
| Schedule Error | Actual minus expected, signed |
| Overrun Rate | Share of cases with error above 30 minutes |
| Predictability (CV) | Standard deviation divided by mean, by procedure |
| OR Hours Consumed | Case count multiplied by mean duration |

**Analysis cohort:** cases with both OR timestamps present, duration between 10 and 720 minutes, on procedures with at least 30 usable cases. 48,117 of 64,352 records.

## Data

MOVER (Medical Informatics Operating Room Vitals and Events Repository), a de-identified perioperative dataset covering November 2017 to August 2023. Four source files totalling 136 MB: case records, procedure events, post-operative complications and patient diagnosis history.

Dates are shifted per patient for de-identification, so day-of-week and seasonal analysis is not possible. Times of day are intact and are used. Patient age is top-coded at 90 per HIPAA requirements.

## Stack

Microsoft Fabric · PySpark · Spark SQL · Delta Lake · Power BI · DAX · PostgreSQL (profiling)
