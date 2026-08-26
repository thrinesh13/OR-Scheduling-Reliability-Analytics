-- SQLBook: Code
-- Active: 1786756852604@@localhost@5432@Mover
select count(*) from patient_information;
-- SQLBook: Code
select *from patient_information limit 10;
-- SQLBook: Code
SELECT column_name, data_type, character_maximum_length, is_nullable
FROM information_schema.columns
WHERE table_name = 'patient_information' ORDER BY ordinal_position;
-- SQLBook: Code
-- ============================================================
-- Q1. Grain check: is LOG_ID a valid primary key?
-- ============================================================
SELECT
    COUNT(*)                              AS total_rows,
    COUNT(DISTINCT "LOG_ID")              AS distinct_log_ids,
    COUNT(*) - COUNT(DISTINCT "LOG_ID")   AS excess_rows,
    COUNT(DISTINCT "MRN")                 AS distinct_patients,
    ROUND(COUNT(*)::numeric / NULLIF(COUNT(DISTINCT "MRN"), 0), 2) AS cases_per_patient
FROM patient_information;
-- SQLBook: Code
-- ============================================================
-- Q2. Is LOG_ID clean enough to count?
-- If distinct_raw <> distinct_trimmed, whitespace is hiding
-- duplicates and the grain answer is wrong before we start.
-- ============================================================
SELECT
    COUNT(DISTINCT "LOG_ID")                    AS distinct_raw,
    COUNT(DISTINCT TRIM("LOG_ID"))              AS distinct_trimmed,
    COUNT(DISTINCT UPPER(TRIM("LOG_ID")))       AS distinct_upper_trimmed,
    COUNT(*) FILTER (WHERE "LOG_ID" <> TRIM("LOG_ID")) AS rows_with_padding,
    COUNT(*) FILTER (WHERE "LOG_ID" IS NULL)    AS null_log_ids,
    MIN(LENGTH("LOG_ID"))                       AS min_len,
    MAX(LENGTH("LOG_ID"))                       AS max_len
FROM patient_information;
-- SQLBook: Code
-- ============================================================
-- Q3. Grain shape: how many rows per LOG_ID?
-- All 2s means a load artifact. A long tail means the table
-- has a legitimate finer grain we have not identified yet.
-- ============================================================
WITH id_counts AS (
    SELECT
        "LOG_ID"  AS log_id,
        COUNT(*)  AS rows_per_id
    FROM patient_information
    GROUP BY "LOG_ID"
)
SELECT
    rows_per_id,
    COUNT(*)                AS num_log_ids,
    COUNT(*) * rows_per_id  AS rows_involved
FROM id_counts
GROUP BY rows_per_id
ORDER BY rows_per_id;
-- SQLBook: Code
-- ============================================================
-- Q4. Are the short LOG_IDs the duplicated ones?
-- Baseline duplicate rate is 1374/64354 = 2.14%.
-- If short IDs sit far above that, truncation is CREATING
-- duplicates and the fix is key repair, not dedup.
-- ============================================================
WITH id_counts AS (
    SELECT "LOG_ID" AS log_id, COUNT(*) AS rows_per_id
    FROM patient_information
    GROUP BY "LOG_ID"
)
SELECT
    LENGTH(log_id)                                AS id_length,
    COUNT(*)                                      AS num_log_ids,
    COUNT(*) FILTER (WHERE rows_per_id = 2)       AS duplicated_ids,
    ROUND(100.0 * COUNT(*) FILTER (WHERE rows_per_id = 2) / COUNT(*), 2) AS pct_duplicated
FROM id_counts
GROUP BY LENGTH(log_id)
ORDER BY id_length;
-- SQLBook: Code
-- ============================================================
-- Q5. THE decisive query. Of the 1,374 duplicated IDs, how many
-- are byte-identical row copies vs genuinely conflicting rows?
-- ============================================================
WITH rows_json AS (
    SELECT "LOG_ID" AS log_id, to_jsonb(p) AS row_json
    FROM patient_information p
),
grouped AS (
    SELECT
        log_id,
        COUNT(*)                  AS n_rows,
        COUNT(DISTINCT row_json)  AS n_distinct_rows
    FROM rows_json
    GROUP BY log_id
    HAVING COUNT(*) > 1
)
SELECT
    COUNT(*)                                       AS duplicated_ids,
    COUNT(*) FILTER (WHERE n_distinct_rows = 1)    AS exact_row_copies,
    COUNT(*) FILTER (WHERE n_distinct_rows > 1)    AS conflicting_pairs
