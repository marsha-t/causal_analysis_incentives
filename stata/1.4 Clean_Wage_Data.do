//=============================================================================
// Project: Evaluating Incentives for Delaying Pension Payouts
// Author: Marsha Teo
// Description:
// This script processes quarterly wage data (2002–2018) for the 1942-49 cohort,
// and computes total wages per member-period.
//=============================================================================

clear all
set more off

//------------------------------------------------------------------------------
// 0. Set Global Paths
//------------------------------------------------------------------------------
global root_path "C:/path/to/project/data"
cd "$root_path"

//------------------------------------------------------------------------------
// 1. Process Quarterly Wage Data
//------------------------------------------------------------------------------
forval y = 2002/2018 { 
	forval q = 1(1)4{
		use raw\wg_`y'_`q'.dta, clear
		
		// Aggregate wage and keep unique entry per mbr_num x con_rm
		bys mbr_num con_rm: egen wage = total(wge_amt)
		bys mbr_num con_rm : g tag = (_n==1)
		keep if tag == 1
		keep mbr_num con_rm wage		

		// Filter to use only 1942-49 cohort
		merge m:1 mbr_num using temp\mbrlist_1942_1949
		keep if _merge == 3
		save temp\wg_`y'_`q', replace
	}
}

//------------------------------------------------------------------------------
// 2. Combine All Quarters into Single Panel
//------------------------------------------------------------------------------
use temp\wg_2002_1, clear
forval q = 2(1)4{
	append using temp\wg_2002_`q'
}
forval y = 2003(1)2018 {
	forval q = 1(1)4{
		append using temp\wg_`y'_`q'
	}
}
	
drop _merge

//------------------------------------------------------------------------------
// 3. Clean dataset and variables
//------------------------------------------------------------------------------

// Remove contributions earlier than 2002
drop if con_rm <=200112

// Date
tostring con_rm, replace
g yr = substr(con_rm, 1,4)
g mth = substr(con_rm, 5,2)
destring yr mth, replace
g ym = ym(yr, mth) 

// Recompute total wage per member-period to ensure clean aggregation
bys mbr_num con_rm: egen wage2 = total(wage)
drop wage
bys mbr_num con_rm: g tag = (_n==1)
keep if tag == 1
drop tag 

save temp\wg_4249_cohort, replace

	