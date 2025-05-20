//=============================================================================
// Project: Evaluating Incentives for Delaying Pension Payouts
// Author: Marsha Teo
// Description:
// This script cleans quarterly balances data to extract time-varying variables
// Specifically, balances and employment status
//=============================================================================

clear all
set more off

//------------------------------------------------------------------------------
// 0. Set Global Paths
//------------------------------------------------------------------------------
global root_path "C:/path/to/project/data"
cd "$root_path"

//------------------------------------------------------------------------------
// 1. Filter Data to 1942–1949 Cohort
//------------------------------------------------------------------------------
forval year = 2002(1)2018 {
	forval qtr = 1(1)4 {
		use raw\bal_`year'_`qtr'.dta, replace 
		keep mbr_num perd_id bal_amt empl_sts_cde 
		merge m:1 mbr_num using temp\mbrlist_1942_1949
		keep if _merge == 3
		drop _merge
		save temp\bal_`year'_`qtr'_panel.dta, replace 
	}
}

//------------------------------------------------------------------------------
// 2. Append All Quarters
//------------------------------------------------------------------------------
use temp\bal_2002_1_panel.dta, replace 
forval qtr = 2(1)4 {
	append using temp\bal_2002_`qtr'_panel.dta
}
forval year = 2003(1)2018 {
	forval qtr = 1(1)4 {
		append using temp\bal_`year'_`qtr'_panel.dta
	}
}

//------------------------------------------------------------------------------
// 3. Clean variables
//------------------------------------------------------------------------------
// Date
g date = date(perd_id, "DMY")
format %td date
g yr = year(date)
g mth= month(date)
g ym = ym(yr, mth)
format %tm ym

// Employment Status
g emp_status = 1 if empl_sts_cde == "A"
replace emp_status = 2 if empl_sts_cde == "S"
replace emp_status = 3 if empl_sts_cde == "I"
lab def emp_status_lab 1"Active" 2"Selfemp" 3"Inactive"
lab val emp_status emp_status_lab
drop empl_sts_cde 

// Handle where Balance = 0
replace bal_amt = . if bal_amt == 0 

// Balance percentiles
foreach x in 20 40 60 80 {
	bysort perd_id latest_birth_year: egen pct`x'_bal = pctile(bal_amt), p(`x')	
}
g bal_quant = 1 if bal_amt < pct20_bal 
replace bal_quant = 	2 if bal_amt >= pct20_bal & bal_amt < pct40_bal
replace bal_quant = 	3 if bal_amt >= pct40_bal & bal_amt < pct60_bal
replace bal_quant = 	4 if bal_amt >= pct60_bal & bal_amt < pct80_bal
replace bal_quant = 	5 if bal_amt >= pct80_bal & bal_amt !=.


save temp\bal_panel, replace 


