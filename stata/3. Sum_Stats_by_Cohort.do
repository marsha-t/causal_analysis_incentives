//=============================================================================
// Project: Evaluating Incentives for Delaying Pension Payouts
// Author: Marsha Teo
// Description:
// This script generates statistics for months since pps for each cohort,
// with various sample restrictions
//=============================================================================

clear all
set more off

//------------------------------------------------------------------------------
// 0. Set Global Paths
//------------------------------------------------------------------------------
global root_path "C:/path/to/project/data"
cd "$root_path"

//------------------------------------------------------------------------------
// 1. Overall: Months between PPS and actual payout month by cohort
//------------------------------------------------------------------------------
// Those turning 70 from 2018 onwards (i.e., 1948 cohort onwards), default 70 payout start

capture log close
log using "log\sumstats_payout_mths" , replace

forval y = 1942/1955 {
    display "---------------------- cohort `y' ---------------------------"
    use temp/ra_ret_incentive_cohort`y'_restrict.dta, clear
    
    tab pyt_mths_since_pps if missing(latest_frst_pyt_yr), missing
    tab pyt_mths_since_pps, missing
    save temp/ra_ret_incentive_cohort`y'_analysis.dta, replace
}

log close

//------------------------------------------------------------------------------
// 2. Sample: Among those with positive balances at PPS
//------------------------------------------------------------------------------
// Those turning 70 from 2018 onwards (i.e., 1948 cohort onwards), default 70 payout start

use temp\bal_panel, clear
forval y = 1942/1953 {
	preserve
	keep if latest_birth_year == `y'
	
	keep mbr_num ym bal_amt 
	save temp\ra_emp_`y', replace
	restore
}

capture log close
log using "log\sumstats_payout_mths_posra (1942-1953)" , replace
forval y = 1942/1953 {
	display "---------------------- cohort `y' ---------------------------"
	use temp\ra_ret_incentive_cohort`y'_restrict, clear
	rename pps_ym ym
	format ym %tm
	merge 1:1 mbr_num ym using temp\ra_emp_`y'
	drop if _merge ==2 
	drop _merge 
	
	tab pyt_mths_since_pps if bal_amt >0, missing 
	tabstat bal_amt if bal_amt >0, by(pyt_mths_since_pps_cat)
	tabstat pyt_mths_since_pps_cat if bal_amt==.  , by(pyt_mths_since_pps_cat) stat(n)
	save temp\ra_ret_incentive_cohort`y'_analysis2, replace
}
log close
	
//------------------------------------------------------------------------------
// 3. Sample: Postive balances at PPS, 1944-45 (born Jan-Jul)
//------------------------------------------------------------------------------
log using "log\sumstats_payout_mths_posra (Jan-Jul 1944-1945)" , replace
forval y = 1944/1945 {

	display "---------------------- cohort `y' ---------------------------"
	use temp\ra_ret_incentive_cohort`y'_analysis2, clear

	keep if latest_birth_mth <8 
	tab pyt_mths_since_pps if bal_amt >0, missing 
	
	tabstat bal_amt if bal_amt >0, by(pyt_mths_since_pps_cat)
	tabstat pyt_mths_since_pps_cat if bal_amt==.  , by(pyt_mths_since_pps_cat) stat(n)
}

log close

