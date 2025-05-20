//=============================================================================
// Project: Evaluating Incentives for Delaying Pension Payouts
// Author: Marsha Teo
// Description: 
// This script imports required data for this study. 
// Data is often in panel form and relatively large. 
// Hence, in some cases, they are cleaned separately (in later do files) before being combined together
// The data was extracted in SAS.
//=============================================================================

clear all
set more off

//------------------------------------------------------------------------------
// 0. Set Global Paths
//------------------------------------------------------------------------------
global root_path "C:/path/to/project/data"
cd "$root_path"

//------------------------------------------------------------------------------
// 1. Import Incentive Transaction Data 
//------------------------------------------------------------------------------
// Contains info on whether individual receive the incentive and frequency of receiving the incentive
import delimited .\clean\incentive_txn.csv, clear 
save .\raw\incentive_txn.dta, replace

//------------------------------------------------------------------------------
// 2. Import Quaterly Balance Data 
//------------------------------------------------------------------------------
// Contains demographic and balance data

// Loop to import and save quarterly data
forval year = 2002(1)2018 {
	forval qtr = 1(1)4 {
		import delimited .\clean\bal_`year'_`qtr'.csv, clear 
		save raw\bal_`year'_`qtr'.dta, replace 
	}
}

//------------------------------------------------------------------------------
// 3. Import Pension Payout Data 
//------------------------------------------------------------------------------
// Contains info on outcome: payout start/deferment
forval year = 2013(1)2018 {
	import delimited .\clean\ret_`year'.csv, clear 
save raw\ret_`year'.dta, replace 

// Combine data
use temp\ret_2013, clear
forval year = 2014(1)2018 {
	append using temp\ret_`year'
	}
save temp\ret_m, replace

//------------------------------------------------------------------------------
// 4. Import Annuity Plan Data 
//------------------------------------------------------------------------------
// Contains info on eligibility: those with annuity plans are not suitable for this study

// Import annuity plan data 
forval year = 2013(1)2018 {
	import delimited .\clean\plan_`year'.csv, clear varnames(1)
	save raw\plan_`year'.dta, replace 
}
// As data is relatively small, possible to combine dataset
use raw\plan_2013, clear
forval year = 2014/2018 {
	append using raw\plan_`year'
}
save temp\plan_m, replace

// Generate unique list of members who have annuity plans
use temp\plan_m, clear
drop perd_id
duplicates drop 
save temp\plan_m_mbr, replace

//------------------------------------------------------------------------------
// 5. Import Quarterly Wage Data 
//------------------------------------------------------------------------------
// Contains data on wages by month
forval y = 2002/2018 { 
	forval q = 1(1)4{
		import delimited "clean\wg_`y'_`q'.csv", clear
		save raw\wg_`y'_`q'.dta, replace
	}
}

//------------------------------------------------------------------------------
// 6. Import Medical Bill Data 
//------------------------------------------------------------------------------
forval y = 2002/2018 {
	forval h = 1/2{
		import delimited "clean\med_`y'_`h'.csv", clear
		save raw\med`y'_`h'.dta, replace
	}	
}

