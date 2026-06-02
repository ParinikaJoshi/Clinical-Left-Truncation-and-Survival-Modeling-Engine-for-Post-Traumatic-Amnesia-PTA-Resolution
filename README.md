# Clinical Left-Truncation and Survival Modeling Engine for Post-Traumatic Amnesia (PTA) Resolution

This repository hosts a production-grade automated clinical epidemiology and biostatistics pipeline implemented in Stata. The integrated engine is engineered to model, analyze, and estimate the rate of cognitive and physical recovery—specifically the clearance of **Post-Traumatic Amnesia (PTA)**—following a traumatic brain injury (TBI). 

The core architecture directly addresses a critical methodological challenge in rehabilitation science: **time-scale alignment, immortal time bias, and left-truncation (staggered entry)**. It implements parallel survival regimes comparing time-from-admission versus time-from-injury axes, adjusts for non-linear care transitions using restricted cubic splines, evaluates a conditional Classification and Regression Trees (CART) Prognostic Index, and handles data-driven confounding cascades.

---

## Analytical Architecture and Execution Phases

The framework processes raw inpatient electronic health records through four sequential execution layers:

### 1. Alternative Time-Scale Alignment and Left-Truncation (Staggered Entry)
A fundamental selection bias occurs when analyzing rehabilitation milestones if the survival clock starts at clinical admission while ignoring the variable acute care period. The pipeline evaluates three baseline survival frameworks to handle this:
* **Model 1 (Admission Time-Scale):** Analysis clock starts at zero ($t = 0$) on the day of rehabilitation admission. Follow-up spans `pta_dys_rehab`.
* **Model 2 (Injury Time-Scale via Staggered Entry):** Analysis clock begins at the true calendar physiological origin ($t = 0$ at the moment of injury). Follow-up spans `pta_days`. Patients are explicitly treated as *left-truncated*, entering the risk set at a staggered interval defined by their acute length of stay (`acute_los`). This completely mitigates **immortal time bias**.
* **Model 3 (Linear & Spline Conditional Models):** Keeps the baseline clock at admission time but adjusts for the acute phase dynamically.
