*-------------------------------------------------------------------------------
* Simple Survival Regressions for PTA Clearance

* 1. Model 1: Time starts at rehab admission (t=0 at admission).
* 2. Model 2: Time starts at injury (staggered entry).
*
*-------------------------------------------------------------------------------

clear all
set more off

global data_path "\\storage.it.tamu.edu\TAMU\OAL\Homes\parinika120201\AccountSettings\Desktop"
global hw_path "\\storage.it.tamu.edu\TAMU\OAL\Homes\parinika120201\AccountSettings\Desktop\HW5"
global data_file "PTArehab_example.xlsx"

log using "$hw_path/HW5_log.smcl", replace

import excel using "$data_path/$data_file", sheet("Dataset") firstrow clear

gen pta_cleared = 1

gen age_cat = .
replace age_cat = 1 if age >= 15 & age <= 24
replace age_cat = 2 if age >= 25 & age <= 44
replace age_cat = 3 if age >= 45 & age < .
label define age_lbl 1 "15-24" 2 "25-44" 3 "45+"
label values age_cat age_lbl

gen yr_cat = .
replace yr_cat = 1 if onset_yr >= 2015 & onset_yr <= 2017
replace yr_cat = 2 if onset_yr >= 2020 & onset_yr <= 2023
label define yr_lbl 1 "2015-2017" 2 "2020-2023"
label values yr_cat yr_lbl

gen selfcare_cat = .
replace selfcare_cat = 1 if selfcare_adm == 7
replace selfcare_cat = 2 if selfcare_adm >= 8 & selfcare_adm <= 11
replace selfcare_cat = 3 if selfcare_adm >= 12 & selfcare_adm <= 16
replace selfcare_cat = 4 if selfcare_adm >= 17 & selfcare_adm < .
label define selfcare_lbl 1 "Score 7" 2 "Score 8-11" 3 "Score 12-16" 4 "Score 17+"
label values selfcare_cat selfcare_lbl

gen mobility_cat = .
replace mobility_cat = 1 if mobility_adm == 15
replace mobility_cat = 2 if mobility_adm >= 16 & mobility_adm <= 19
replace mobility_cat = 3 if mobility_adm >= 20 & mobility_adm <= 28
replace mobility_cat = 4 if mobility_adm >= 29 & mobility_adm < .
label define mobility_lbl 1 "Score 15" 2 "Score 16-19" 3 "Score 20-28" 4 "Score 29+"
label values mobility_cat mobility_lbl

gen drs_cat = .
replace drs_cat = 1 if drs_adm >= 1 & drs_adm <= 13
replace drs_cat = 2 if drs_adm >= 14 & drs_adm <= 19
replace drs_cat = 3 if drs_adm >= 20 & drs_adm < .
label define drs_lbl 1 "Score 1-13" 2 "Score 14-19" 3 "Score 20+"
label values drs_cat drs_lbl

global covariates "male age race onset_yr drs_adm selfcare_adm mobility_adm"
global covariates "i.male i.age_cat i.race i.yr_cat i.drs_adm i.selfcare_adm i.mobility_adm"

*===============================================================================
* MODEL 1: Time starts at Rehab Admission
*
* Analysis time (t) = pta_dys_rehab (days from rehab admission to PTA clear)
* Event = pta_cleared (everyone has the event)
* Origin (t=0) = Rehab admission
*===============================================================================

stset pta_dys_rehab, failure(pta_cleared)

display ""
display "--- Model 1: Univariate Cox Regression for male ---"
stcox i.male

display ""
display "--- Model 1: Univariate Cox Regression for age_cat ---"
stcox i.age_cat

display ""
display "--- Model 1: Univariate Cox Regression for race ---"
stcox i.race

display ""
display "--- Model 1: Univariate Cox Regression for yr_cat ---"
stcox i.yr_cat

display ""
display "--- Model 1: Univariate Cox Regression for drs_cat ---"
stcox i.drs_cat

display ""
display "--- Model 1: Univariate Cox Regression for selfcare_cat ---"
stcox i.selfcare_cat

display ""
display "--- Model 1: Univariate Cox Regression for mobility_cat ---"
stcox i.mobility_cat

*===============================================================================
* MODEL 2: Time starts at Injury (Staggered Entry)
*
* Analysis time (t) = Time from injury
* Event = pta_cleared (everyone has the event)
* Origin (t=0) = Injury
* Entry time = acute_los (days from injury to rehab admission)
* Exit time = pta_days (days from injury to PTA clear)
*===============================================================================

