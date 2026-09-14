# Data Quality and Feature Engineering

## Purpose

This document records how the MOVER patient-information data was profiled, cleaned, repaired, validated, and transformed for the OR Scheduling Reliability analysis. It also records known data and model issues that affect interpretation in Power BI.

The goal of the Silver layer was simple: produce one row per surgical case, calculate a duration worth using, and retain a flag for every value changed. Cohort selection and analytical features were then applied in Gold.

For source-to-report dependencies, see [DATA_LINEAGE.md](DATA_LINEAGE.md).

## Quality checkpoints

| Checkpoint | Rows | What changed |
|---|---:|---|
| Bronze `patient_information` | 65,728 | Source preserved as strings |
| After trimming and exact deduplication | 64,362 | 1,366 identical rows removed |
| After resolving duplicate `log_id` values | 64,354 | One deterministic row retained per case ID |
| Final Silver table | 64,353 | One unresolved timestamp outlier excluded |
| Silver rows with an OR duration | 57,861 | Both usable OR timestamps available |
| Final Gold case cohort | 48,118 | Duration and procedure-volume eligibility applied |

The final Silver table contains 64,353 rows. The Gold cohort contains 48,118 cases across 418 procedures.

## Bronze ingestion controls

All four CSV extracts were loaded with `inferSchema=False`, keeping every field as a string. No renaming, casting, trimming, filtering, or row removal occurred during ingestion.

| Bronze table | Rows | Columns | Used in current analysis |
|---|---:|---:|---|
| `bronze.patient_information` | 65,728 | 23 | Yes |
| `bronze.patient_history` | 970,741 | 3 | No—staged for future work |
| `bronze.patient_procedure_events` | 640,223 | 5 | No—staged for future work |
| `bronze.patient_post_op_complications` | 203,945 | 6 | No—staged for future work |

Each Delta table was read back after writing, and its row and column counts were reconciled with the source DataFrame.

Current ingestion limitations:

- The notebook does not enforce an explicit source-schema contract.
- Malformed-row capture, encoding validation, ingestion timestamps, and schema-drift alerts are not yet implemented.
- The three unused Bronze tables should not be presented as inputs to the current analytical findings.

## Profiling and issue resolution

### Duplicate records

Trimming string values and removing exact duplicates reduced the table from 65,728 to 64,362 rows. Duplicate `log_id` values were then reviewed because `log_id` represents a surgical case.

Conflicting duplicates had the same OR duration. A deterministic window ordered the complete row representation and retained one record per `log_id`, producing 64,354 unique case IDs.

### Potentially corrupted identifiers

Some identifiers appeared in scientific notation, suggesting that digits may have been lost before ingestion.

| Flag | Records |
|---|---:|
| `log_id_corrupt` | 39 |
| `mrn_corrupt` | 37 |

The records were retained because the identifiers do not affect the case-duration calculations. The flags warn against using affected values as reliable join keys in future extensions.

### Timestamp parsing and missingness

Four source fields were parsed using `M/d/yy H:mm`:

- `in_or_dttm` → `in_or`
- `out_or_dttm` → `out_or`
- `an_start_datetime` → `an_start`
- `an_stop_datetime` → `an_stop`

There were no parse failures among populated values. However, 6,492 records were missing either `in_or` or `out_or` and could not support an OR-duration calculation. Only 10 cases had a missing `in_or` while `an_start` and `out_or` were both present; broad imputation was not performed because it would not resolve most missing-duration cases and would introduce unnecessary assumptions.

### Initial OR-duration profile

`or_duration_min` measures room occupancy from OR entry to OR exit; it is not surgical incision-to-close time.

Before repairs, the profile identified:

- 57,862 non-null OR durations
- 1 non-positive duration
- 8 cases above 1,440 minutes with a clear one-day offset pattern
- additional long-duration records requiring review rather than automatic deletion

