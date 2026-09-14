# Open and reproduce the project

## View the dashboard

**[Open the public dashboard](https://thrinesh13.github.io/OR-Scheduling-Reliability-Analytics/)** in a browser. No Fabric credentials are required.

For an offline copy, download the repository and open `dashboard/index.html`. Its data, styles, and scripts are embedded. The root entry point and previous `dashboard-data/OR-dashboard.html` address redirect to this file.

## Open Power BI source

1. Download or clone the full repository.
2. Use a current Power BI Desktop version that supports the supplied PBIP/PBIR and TMDL formats.
3. Open `powerbi/OR_Scheduling_Reliability.pbip`.
4. Keep both adjacent folders intact: `OR_Scheduling_Reliability.Report` and `OR_Scheduling_Reliability.SemanticModel`.

**The report and semantic model definitions are included; the imported data cache is not.** The report’s relative model reference and the launcher’s relative report reference are preserved.

The model’s two Import-mode partitions currently reference the original Fabric SQL endpoint and `moverdata` database. Those connection references do not grant access. To refresh in your own environment, configure the source for your authorized endpoint/database in Power Query, sign in with an authorized account, and ensure both Gold tables exist.

## Rebuild the data pipeline in Fabric

1. Obtain MOVER source data under its access terms. Do not commit raw patient-level extracts.
2. Create a Fabric Lakehouse with schema support and upload these files to its `Files/` area:
   - `patient_information.csv`
   - `patient_history.csv`
   - `patient_procedure_events.csv`
   - `patient_post_op_complications.csv`
3. Import the three notebooks from `notebooks/` into Fabric and attach your Lakehouse as the default. Original workspace attachment metadata has been removed.
4. Run **01 → 02 → 03** in order. The notebooks use PySpark and Spark SQL, including Fabric notebook SQL cells.
5. Review reconciliation and quality checks before refreshing Power BI.
6. Point Power BI at the SQL endpoint/database exposing `gold.fact_cases` and `gold.procedure_baseline`, then refresh.

**The notebooks overwrite their named Bronze/Silver/Gold output tables.** Use a dedicated project Lakehouse. The Silver notebook includes source-specific repairs and a fixed row-count assertion; review these before applying it to a different extract.

## Expected reconciliation for the original extract

| Check | Expected |
|---|---:|
| Silver rows | 64,353 |
| Gold cases | 48,118 |
| Gold procedures | 418 |
| Absolute deviation, case table | 2,600,928 min |
| Absolute deviation, procedure table | 2,600,928 min |
| Mean / median absolute deviation | 54.1 / 33.0 min |

See [data quality](DATA_QUALITY.md) for detailed rules. These are reference results for the original cohort, not universal expectations for new data.

## Updating the public dashboard

**Refreshing Power BI or replacing CSV exports does not update the HTML file.** The public dashboard contains a separate embedded snapshot, including grouped case-count distributions needed for exact filtered medians.

A future refresh must regenerate that embedded snapshot and reconcile the dashboard against the updated model. This repository contains the finished HTML artifact, not an automated model-to-HTML build pipeline.

## What was excluded

- Power BI `.pbi/cache.abf`: local imported data cache.
- Power BI `.pbi/localSettings.json`: personal settings.
- Power BI `.pbi/editorSettings.json`: optional editor preferences.
- Notebook outputs, execution metadata, widget state, and original workspace attachments.
- Duplicate narrative project notes, consolidated into the README and focused documentation.

**All report visuals, referenced themes, model definitions, DAX, relationships, and notebook source cells are retained.** The original local ZIP remains unchanged. Older repository revisions retain their original files in Git history; this cleanup does not rewrite history.
