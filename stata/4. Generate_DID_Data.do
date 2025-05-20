//=============================================================================
// Project: Evaluating Incentives for Delaying Pension Payouts
// Author: Marsha Teo
// Description:
// This script generates the dataset for the DiD analysis where the data is restricted
// to those born in Jan-Jul in 1944 (control) and 1945 (treatment)
//=============================================================================

clear all
set more off

//------------------------------------------------------------------------------
// 0. Set Global Paths
//------------------------------------------------------------------------------
global root_path "C:/path/to/project/data"
cd "$root_path"

//------------------------------------------------------------------------------
// 1944 v 1945 Cohort 
//------------------------------------------------------------------------------
// Medical 
use temp\med_4249_cohort, clear
keep if latest_birth_year == 1944 | latest_birth_year == 1945
keep mbr_num ym lastyr_med tot_bill
save temp\med_4445_analysis, replace

// RA Balance and Emp Status
use temp\bal_panel, clear
keep if latest_birth_year == 1944 | latest_birth_year == 1945
keep mbr_num ym bal_amt emp_status bal_quant
save temp\ra_emp_4445_analysis, replace
	
// Wage 
use temp\wg_4249_cohort, clear
keep if latest_birth_year == 1944 | latest_birth_year == 1945
keep mbr_num ym wage2 
save temp\wg_4445_analysis, replace

// Generate analysis dataset
use temp\ra_ret_incentive_cohort1944_analysis, clear
append using temp\ra_ret_incentive_cohort1945_analysis

keep if latest_birth_mth <8

** Treat Variable 
g treat = 1 if latest_birth_year == 1945
replace treat = 0 if latest_birth_year == 1944

forval x = 1(1)7	{
	local y = 20-`x'
	display "`y'"
	expand `y' if latest_birth_mth == `x' 
}

bys mbr_num: g dup = _N
tab dup latest_birth_mth
drop dup 

bys mbr_num: g temp = _n
g mth_since_pps = temp -1 

** Corresponding ym 	
g mth = mth_since_pps + latest_birth_mth

g yr = 2006 if latest_birth_year == 1944 & mth <=12
replace yr = 2007 if latest_birth_year == 1944 & mth >12
replace yr = 2007 if latest_birth_year == 1945 & mth <=12
replace yr = 2008 if latest_birth_year == 1945 & mth >12

replace mth = mth - 12 if mth > 12
	
g ym = ym(yr, mth)
format ym %tm
** Covariates
	//Medical bill in past 12 months
	merge 1:1 mbr_num ym using temp\med_4445_analysis
	drop if _merge == 2
	replace lastyr_med = 0 if lastyr_med == . 
	rename _merge merge_med
	// Wages
	merge 1:1 mbr_num ym using temp\wg_4445_analysis
	drop if _merge == 2
	replace wage2 = 0 if wage2 <0 | wage2==. 
	rename _merge merge_wg
	
	// RA Balance and Emp Status
	merge 1:1 mbr_num ym using temp\ra_emp_4445_analysis
	drop if _merge == 2 
	rename _merge merge_ra_emp
	sum bal_amt, detail
	replace bal_amt = . if bal_amt == 0 
	
	// Keep if balance is positive at PPS
	g pos_ra = (bal_amt !=. & mth_since_pps == 0 )
	bys mbr_num: egen pos_ra_max = max(pos_ra)
	
	keep if pos_ra_max == 1 
	
** Post Variable
	g post = 0 
	replace post = 1 if latest_birth_mth == 1 &  mth_since_pps >=7 
	replace post = 1 if latest_birth_mth == 2 &  mth_since_pps >=6 
	replace post = 1 if latest_birth_mth == 3 &  mth_since_pps >=5 
	replace post = 1 if latest_birth_mth == 4 &  mth_since_pps >=4 
	replace post = 1 if latest_birth_mth == 5 &  mth_since_pps >=3 
	replace post = 1 if latest_birth_mth == 6 &  mth_since_pps >=2 
	replace post = 1 if latest_birth_mth == 7 &  mth_since_pps >=1 
	
	g post_ym_first =  0 
	replace post_ym_first = 7 if latest_birth_mth == 1
	replace post_ym_first = 6 if latest_birth_mth == 2
	replace post_ym_first = 5 if latest_birth_mth == 3
	replace post_ym_first = 4 if latest_birth_mth == 4
	replace post_ym_first = 3 if latest_birth_mth == 5
	replace post_ym_first = 2 if latest_birth_mth == 6
	replace post_ym_first = 1 if latest_birth_mth == 7
	
	gen mth_since_announce = mth_since_pps - post_ym_first
	g mth_since_announce_7is0 = mth_since_announce+7 

* Placebo Variable
forval neg = 1(1)3 {
	g placebo_mth_b4_`neg' = 0

	forval mth = 1(1)7 {
		replace placebo_mth_b4_`neg' = 1 if latest_birth_mth == `mth' &  mth_since_pps == 8 - `mth' - `neg'
	}
	replace placebo_mth_b4_`neg' = . if placebo_mth_b4_`neg' <0
}

** Outcome Variable: Pr(defer/start)
	g start = 0 
	replace start = 0
	replace start = 1 if pyt_mths_since_pps <= mth_since_pps
		
egen new_id = group(mbr_num)
xtset new_id mth_since_pps

save temp\did_4445, replace
	