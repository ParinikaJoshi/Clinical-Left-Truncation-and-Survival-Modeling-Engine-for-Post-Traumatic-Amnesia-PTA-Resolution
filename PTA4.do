*-------------------------------------------------------------------------------
* FINAL EXAM: Survival Analysis of PTA Clearance
* Student Name: Parinika Tusharbhai Joshi
*-------------------------------------------------------------------------------

clear all
set more off

global data_path "\\storage.it.tamu.edu\TAMU\OAL\Homes\parinika120201\AccountSettings\Desktop\Final Exam"
global data_file "\\storage.it.tamu.edu\TAMU\OAL\Homes\parinika120201\AccountSettings\Desktop\Final Exam\patient_dataset_v2_PTArehab.xlsx"
global log_file  "$data_path\FinalExam_Log_Categorical_All.smcl"

capture log close
log using "$log_file", replace

import excel using "$data_file", firstrow clear

*===============================================================================
* PART A: DATA PREPARATION & CENSORING
*===============================================================================

* Event Variable
gen event = 1
label variable event "PTA Cleared Status"

* Administrative Censoring at 120 Days
replace event = 0 if pta_days > 120
replace pta_days = 120 if pta_days > 120

* Staggered Entry logic errors
drop if acute_los >= 120

* Survival Data 
stset pta_days, failure(event==1) enter(acute_los)

stsum

*===============================================================================
* PART B: VARIABLE ENGINEERING 
*===============================================================================

* Age
mkspline age_sp = age, cubic nknots(3)
gen age_cat = .
replace age_cat = 1 if age <= 24
replace age_cat = 2 if age >= 25 & age <= 44
replace age_cat = 3 if age > 44
label define age_lbl 1 "15-24" 2 "25-44" 3 ">44"
label values age_cat age_lbl

* Mobility
xtile mob_check = irf_mob_adm, nq(4) 
gen mob_cat = .
replace mob_cat = 1 if irf_mob_adm <= 15
replace mob_cat = 2 if irf_mob_adm >= 16 & irf_mob_adm <= 19
replace mob_cat = 3 if irf_mob_adm >= 20 & irf_mob_adm <= 28
replace mob_cat = 4 if irf_mob_adm >= 29
label define mob_lbl 1 "Score 15" 2 "Score 16-19" 3 "Score 20-28" 4 "Score 29+"
label values mob_cat mob_lbl

* Self-Care 
gen self_cat = .
replace self_cat = 1 if irf_self_adm <= 7
replace self_cat = 2 if irf_self_adm >= 8 & irf_self_adm <= 11
replace self_cat = 3 if irf_self_adm >= 12 & irf_self_adm <= 16
replace self_cat = 4 if irf_self_adm >= 17
label define self_lbl 1 "Score 7" 2 "Score 8-11" 3 "Score 12-16" 4 "Score 17+"
label values self_cat self_lbl

* DRS 
mkspline drs_sp = drs_adm, cubic nknots(3)
gen drs_cat = .
replace drs_cat = 1 if drs_adm <= 13
replace drs_cat = 2 if drs_adm >= 14 & drs_adm <= 19
replace drs_cat = 3 if drs_adm >= 20
label define drs_lbl 1 "Score 1-13" 2 "Score 14-19" 3 "Score 20+"
label values drs_cat drs_lbl

* Onset Year 
gen yr_cat = .
replace yr_cat = 1 if onset_yr <= 2019
replace yr_cat = 2 if onset_yr >= 2020
label define yr_lbl 1 "2015-2019" 2 "2020-2023"
label values yr_cat yr_lbl

*===============================================================================
* PART C: UNIVARIATE ANALYSES (CATEGORICAL)
*===============================================================================

* Loop through all variables 
local all_cats male i.age_cat race i.yr_cat i.drs_cat i.self_cat i.mob_cat

foreach var of local all_cats {
    display ""
    display "--- Univariate Model: `var' ---"
    stcox `var'
    estat phtest, detail
}

*===============================================================================
* PART D: BIVARIATE ANALYSIS 
*===============================================================================

* Crude Association 
stcox irf_mob_adm
scalar crude_coef = _b[irf_mob_adm]

* Confounding and Interaction
* Continuous versions here just to see the % change accurately
local covariates male age race onset_yr drs_adm irf_self_adm

foreach var of local covariates {
    display "--------------------------------------------------"
    display "CHECKING VARIABLE: `var'"
    
    * Confounding
    quietly stcox irf_mob_adm `var'
    scalar adj_coef = _b[irf_mob_adm]
    scalar pct_change = abs((crude_coef - adj_coef) / crude_coef) * 100
    
    display "Confounding Check:"
    display "  % Change: " pct_change "%"
    if pct_change > 10 {
        display "  -> CONCLUSION: `var' IS A CONFOUNDER."
    }

    * Interaction
    display "Interaction Check (with Categorical Mobility):"
    
    if "`var'" == "male" | "`var'" == "race" {
        stcox i.mob_cat##i.`var'
    }
    else {
        stcox i.mob_cat##c.`var'
    }
    display "  -> INSTRUCTION: Look for significant interaction terms."
}

*===============================================================================
* PART E: Full Model 
*===============================================================================

stcox i.male i.age_cat i.race i.yr_cat i.drs_cat i.self_cat i.mob_cat

*===============================================================================
* PART F: Best Models
*===============================================================================

stepwise, pr(0.05): stcox i.male i.age_cat i.race i.yr_cat i.drs_cat i.self_cat i.mob_cat

stcox i.mob_cat i.drs_cat i.self_cat i.age_cat
est store best_mob_model

*===============================================================================
* PART G: KAPLAN-MEIER PLOTS
*===============================================================================

* Unadjusted Plot 
sts graph, by(mob_cat) ///
    title("Unadjusted Kaplan-Meier Estimates") ///
    subtitle("Stratified by Mobility Categories") ///
    xtitle("Days from Onset") ytitle("Probability of Remaining in PTA") ///
    name(Unadj_KM, replace)
graph save "$data_path\Unadj_KM.gph", replace

* Adjusted Plot 
* 4 Mobility curves, holding Age, DRS, Self-Care at their reference (Group 1)
* OR at their means. 

stcox i.mob_cat i.drs_cat i.self_cat i.age_cat

stcurve, survival at1(mob_cat=1) at2(mob_cat=2) at3(mob_cat=3) at4(mob_cat=4) ///
    title("Adjusted Survival Curves (Cox Model)") ///
    subtitle("Adjusted for Age, DRS, and Self-Care Categories") ///
    legend(label(1 "Score 15") label(2 "Score 16-19") label(3 "Score 20-28") label(4 "Score 29+")) ///
    xtitle("Days from Onset") ytitle("Probability of Remaining in PTA") ///
    name(Adj_KM, replace)
graph save "$data_path\Adj_KM.gph", replace

* PH Test for Final Model 
display "Checking PH Assumption for Final Model..."
estat phtest, detail

log close