FROM grouped;
-- SQLBook: Code
-- ============================================================
-- Q6. For the conflicting pairs, WHICH columns disagree?
-- MRN disagreeing means two different patients = ID collision.
-- Only procedure name disagreeing means a multi-procedure case.
-- ============================================================
WITH dup_ids AS (
    SELECT "LOG_ID" AS log_id
    FROM patient_information
    GROUP BY "LOG_ID"
    HAVING COUNT(*) > 1
),
exploded AS (
    SELECT
        p."LOG_ID" AS log_id,
        kv.key     AS column_name,
        kv.value   AS col_value
    FROM patient_information p
    JOIN dup_ids d ON d.log_id = p."LOG_ID"
    CROSS JOIN LATERAL jsonb_each_text(to_jsonb(p)) AS kv
),
per_group AS (
    SELECT
        log_id,
        column_name,
        COUNT(DISTINCT COALESCE(col_value, '<NULL>')) AS distinct_vals
    FROM exploded
    GROUP BY log_id, column_name
)
SELECT
    column_name,
    COUNT(*) FILTER (WHERE distinct_vals > 1) AS groups_differing
FROM per_group
GROUP BY column_name
ORDER BY groups_differing DESC, column_name;
-- SQLBook: Code
-- ============================================================
-- Q7. Eyeball the 10 conflicting pairs. Twenty rows, read them.
-- ============================================================
WITH rows_json AS (
    SELECT "LOG_ID" AS log_id, to_jsonb(p) AS row_json
    FROM patient_information p
),
conflicting AS (
    SELECT log_id
    FROM rows_json
    GROUP BY log_id
    HAVING COUNT(*) > 1 AND COUNT(DISTINCT row_json) > 1
)
SELECT
    p."LOG_ID", p."MRN", p."SEX", p."BIRTH_DATE", p."HEIGHT", p."WEIGHT",
    p."SURGERY_DATE", p."IN_OR_DTTM", p."OUT_OR_DTTM",
    p."PRIMARY_PROCEDURE_NM", p."PRIMARY_ANES_TYPE_NM", p."DISCH_DISP"
FROM patient_information p
JOIN conflicting c ON c.log_id = p."LOG_ID"
ORDER BY p."LOG_ID", p."IN_OR_DTTM";
-- SQLBook: Code
-- ============================================================
-- CLEANING RULE: LOG_ID grain resolution
--   1. TRIM all text columns (fixes 2 of 10 conflicts)
--   2. DISTINCT on full row (resolves 1,366 of 1,374)
--   3. Deterministic tiebreak on the remaining 8
-- Metric impact: NONE. All conflicting pairs have identical
-- OR duration, verified in Q7.
-- 65,728 -> 64,354 rows. LOG_ID becomes a true primary key.
-- ============================================================
WITH trimmed AS (
    SELECT
        TRIM("LOG_ID")               AS log_id,
        TRIM("MRN")                  AS mrn,
        TRIM("PRIMARY_PROCEDURE_NM") AS primary_procedure_nm,
        TRIM("PRIMARY_ANES_TYPE_NM") AS primary_anes_type_nm,
        TRIM("ASA_RATING")           AS asa_rating,
        TRIM("DISCH_DISP")           AS disch_disp,
        TRIM("SEX")                  AS sex,
        TRIM("ICU_ADMIN_FLAG")       AS icu_admin_flag,
        TRIM("PATIENT_CLASS_GROUP")  AS patient_class_group,
        TRIM("PATIENT_CLASS_NM")     AS patient_class_nm,
        TRIM("HEIGHT")               AS height,
        TRIM("WEIGHT")               AS weight,
        TRIM("BIRTH_DATE")           AS age_years,
        TRIM("LOS")                  AS los,
        TRIM("IN_OR_DTTM")           AS in_or_dttm,
        TRIM("OUT_OR_DTTM")          AS out_or_dttm,
        TRIM("AN_START_DATETIME")    AS an_start_datetime,
        TRIM("AN_STOP_DATETIME")     AS an_stop_datetime,
        TRIM("SURGERY_DATE")         AS surgery_date,
        TRIM("HOSP_ADMSN_TIME")      AS hosp_admsn_time,
        TRIM("HOSP_DISCH_TIME")      AS hosp_disch_time,
        TRIM("DISCH_DISP_C")         AS disch_disp_c
    FROM patient_information
),
deduped AS (
    SELECT DISTINCT * FROM trimmed
),
ranked AS (
    SELECT
        d.*,
        ROW_NUMBER() OVER (
            PARTITION BY log_id
            ORDER BY to_jsonb(d)::text   -- arbitrary but reproducible
        ) AS rn
    FROM deduped d
)
SELECT * FROM ranked WHERE rn = 1;
-- SQLBook: Code
-- ============================================================
-- Q8. What types did the load actually produce?
-- ============================================================
SELECT
    ordinal_position,
    column_name,
    data_type,
    character_maximum_length