stset pta_days, failure(pta_cleared) enter(acute_los)

display ""
display "--- Model 2: Univariate Cox Regression for male (Staggered Entry) ---"
stcox i.male

display ""
display "--- Model 2: Univariate Cox Regression for age_cat (Staggered Entry) ---"
stcox i.age_cat

display ""
display "--- Model 2: Univariate Cox Regression for race (Staggered Entry) ---"
stcox i.race

display ""
display "--- Model 2: Univariate Cox Regression for yr_cat (Staggered Entry) ---"
stcox i.yr_cat

display ""
display "--- Model 2: Univariate Cox Regression for drs_cat (Staggered Entry) ---"
stcox i.drs_cat

display ""
display "--- Model 2: Univariate Cox Regression for selfcare_cat (Staggered Entry) ---"
stcox i.selfcare_cat

display ""
display "--- Model 2: Univariate Cox Regression for mobility_cat (Staggered Entry) ---"
stcox i.mobility_cat


*===============================================================================
* COMPARISON FOR MODEL 3: Adjusted Survival Plots acute_los
*===============================================================================

stset pta_dys_rehab, failure(pta_cleared)

stcox i.male acute_los

stcox i.age_cat acute_los

stcox i.race acute_los

stcox i.yr_cat acute_los

stcox i.drs_cat acute_los

stcox i.selfcare_cat acute_los

stcox i.mobility_cat acute_los

*===============================================================================
* MODEL 1 (Continuous): Time starts at Rehab Admission
*===============================================================================

stset pta_dys_rehab, failure(pta_cleared)

display ""
display "--- Model 1: Univariate Cox Regression for male ---"
stcox male

display ""
display "--- Model 1: Univariate Cox Regression for age ---"
stcox age

display ""
display "--- Model 1: Univariate Cox Regression for race ---"
stcox race

display ""
display "--- Model 1: Univariate Cox Regression for onset_yr ---"
stcox onset_yr

display ""
display "--- Model 1: Univariate Cox Regression for drs_adm ---"
stcox drs_adm

display ""
display "--- Model 1: Univariate Cox Regression for selfcare_adm ---"
stcox selfcare_adm

display ""
display "--- Model 1: Univariate Cox Regression for mobility_adm ---"
stcox mobility_adm

*===============================================================================
* MODEL 2 (Continuous): Time starts at Injury (Staggered Entry)
*===============================================================================

stset pta_days, failure(pta_cleared) enter(acute_los)

display ""
display "--- Model 2: Univariate Cox Regression for male (Staggered Entry) ---"
stcox male

display ""
display "--- Model 2: Univariate Cox Regression for age (Staggered Entry) ---"
stcox age

display ""
display "--- Model 2: Univariate Cox Regression for race (Staggered Entry) ---"
stcox race

display ""
display "--- Model 2: Univariate Cox Regression for onset_yr (Staggered Entry) ---"
stcox onset_yr

display ""
display "--- Model 2: Univariate Cox Regression for drs_adm (Staggered Entry) ---"
stcox drs_adm

display ""
display "--- Model 2: Univariate Cox Regression for selfcare_adm (Staggered Entry) ---"
stcox selfcare_adm

display ""
display "--- Model 2: Univariate Cox Regression for mobility_adm (Staggered Entry) ---"
stcox mobility_adm

*===============================================================================
* MODEL 3 (Continuous): Time at Rehab, controlling for acute_los
*===============================================================================

stset pta_dys_rehab, failure(pta_cleared)

display ""
display "--- Model 3: Cox Regression for male (controlling for acute_los) ---"
stcox male acute_los

display ""
display "--- Model 3: Cox Regression for age (controlling for acute_los) ---"
stcox age acute_los

display ""
display "--- Model 3: Cox Regression for race (controlling for acute_los) ---"
stcox race acute_los

display ""
display "--- Model 3: Cox Regression for onset_yr (controlling for acute_los) ---"
stcox onset_yr acute_los

display ""
display "--- Model 3: Cox Regression for drs_adm (controlling for acute_los) ---"
stcox drs_adm acute_los

display ""
display "--- Model 3: Cox Regression for selfcare_adm (controlling for acute_los) ---"
stcox selfcare_adm acute_los

display ""
display "--- Model 3: Cox Regression for mobility_adm (controlling for acute_los) ---"
stcox mobility_adm acute_los

log close