Long duration alone was not treated as proof of bad data. After repair and review, 508 cases above 720 minutes remained in Silver because they appeared genuine. They were later excluded from the Gold analytical cohort by the 10–720 minute eligibility rule.

## Timestamp validation and repairs

### Why anesthesia timestamps were used

The OR and anesthesia timestamps come from separate systems but describe the same case. Their normal relationship was measured before using anesthesia as a validation clock.

| Comparison | Records checked | Median gap | p95 | p99 |
|---|---:|---:|---:|---:|
| `in_or` vs. `an_start` | 55,815 | 0 min | 2 min | 10 min |
| `out_or` vs. `an_stop` | — | 8 min | 18 min | 33 min |

The close alignment between `in_or` and `an_start` supported using `an_start` only when the recorded OR start was clearly invalid. The exit gap is naturally wider because anesthesia care can continue after the patient leaves the OR.

There were 57,029 cases with a usable anesthesia duration and no non-positive anesthesia durations.

### OR–anesthesia disagreement profile

`or_minus_anes` was calculated as:

```text
or_duration_min - anes_duration_min
```

The middle 50% of cases ranged from −10 to −6 minutes, with a median of −7 minutes. Extreme differences were reviewed as possible timestamp errors rather than being repaired solely because they were statistical outliers.

### Repairs applied

| Repair | Rule and evidence | Result |
|---|---|---:|
| One-day `out_or` offset | Subtract one day when OR duration exceeded 1,440 minutes | 8 cases repaired |
| Negative OR duration | Replace the invalid `in_or` with `an_start` after confirming normal start-time alignment | 1 case repaired |
| Large `in_or` gap | Review cases where OR duration exceeded 3× anesthesia duration, start gap exceeded 120 minutes, and anesthesia duration was at least 60 minutes | 4 additional cases repaired |

The five `in_or` repairs include the negative-duration case. All changes are traceable through `out_or_repaired_flag` and `in_or_repaired_flag`.

One record, `8338d2b6d17feea0`, showed an OR duration of 1,367 minutes and an anesthesia duration of 47 minutes. It did not match a defensible repair pattern, so it was excluded rather than modified.

A small number of other cases, including tunneled catheter placements, had anesthesia timestamps substantially misaligned with OR timestamps. They were not used as evidence for timestamp repair because the relationship was unclear.

### Post-repair validation

After repair and exclusion:

- 57,861 OR durations remained
- no non-positive OR durations remained
- OR durations ranged from 3 to 1,399 minutes
- 8 `out_or` and 5 `in_or` values carried repair flags
- one unresolved timestamp record was excluded

## Procedure-name quality

Procedure names were uppercased, trimmed, and reduced to single spaces. Compound names containing standalone `AND` or `OR` were flagged rather than merged with individual procedures because they can represent different case scope and duration.

- 207 distinct compound procedure names were identified
- 9,015 cases, approximately 14% of Silver, carried the compound-name flag

A punctuation-insensitive fingerprint removed all non-alphanumeric characters to detect remaining variants. Two variant groups were manually reviewed and merged:

- encoded/trailing-character variants of `CRANIOPLASTY FOR CRANIAL DEFECT`
- comma variants of `RESECTION, TEMPORAL BONE, EXTERNAL APPROACH`

The process reduced 1,768 raw names to 1,765 standardized names.

## Missing values and type decisions

| Field | Finding | Treatment |
|---|---|---|
| `age_years` | No missing values; range 17–90 | Cast to integer |
| `los_days` | 14 missing values | Retained as missing; cast to numeric |
| `asa_rating_c` | 6,809 missing values, about 10.6% | Retained as missing; not imputed |
| `procedure_nm` | 6 missing values | Retained in Silver; excluded where Gold requires a procedure |
| `icu_admit` | Source flag contains missing values | Derived as Boolean; missing treated as `False` |
| `height` | Free-text source field | Left unchanged and unused |
| `weight` | Stored in ounces | Left unchanged and unused |

