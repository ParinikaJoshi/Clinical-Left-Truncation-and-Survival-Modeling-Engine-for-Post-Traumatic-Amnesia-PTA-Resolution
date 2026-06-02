*******************************************************************
***** Department of Epidemiology and Biostatistics
***** Survival Analysis - Multiple Variable Adjustment
***** Student: Parinika Tusharbhai Joshi
***** Date: 26 November 2025
*******************************************************************

clear all
set more off

global data_path "\\storage.it.tamu.edu\TAMU\OAL\Homes\parinika120201\AccountSettings\Desktop"
global hw_path "\\storage.it.tamu.edu\TAMU\OAL\Homes\parinika120201\AccountSettings\Desktop\Cart"
global data_file "PTArehab_example.xlsx"

capture log close
log using "$hw_path/HW_Multivariable_Log.smcl", replace

import excel using "$data_path/$data_file", sheet("Dataset") firstrow clear

* Generate the event variable 
gen event = 1

*=====================================================================
* DATA MANAGEMENT 
*=====================================================================

* Age Categories
clonevar age_cat = age
recode age_cat (15/24=1) (25/44=2) (45/.=3)
label define age_lbl 1 "15-24" 2 "25-44" 3 ">44"
label values age_cat age_lbl

* Gender
clonevar gender = male
label define gender 1 "Male" 0 "Female"
label values gender gender

* Race
label define race_lbl 1 "White" 0 "Others"
label values race race_lbl

* Year of Onset
clonevar onset_era = onset_yr
recode onset_era (2015/2019=1) (2020/2023=2)
label define onset_era 1 "2015-2019" 2 "2020-2023"
label values onset_era onset_era

* IRF Selfcare Score 
clonevar selfcare_cat = selfcare_adm
recode selfcare_cat (7=1) (8/11=2) (12/16=3) (17/.=4)
label define selfcare_cat 1 "7" 2 "8-11" 3 "12-16" 4 ">16"
label values selfcare_cat selfcare_cat

* IRF Mobility Score
clonevar mobility_cat = mobility_adm
recode mobility_cat (15=1) (16/19=2) (20/28=3) (29/.=4)
label define mobility_cat 1 "15" 2 "16-19" 3 "20-28" 4 ">28"
label values mobility_cat mobility_cat

* DRS Score
clonevar drs_cat = drs_adm
recode drs_cat (1/13=1) (14/19=2) (20/.=3)
label define drs_cat 1 "1-13" 2 "14-19" 3 ">20"
label values drs_cat drs_cat

*=====================================================================
* Create New Risk Factor 
*
* Based on previous CART results, the "Prognostic Index" is created 
* that accounts for the interaction between Self-Care and Acute LOS.
*=====================================================================

gen pta_index = .

* Group 1: Best Prognosis (High Function, Time doesn't matter)
replace pta_index = 1 if selfcare_adm >= 17

* Group 2: Moderate Risk (Mid Function + Early Admission)
replace pta_index = 2 if (selfcare_adm >= 8 & selfcare_adm <= 16) & acute_los < 45

* Group 3: High Risk (Low Function + Early Admission)
replace pta_index = 3 if selfcare_adm == 7 & acute_los < 45

* Group 4: Worst Prognosis (Low Function + Late Admission)
replace pta_index = 4 if selfcare_adm < 17 & acute_los >= 45

label define index_lbl 1 "Group 1: Best (SC>=17)" ///
                       2 "Group 2: Mid (SC 8-16, Early)" ///
                       3 "Group 3: Poor (SC=7, Early)" ///
                       4 "Group 4: Worst (SC<17, Late)"
label values pta_index index_lbl

display "--- Step 1: Check Distribution of New Risk Factor ---"
tab pta_index, missing

*=====================================================================
* Summary Statistics
*=====================================================================

display "* STEP 2: SUMMARY STATISTICS                        *"

* Installing table1_mc
capture ssc install table1_mc

* Table 1 including the NEW pta_index variable
table1_mc, vars(age contn %9.2f \ age_cat cat \ gender cat \ race cat \ ///
                onset_era cat \ selfcare_adm contn %9.2f \ selfcare_cat cat \ ///
                mobility_adm contn %9.2f \ mobility_cat cat \ ///
                drs_adm contn %9.2f \ drs_cat cat \ pta_index cat)

*=====================================================================
* Multiple Variable Regression
* Using Staggered Entry 
* Variable reduction.
*=====================================================================

display "* STEP 3: MULTIVARIABLE REGRESSION & REDUCTION      *"

* Set Survival Data: Time from Injury (Staggered Entry)
stset pta_days, failure(event==1) entry(acute_los)

* --- 3A. Full Model ---
* 'selfcare_cat' or 'acute_los' are not included separately here (collinearity)
* because they are already built into 'pta_index'

display "--- 3A. Full Model (All Covariates + New Risk Factor) ---"
stcox i.pta_index i.age_cat i.gender i.race i.onset_era i.mobility_cat i.drs_cat

* --- 3B. Variable Reduction (Final Model) ---
* verified this by running the reduced model.

display "--- 3B. Final Reduced Model ---"
stcox i.pta_index i.mobility_cat i.drs_cat i.gender

* Check Proportional Hazards Assumption for the final model
estat phtest, detail

*=====================================================================
* Adjusted Kaplan-Meier Plot
*=====================================================================

display "* STEP 4: ADJUSTED SURVIVAL CURVES                  *"

* stcurve to plot the survival of the 4 pta_index groups
* holding the other variables (Mobility, DRS, Gender) at their means.

stcurve, survival at(pta_index=(1 2 3 4)) ///
    title("Adjusted Survival by Prognostic Index") ///
    subtitle("Adjusted for Mobility, DRS, and Gender") ///
    ytitle("Probability of Remaining in PTA") ///
    xtitle("Days from Injury") ///
    legend(label(1 "Best (High SC)") label(2 "Mid (Mid SC, Early)") ///
           label(3 "Poor (Low SC, Early)") label(4 "Worst (Low SC, Late)")) ///
    name(Adjusted_KM, replace)

graph save "$hw_path/Adjusted_KM.gph", replace
graph export "$hw_path/Adjusted_KM.pdf", replace

*=====================================================================
* Administrative Censoring
* Re-run final model censoring at 100 days POST REHAB ADMISSION.
*=====================================================================

display "* STEP 6: ADMINISTRATIVE CENSORING AT 100 DAYS      *"

* 1. Censoring time
* stop following patients 100 days after they enter rehab.
* Since our timeline is "Days from Injury", the censoring time for each person is:
* Censoring Time = (Acute LOS) + 100
gen censor_cutoff = acute_los + 100

* 2. Create new time variable
gen pta_days_censored = pta_days
* Create new event variable
gen event_censored = event

* 3. Censoring Logic
* If their total time exceeds the cutoff, cap the time and change event to 0.
replace event_censored = 0 if pta_days > censor_cutoff
replace pta_days_censored = censor_cutoff if pta_days > censor_cutoff

* 4. Re-Set Survival Data with Censored Variables
* Still using staggered entry, but with the new capped time and event.
stset pta_days_censored, failure(event_censored==1) entry(acute_los)

display "--- Check Censoring Stats ---"
stsum

* 5. Re-Run Final Model with Censored Data

display "--- Final Model with 100-Day Administrative Censoring ---"
stcox i.pta_index i.mobility_cat i.drs_cat i.gender

*=====================================================================
* Close Log
*=====================================================================
log close
