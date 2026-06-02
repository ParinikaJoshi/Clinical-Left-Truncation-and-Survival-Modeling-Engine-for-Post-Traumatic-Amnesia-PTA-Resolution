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

### 2. Flexible Non-Linear Boundary Smoothing
To avoid assuming that the risk associated with delayed rehabilitation entry is purely linear, the pipeline uses the `mkspline` engine to implement restricted cubic splines. It generates 4 knots positioned across the sample percentiles of `acute_los`, generating piece-wise basis functions (`los_spl1`, `los_spl2`, `los_spl3`) that map non-linear biological trends within Cox Proportional Hazards structures.

### 3. Interaction Modeling and CART-Derived Classification Index
The framework implements a categorical **Prognostic Index Matrix** derived from conditional tree-based partitioning (CART). This index groups patients into distinct risk profiles based on the interaction between initial cognitive/physical presentation and system delays:
* **Group 1 (Optimal Prognosis):** High-functioning independence profile ($\text{Self-Care Admission Score} \ge 17$).
* **Group 2 (Intermediate Risk):** Moderate functionality ($\text{Self-Care Score } 8\text{ to } 16$) paired with rapid stabilization ($\text{Acute Care Phase} < 45\text{ days}$).
* **Group 3 (Severe/High Risk):** Complete dependence ($\text{Self-Care Score} = 7$) paired with rapid stabilization ($\text{Acute Care Phase} < 45\text{ days}$).
* **Group 4 (Critical/Worst Prognosis):** Impaired clinical functionality ($\text{Self-Care Score} < 17$) combined with prolonged acute system delays ($\text{Acute Care Phase} \ge 45\text{ days}$).

### 4. Bivariate Confounding Cascades and Automated Model Pruning
The pipeline uses a strict $10\%$ coefficient shift rule ($|\beta_{\text{Crude}} - \beta_{\text{Adjusted}}| / |\beta_{\text{Crude}}| \times 100 > 10$) to screen for true confounders across baseline characteristics. Model optimization is driven by automated downward stepwise elimination (`stepwise, pr(0.05)`). Global and parameter-specific proportional hazards assumptions are validated using Schoenfeld residual score tests (`estat phtest`).

---

## Data Dictionary and Engineering Matrix

The pipeline reads clinical observation matrices containing demographic details, temporal factors, and Functional Independence Measure (FIM) items:

* **Temporal Tracking Metrics (Outcomes and Clocks):**
  * `pta_dys_rehab`: Continuous measure tracking total days elapsed from rehabilitation admission to clear PTA resolution.
  * `pta_days`: Continuous measure tracking total days elapsed from initial traumatic injury to clear PTA resolution.
  * `acute_los`: Left-truncation metric tracking days spent in acute care prior to rehabilitation admission.
  * `onset_yr` / `yr_cat`: Year of traumatic incident tracking structural changes across clinical eras ($2015\text{--}2019$ vs. $2020\text{--}2023$).

* **Clinical Exposure Profiles:**
  * `selfcare_adm` / `self_cat`: Baseline self-care index spanning complete functional dependence ($\text{Score} \le 7$) up to independent functional status ($\text{Score} \ge 17$).
  * `mobility_adm` / `mob_cat`: Baseline physical mobility score tracking transfer capabilities ranging from restricted mobility ($\text{Score} \le 15$) up to full functional mobility ($\text{Score} \ge 29$).
  * `drs_adm` / `drs_cat`: Disability Rating Scale index tracking severe structural deficits ($\text{Score} \ge 20$) down to minor cognitive deficits ($\text{Score} \le 13$).

* **Socio-Demographic Controls:**
  * `male` / `gender`: Binary demographic category ($1$ = Male, $0$ = Female).
  * `race`: Categorical indicator mapping patient ancestry ($1$ = White, $0$ = Other groups).
  * `age` / `age_cat`: Age at injury categorized into distinct lifecourse brackets ($15\text{--}24$, $25\text{--}44$, $\ge 45$ years).

---

## System Requirements and Deployment Path

This code framework is written for Stata version 15.0 or higher. The pipeline utilizes native survival commands (`stset`, `stcox`, `stcurve`) and integrates the external package `table1_mc` for automated baseline demographic reporting.

### Operational Deployment Steps

#### 1. Configure System Pointers
Before running the scripts, change the global path variables to point to your data directory, cluster volume, or local project folder:

```stata
global data_path "YOUR_VOLUME:/Path/To/Your/Data/Volume"
global hw_path   "YOUR_VOLUME:/Path/To/Your/Active/Workspace"
global data_file "patient_dataset_v2_PTArehab.xlsx"
