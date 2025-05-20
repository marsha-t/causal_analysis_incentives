//=============================================================================
// Project: Evaluating Incentives for Delaying Pension Payouts
// Author: Marsha Teo
// Description: 
// This script cleans quarterly balances data to extract constant variables for each member. 
//  Quaterly dataset combined to form master panel dataset. 
//	Master panel dataset used to generate non-panel member-level dataset
//	As this non-panel dataset is quite large, it is split by birth cohorts
//	These are required because the constant variables are often not constant
//=============================================================================

clear all
set more off

//------------------------------------------------------------------------------
// 0. Set Global Paths
//------------------------------------------------------------------------------
global root_path "C:/path/to/project/data"
cd "$root_path"

//------------------------------------------------------------------------------
// 1. Process Member-Level Constant Demographic Varibles 
//------------------------------------------------------------------------------
// Note: fields here are to be constant for each member but this is not always the case in data
// 		Hence, use latest instance by a given date
forval year = 2013/2018 {
	forval qtr = 1/4 {
		use raw\bal_`year'_`qtr'.dta, clear
		keep mbr_num perd_id brth_dte dth_dte gndr_cde rc_grp_cde ctzn_grp_cde

		// Date variable 
		g date = date(perd_id, "DMY")
		format %td date 

		sort mbr_num date
		bys mbr_num: g tag = (_n == _N)

		// Keep latest birth date 
			g birth_date = date(brth_dte, "DMY")
			format %td birth_date
			g latest_birth_date_t = birth_date if tag == 1
			bys mbr_num: egen latest_birth_date = max(latest_birth_date_t) 
			format %td latest_birth_date
			drop latest_birth_date_t  
			
			g latest_birth_year = year(latest_birth_date)
			keep if latest_birth_year >= 1942 & latest_birth_year <=1955
			drop brth_dte

		// Keep latest death date 
			tostring dth_dte, replace
			g death_date = date(dth_dte, "DMY")
			format %td death_date 
			g latest_death_date_t  = death_date if tag == 1 
			bys mbr_num: egen latest_death_date = max(latest_death_date_t)
			format %td latest_death_date
			drop latest_death_date_t	

		// Keep latest gender
			g male = 1 if gndr_cde == "M"
			replace male = 0 if gndr_cde == "F"
			
			g latest_male_t = male if tag == 1 
			bys mbr_num: egen latest_male = max(latest_male_t)
			drop latest_male_t
			
		// Keep latest race 
			g race = 1 if rc_grp_cde == "02"
			replace race = 2 if rc_grp_cde == "00"
			replace race = 3 if rc_grp_cde == "04"
			replace race = 4 if rc_grp_cde == "O" | rc_grp_cde == "U"  
			lab def race_lab 1"Chinese" 2"Malay" 3"Indian" 4"Others/Unknown"
			lab val race race_lab
			
			g latest_race_t = race if tag == 1 
			bys mbr_num: egen latest_race = max(latest_race_t)
			lab val latest_race race_lab 
			drop latest_race_t
			
		// Keep latest citizenship 
			g ctz = 1 if ctzn_grp_cde == "S"
			replace ctz = 2 if ctzn_grp_cde == "P"
			replace ctz = 2 if ctzn_grp_cde == "F"
			lab def ctz_lab 1"SC" 2"PR" 3"FW"
			lab val ctz ctz_lab
			
			g latest_ctz_t = ctz if tag == 1 
			bys mbr_num: egen latest_ctz = max(latest_ctz_t)
			drop latest_ctz_t
			
		keep mbr_num date latest_birth_date latest_birth_year latest_death_date latest_male latest_race latest_ctz  tag 
		keep if tag == 1 
		drop tag 
	save temp\bal_`year'_`qtr'_mbr.dta, replace 
	}
}

// Combine all quarters
use temp\bal_2013_1_mbr, clear
forval qtr = 2/4 {
	append using temp\bal_2013_`qtr'_mbr
}
forval year = 2014/2018 {
	forval qtr = 1/4 {
		append using temp\bal_`year'_`qtr'_mbr
	}
}
save temp\bal_mbr_t, replace

// Generate member-level dataset (non-panel)
use temp\bal_mbr_t, replace
sort mbr_num date
bys mbr_num: g tag = (_n == _N)
codebook mbr_num 
tab tag 
keep if tag == 1
save temp\bal_mbr, replace

// Split into separate birth year cohorts 
forvalues y = 1942/1955{
	preserve
	keep if latest_birth_year == `y'
	save temp\bal_m_cohort`y', replace
	restore
}