The remaining categorical fields—sex, ASA rating, anesthesia type, patient class group, patient class, and discharge disposition—were profiled by value count. No additional label standardization was required.

## Feature engineering

### Silver features

| Feature | Definition |
|---|---|
| `or_duration_min` | Minutes between repaired `in_or` and `out_or` |
| `anes_duration_min` | Minutes between `an_start` and `an_stop` |
| `or_minus_anes` | OR duration minus anesthesia duration |
| `age_years` | Integer patient age from the source `birth_date` field |
| `los_days` | Numeric length of stay |
| `icu_admit` | Boolean ICU-admission indicator |
| `start_hour` | Hour extracted from repaired `in_or` |
| `procedure_nm` | Standardized procedure name |
| `is_compound_name` | Procedure-name compound indicator |

### Gold cohort and features

Gold includes cases with non-null OR timestamps, an OR duration from 10 through 720 minutes, a non-null procedure name, and a procedure with at least 30 qualifying cases.

| Feature | Definition |
|---|---|
| `expected_duration_min` | Historical median OR duration for the procedure |
| `schedule_error_min` | Actual OR duration minus the procedure baseline |
| `abs_error_min` | Absolute difference from baseline |
| `overrun_30` | More than 30 minutes above baseline |
| `overrun_60` | More than 60 minutes above baseline |
| `early_30` | More than 30 minutes below baseline |
| `cv` | Procedure duration standard deviation divided by mean |
| `or_hours_consumed` | Total observed OR minutes converted to hours |
| `total_deviation_min` | Sum of absolute deviation for a procedure |

The Gold output contains 418 procedure baselines and 48,118 case records. Total deviation reconciles exactly between the case and procedure tables at 2,600,928 minutes.

## Power BI data and model issues

### Percentage denominator issue

The timing-outcome categories contain mutually exclusive case counts that reconcile to 48,118. In the current report implementation, the on-screen category percentages can sum to approximately 100.7% because a bidirectional relationship changes the comparison base slightly by category.

The headline percentages in the README and dashboard guide are calculated from the reconciled case counts, not from the affected displayed percentages.

Recommended correction:

1. Replace the bidirectional relationship with single-direction filtering where possible.
2. Re-test cross-filtering between the case table, procedure table, timing chart, and procedure selections.
3. Validate every percentage against the 48,118-row case-level denominator.

### Grain control

Portfolio averages and percentages must be calculated from `gold.fact_cases`. Averaging procedure-level percentages would give a 30-case procedure the same influence as a procedure with hundreds of cases. `gold.procedure_baseline` should support procedure comparisons, not replace the case table as the denominator for portfolio KPIs.

### Date analysis restriction

MOVER applies patient-specific date shifts. Duration calculations within a case remain usable, but cross-patient calendar features must not be interpreted as real seasonality, weekday effects, or year-over-year trends. A conventional calendar dimension would therefore imply unsupported calendar analysis unless an appropriate unshifted source becomes available.

## Remaining improvements

- Replace the hardcoded Silver row-count assertion with property-based validation and reconciliation checks that remain valid after legitimate source updates.
- Enforce or quarantine the `log_id_corrupt` and `mrn_corrupt` flags before future joins.
- Add Bronze schema contracts, malformed-row handling, ingestion metadata, and schema-drift monitoring.
- Resolve and document the role of every staged Bronze table before bringing it into the analytical model.
- Correct and regression-test the Power BI percentage denominator behavior.
- Validate the historical-median benchmark on a holdout period or independent dataset.

## Reproducibility

The evidence and transformations summarized here are implemented in:

- [`01_bronze_ingest.ipynb`](01_bronze_ingest.ipynb)
- [`02_silver_patient_information.ipynb`](02_silver_patient_information.ipynb)
- [`03_gold.ipynb`](03_gold.ipynb)

This document summarizes the decisions; the notebooks remain the executable record.
