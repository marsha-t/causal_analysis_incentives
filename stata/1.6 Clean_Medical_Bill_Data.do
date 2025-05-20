//=============================================================================
// Project: Evaluating Incentives for Delaying Pension Payouts
// Author: Marsha Teo
// Description:
// This script processes medical bill data (2002–2018) for the 1942-49 cohort
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
	forval h = 1/2{
		use raw\med_`y'_`h'.dta, clear
		
		keep mbr_num perd_id lastyr_med tot_bill		

		// Filter to use only 1942-49 cohort
		merge m:1 mbr_num using temp\mbrlist_1942_1949
		keep if _merge == 3
		save temp\wg_`y'_`h', replace
	}
}

//------------------------------------------------------------------------------
// 2. Combine All Quarters into Single Panel
//------------------------------------------------------------------------------
use temp\med_2002_1, clear
append using temp\med_2002_2
forval y = 2003/2018 {
	forval q = 1/2{
		append using temp\med_`y'_`h'
	}
}

drop _merge

//------------------------------------------------------------------------------
// 3. Clean dataset and variables
//------------------------------------------------------------------------------

// Date
g date = date(perd_id, "DMY")
format %td date
g yr = year(date)
g mth= month(date)
g ym = ym(yr, mth)

save temp\med_4249_cohort, replace

	