# OR Scheduling Reliability & Cost Exposure

**This is an end-to-end data analytics project exploring how historical data can be used to
make Operating Room (OR) scheduling more reliable.** Built on Microsoft Fabric from raw data
through to a published Power BI report, covering 48,118 surgical cases across 418 procedures.

![Dashboard overview](OR_OVERVIEW.png)

## Business case

The OR is one of a hospital's most important assets. It drives a large share of hospital
revenue, but it's also one of the most expensive and tightly constrained resources on site,
every room is staffed, equipped, and scheduled down to the minute, and there are only so many
rooms and hours in a day.

That makes scheduling accuracy matter more than it might in most other settings. When a case
runs longer than expected, the next case gets delayed, staff stay late, and the ripple effect
can push an entire day's schedule off track. When a case finishes earlier than expected, the
room sits idle, staffed and paid for, but unused. Both situations are common. Neither is free.
Most hospitals only track the first one.

## Business value

This project puts a number on a problem that's usually only discussed anecdotally. It shows
that OR scheduling misses its mark, in either direction, on more than half of all cases, and
it prices what that adds up to across a year. That single reframe, treating early finishes as
a real cost alongside overruns, is what turns "surgery sometimes runs late" into a measurable,
year-round operational cost that leadership can actually size and act on.

## What this analysis does, and how it helps

This analysis builds a historical benchmark for how long each procedure typically takes, then
measures how far every individual case falls from that benchmark, in both directions. From
there, it identifies which procedures are the least predictable and the most worth a closer
look, and roughly what the inaccuracy is costing.

**This helps stakeholders:**

- **OR operations and scheduling teams** know which procedures to prioritize for a scheduling
  review first, instead of reviewing all 418 equally or going by instinct.
- **Perioperative and service-line leaders** see the problem sized and split by cause, so they
  can judge whether a fix belongs in scheduling policy, in specific block times, or elsewhere.
- **Hospital leadership** gets a defensible, scenario-based estimate of what scheduling
  inaccuracy costs annually, useful for prioritizing this kind of improvement work against
  other initiatives competing for the same attention.

This is a decision-support tool. It's built to tell a team where to look and roughly what's at
stake, not to claim a fix has already been made or that a specific dollar figure will be
recovered, the data behind it doesn't support a claim that strong, and the project is upfront
about that rather than overselling it.

## The data

Built from the [MOVER dataset](https://mover.ics.uci.edu/) (Medical Informatics Operating Room
Vitals and Events Repository), a de-identified, HIPAA-compliant, IRB-approved collection of
real perioperative records from the University of California, Irvine Medical Center. This
project uses four tables covering patient information, procedure history, procedure events,
and post-operative complications, spanning roughly 5.75 years of surgical cases.

> Samad M, Angel M, Rinehart J, Kanomata Y, Baldi P, Cannesson M. *Medical Informatics
> Operating Room Vitals and Events Repository (MOVER): a public-access operating room
> database.* JAMIA Open, 2023. DOI: [10.1093/jamiaopen/ooad084](https://doi.org/10.1093/jamiaopen/ooad084)

The raw data required substantial cleaning before it could be trusted, duplicate records,
corrupted timestamps, and inconsistent procedure naming all had to be found and resolved.
That process is documented in full in the project's notebooks for anyone who wants the detail;
this README stays focused on what the cleaned data shows.

## Findings

- **OR scheduling misses its mark on more than half of all cases.** Only about 47% of cases
  land within 30 minutes of what history would predict. The rest split almost evenly between
  running significantly over and finishing significantly early.
- **The two directions of error are roughly the same size**, which wasn't previously visible
  when only overruns were tracked. Cases that finish early are just as common as cases that
  run long, and an idle staffed room is a real cost, not a win.
- **The estimated cost of this gap is substantial**, somewhere between $15.8M and $27.1M a
  year depending on assumptions, and that's before accounting for downstream effects like
  delayed cases and staff overtime.
- **The problem isn't concentrated in a handful of procedures.** It's spread broadly across
  the surgical caseload, which means a small, targeted fix won't solve most of it, this needs
  a systematic review process, not a one-time patch on a few outliers.
- **The scheduling benchmark itself holds up under scrutiny.** These findings didn't change
  even after the data was checked and re-checked for quality issues, which means the pattern
  is real, not an artifact of messy data.

## Recommendations and limitations

**Recommended next step:** use the dashboard's prioritization view to identify the procedures
that are both high-volume and unpredictable, and start a scheduling review there, since that's
where a change would have the largest measurable effect.

**What this analysis can't do, and why:**

- It compares actual case time against a procedure's own history, not against what was
  originally scheduled or booked, that information wasn't available in the source data. It
  measures predictability, not schedule adherence.
- It has no way to test whether a fix works, since the data doesn't include a period after any
  change was made. It identifies the opportunity, it doesn't measure a result.
- It can't yet say why specific procedures are unpredictable, patient risk level, anesthesia
  type, or case type may all play a role, but those relationships haven't been tested yet.

## Future scope

- Test whether patient risk level, anesthesia type, or inpatient/outpatient status explain why
  some procedures are harder to predict than others.
- Compare actual case time against real booked schedule times, if that data ever becomes
  available, moving from "how predictable is this" to "how accurate was the schedule."
- Let a viewer adjust the assumed cost-per-minute interactively instead of reading two fixed
  scenarios.
- Extend to department- or service-line-level access controls if this moves toward everyday
  operational use.

## Project structure

```
01_bronze_ingest.ipynb                Raw data ingestion, no transformation
02_silver_patient_information.ipynb   Cleaning, repair, and validation
03_gold.ipynb                         Analytical tables: procedure benchmarks and case-level deviation
OR_Scheduling_Reliability.pbip        Power BI report and semantic model
DASHBOARD_GUIDE.md                    How to read the report
PROJECT_NOTES.md                      Full technical detail: every measure, its logic, and build limitations
OR_OVERVIEW.png                       Report screenshot
```

## Tech stack

Microsoft Fabric (Lakehouse, PySpark, Spark SQL, Delta Lake), Power BI Desktop (Import-mode
semantic model, DAX), Fabric SQL analytics endpoint.