FROM information_schema.columns
WHERE table_name = 'patient_information'
ORDER BY ordinal_position;
-- SQLBook: Code
-- ============================================================
-- Q9. How far did the numeric coercion spread?
-- MRN gates the patient_history join, so this matters more
-- than LOG_ID did.
-- ============================================================
SELECT
    COUNT(*) FILTER (WHERE "MRN" LIKE '%E+%')          AS mrn_scientific,
    COUNT(*) FILTER (WHERE "LOG_ID" LIKE '%E+%')       AS log_id_scientific,
    COUNT(*) FILTER (WHERE LENGTH("MRN") <> 16)        AS mrn_wrong_length,
    MIN(LENGTH("MRN"))                                 AS mrn_min_len,
    MAX(LENGTH("MRN"))                                 AS mrn_max_len,
    COUNT(DISTINCT "MRN")                              AS distinct_mrn,
    MAX(LENGTH("PRIMARY_PROCEDURE_NM"))                AS max_proc_len,
    COUNT(*) FILTER (WHERE LENGTH("PRIMARY_PROCEDURE_NM") = 128) AS proc_at_limit
FROM patient_information;
-- SQLBook: Code
-- ============================================================
-- Q11. Key integrity across all four tables.
-- complications is the control: untouched since Dec 2022.
-- ============================================================
SELECT 'events' AS src,
       COUNT(*) AS rows,
       COUNT(DISTINCT "LOG_ID") AS distinct_log_ids,
       COUNT(*) FILTER (WHERE "LOG_ID" LIKE '%E+%') AS scientific,
       MIN(LENGTH("LOG_ID")) AS min_len, MAX(LENGTH("LOG_ID")) AS max_len
FROM "patient_procedure_events"
UNION ALL
SELECT 'complications',
       COUNT(*), COUNT(DISTINCT "LOG_ID"),
       COUNT(*) FILTER (WHERE "LOG_ID" LIKE '%E+%'),
       MIN(LENGTH("LOG_ID")), MAX(LENGTH("LOG_ID"))
FROM patient_post_op_complications
UNION ALL
SELECT 'history',
       COUNT(*), COUNT(DISTINCT "mrn"),
       COUNT(*) FILTER (WHERE "mrn" LIKE '%E+%'),
       MIN(LENGTH("mrn")), MAX(LENGTH("mrn"))
FROM patient_history;
-- SQLBook: Code
-- Confirm
SELECT * FROM patient_post_op_complications WHERE "LOG_ID" = 'LOG_ID';
SELECT * FROM patient_procedure_events WHERE "LOG_ID" = 'LOG_ID';

-- Remove
DELETE FROM patient_post_op_complications WHERE "LOG_ID" = 'LOG_ID';
DELETE FROM patient_procedure_events WHERE "LOG_ID" = 'LOG_ID';