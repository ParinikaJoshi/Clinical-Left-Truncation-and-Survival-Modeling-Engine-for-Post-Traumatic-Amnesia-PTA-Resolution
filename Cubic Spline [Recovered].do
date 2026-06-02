*-------------------------------------------------------------------------------
* Survival Regressions for PTA Clearance (With Splines)
*
* Model 1: Staggered Entry (t=Injury)
* Model 2: Time from Admission + Linear Adjustment for Acute LOS
* Model 3: Time from Admission + CUBIC SPLINE Adjustment for Acute LOS
*-------------------------------------------------------------------------------

clear all
set more off

global data_path "\\storage.it.tamu.edu\TAMU\OAL\Homes\parinika120201\AccountSettings\Desktop"
global hw_path "\\storage.it.tamu.edu\TAMU\OAL\Homes\parinika120201\AccountSettings\Desktop\HW5"
global data_file "PTArehab_example.xlsx"

log using "$hw_path/HW5_Spline_Log.smcl", replace

import excel using "$data_path/$data_file", sheet("Dataset") firstrow clear

* Data Preparation 
gen pta_cleared = 1

* Categorical Variables
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

* CUBIC SPLINES FOR ACUTE_LOS
* 4 knots (standard default).
* new variables: los_spl1, los_spl2, los_spl3

mkspline los_spl = acute_los, cubic nknots(4) displayknots

* Staggered Entry Model
* (Time = Injury to PTA clear, Entry = Acute LOS)

stset pta_days, failure(pta_cleared) enter(acute_los)

display "--- Model 1: Staggered Entry Results ---"
stcox i.male
stcox i.age_cat
stcox i.race
stcox i.yr_cat
stcox i.drs_cat
stcox i.selfcare_cat
stcox i.mobility_cat

* Time from Rehab + LINEAR Adjustment
* (Time = Rehab to PTA clear, Adjusted for simple 'acute_los')

stset pta_dys_rehab, failure(pta_cleared)

display "--- Model 2: Linear Adjustment Results ---"
stcox i.male acute_los
stcox i.age_cat acute_los
stcox i.race acute_los
stcox i.yr_cat acute_los
stcox i.drs_cat acute_los
stcox i.selfcare_cat acute_los
stcox i.mobility_cat acute_los

* Time from Rehab + CUBIC SPLINE Adjustment
* (Time = Rehab to PTA clear, Adjusted for 'los_spl*')

display "--- Model 3: Cubic Spline Adjustment Results ---"
stcox i.male los_spl*
stcox i.age_cat los_spl*
stcox i.race los_spl*
stcox i.yr_cat los_spl*
stcox i.drs_cat los_spl*
stcox i.selfcare_cat los_spl*
stcox i.mobility_cat los_spl*


* --- Close Log ---
log close
