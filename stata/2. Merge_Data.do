//=============================================================================
// Project: Evaluating Incentives for Delaying Pension Payouts
// Author: Marsha Teo
// Description:
// This script merges cohort-level RA balance, payout, incentive, and annuity plan data.
// It generates derived variables such as age at payout and bonus, and applies
// sample restrictions to create the final cleaned datasets.
//=============================================================================

clear all
set more off

//------------------------------------------------------------------------------
// 0. Set Global Paths
//------------------------------------------------------------------------------
global root_path "C:/path/to/project/data"
cd "$root_path"

//------------------------------------------------------------------------------
// 1. Clean variables by cohort
//------------------------------------------------------------------------------
forvalues y = 1942/1955{
	use temp\ra_ret_incentive_cohort`y', clear 
	
	//--------------------------------------------------------------------------
	// 1.1 Clean variables needed to restrict sample
	//--------------------------------------------------------------------------
    // Derive age at payout
	g latest_birth_mth = month(latest_birth_date)
	g latest_frst_pyt_date = dofm(latest_frst_pyt_ym)
	format %td latest_frst_pyt_date 
	g latest_frst_pyt_yr = year(latest_frst_pyt_date)
	g latest_frst_pyt_mth = month(latest_frst_pyt_date)
	g age_at_payout = latest_frst_pyt_yr - latest_birth_year if latest_frst_pyt_mth >= latest_birth_mth
	replace age_at_payout = latest_frst_pyt_yr - latest_birth_year - 1 if latest_frst_pyt_mth <latest_birth_mth

    // Early payout flag based on policy rules
	g early_payout = 0
	replace early_payout = 1 if latest_birth_year <= 1943 & age_at_payout <60
	replace early_payout = 1 if latest_birth_year >= 1944 & latest_birth_year <=1949 & age_at_payout <62
	replace early_payout = 1 if latest_birth_year >= 1950 & latest_birth_year <=1951 & age_at_payout <63
	replace early_payout = 1 if latest_birth_year >= 1952 & latest_birth_year <=1953 & age_at_payout <64
	replace early_payout = 1 if latest_birth_year >= 1954 & age_at_payout <65

    // Flag: dead before 2013
	g dead_before_2013 = 0
	replace dead_before_2013 = 1 if year(latest_death_date) <2013 

    // Flag: dead by age 65
	g latest_birth_day = day(latest_birth_date)
	g bday_at_65 = mdy(latest_birth_mth, latest_birth_day, latest_birth_year + 65)
	format %td bday_at_65
	g dead_by_65 = (latest_death_date < bday_at_65)

    // Merge with annuity plan data
	merge m:1 mbr_num using temp\plan_m_mbr
	drop if _merge ==2 
	g plan_mbr = (_merge ==3)
	drop _merge 

    //--------------------------------------------------------------------------
	// 1.2 Add payout related variables 
	//--------------------------------------------------------------------------
	// Potential payout start date (pps) for each cohort
	local pps = ///
        cond(inrange(`y', 1942, 1943), 60, 
        cond(inrange(`y', 1944, 1949), 62, ///
        cond(inrange(`y', 1950, 1951), 63, ///
        cond(inrange(`y', 1952, 1953), 64, ///
        cond(inrange(`y', 1954, 1955), 65, .)))))
	
	// Calculate payout months since PPS
    gen pps_dte = mdy(latest_birth_mth, latest_birth_day, latest_birth_year + `pps')
	g pps_ym = ym(latest_birth_year + 60, latest_birth_mth)
	
	g pyt_mths_since_pps = .
    replace pyt_mths_since_pps = 12 * (latest_frst_pyt_yr - year(pps_dte)) + latest_frst_pyt_mth - month(pps_dte)
    format %td pps_dte
	
	g pyt_mths_since_pps_cat = 0 if pyt_mths_since_pps ==0 
	replace pyt_mths_since_pps_cat = 1 if pyt_mths_since_pps > 0 & pyt_mths_since_pps <12
	replace pyt_mths_since_pps_cat = 2 if pyt_mths_since_pps >=12 & pyt_mths_since_pps <24
	replace pyt_mths_since_pps_cat = 3 if pyt_mths_since_pps >=24 & pyt_mths_since_pps <36
	replace pyt_mths_since_pps_cat = 4 if pyt_mths_since_pps >=36 & pyt_mths_since_pps <48
	replace pyt_mths_since_pps_cat = 5 if pyt_mths_since_pps >=48 & pyt_mths_since_pps <60
	replace pyt_mths_since_pps_cat = 6 if pyt_mths_since_pps >=60 
	
	//--------------------------------------------------------------------------
	// 1.2 Add incentive related
	//--------------------------------------------------------------------------
	// Calculate age at each incentive tranche (up to 3)
	forval i = 1(1)3{
		g age_at_incentive`i' = bonus_num`i'_year - latest_birth_year if month(bonus_num`i'_date) > month(latest_birth_date) | (month(bonus_num`i'_date) == month(latest_birth_date) & day(bonus_num1_date) >= day(latest_birth_date))
		replace age_at_incentive`i' = bonus_num`i'_year - latest_birth_year - 1 if (month(bonus_num`i'_date) < month(latest_birth_date)) | (month(bonus_num`i'_date) == month(latest_birth_date) & day(bonus_num1_date) < day(latest_birth_date))
	}
	save temp\ra_ret_incentive_cohort`y', replace
}

//------------------------------------------------------------------------------
// 2. Apply Sample Restrictions
//------------------------------------------------------------------------------
capture log close 
log using "log\sample_restrictions", replace text

forvalues y = 1942(1)1955{
	display "----------------------------------cohort `y'----------------------------------"
	use temp\ra_ret_incentive_cohort`y', clear

	* Drop if dead before 2013
	drop if dead_before_2013 == 1
	* Drop if dead before 65 years old 
	drop if dead_by_65 == 1 
	* Drop if have annuity plan
	drop if plan_mbr == 1
	* Drop if early payout
	drop if early_payout == 1 
	* Drop if foreigner 
	drop if latest_ctz == 3
	* Drop if pensionable
	drop if pnsn_mbr ==1
	* Drop if MGS member
	drop if  mgs_mbr ==1 

    // Exploratory summary
	forval i = 1(1)3{
		tab latest_birth_year age_at_incentive`i'
		tab age_at_payout age_at_incentive`i'
	}
	save temp\ra_ret_incentive_cohort`y'_restrict, replace
}

log close 
