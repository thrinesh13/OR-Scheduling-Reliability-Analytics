# Power BI report source

**This folder contains the editable Power BI project, not a browser-viewable report.** To explore the finished report without installing Power BI, [open the live interactive dashboard](https://thrinesh13.github.io/OR-Scheduling-Reliability-Analytics/).

## What is here

| Item | Purpose |
|---|---|
| [`OR_Scheduling_Reliability.pbip`](OR_Scheduling_Reliability.pbip) | Project launcher for Power BI Desktop |
| [`OR_Scheduling_Reliability.Report/`](OR_Scheduling_Reliability.Report/) | Report page, visuals, interactions, and theme |
| [`OR_Scheduling_Reliability.SemanticModel/`](OR_Scheduling_Reliability.SemanticModel/) | TMDL model definitions, relationships, and DAX measures |

**The Report and SemanticModel folders must stay beside the PBIP launcher.** The report uses a relative path to the semantic model.

## How to open it

1. Download or clone the **whole repository**, not just the `.pbip` file.
2. Open `powerbi/OR_Scheduling_Reliability.pbip` in a compatible version of **Power BI Desktop**.
3. To refresh the data, connect the model to an authorized Fabric environment with the two Gold tables. The imported data cache and raw MOVER extracts are intentionally excluded.

**The public dashboard is a fixed snapshot.** It works without Fabric access, but changes to the Power BI source do not automatically update it.

For the full data pipeline and refresh steps, see [setup instructions](../docs/SETUP.md). For an explanation of the visuals and metrics, see the [dashboard guide](../docs/DASHBOARD_GUIDE.md).
