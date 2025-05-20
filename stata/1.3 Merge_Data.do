//=============================================================================
// Project: Evaluating Incentives for Delaying Pension Payouts
// Author: Marsha Teo
// Description: 
// This script merges member-level datasets (RA balance, payout, incentive data)
// Unique list of members in the relevant cohorts used for the cleaning of other datasets
//=============================================================================

clear all
set more off

//------------------------------------------------------------------------------
// 0. Set Global Paths
//------------------------------------------------------------------------------
global root_path "C:/path/to/project/data"
cd "$root_path"

//------------------------------------------------------------------------------
// 1. Merge RA Balance, Payout and Incentive Data by Birth Cohort
//------------------------------------------------------------------------------
forvalues y = 1942/1955{
	// Start with balances data
	use temp\bal_m_cohort`y', clear
	
	// Merge payout data
	merge m:1 mbr_num using temp\ret_m_mbr
	drop if _merge == 2 
	rename _merge merge_ra_ret

	// Merge incentive transaction data
	merge m:1 mbr_num using temp\incentive_txn_mbr.dta
	drop if _merge == 2 
	rename _merge merge_ra_ret_incentive

	save temp\ra_ret_incentive_cohort`y', replace
}

//------------------------------------------------------------------------------
// 3. Generate Member List for 1942–1949 Cohorts 
//------------------------------------------------------------------------------
// Start with first cohort
use temp/ra_ret_incentive_cohort1942.dta, clear
keep mbr_num latest_birth_year
duplicates drop

// Append others
forvalues y = 1943/1949 {
	append using temp/ra_ret_incentive_cohort`y'.dta
	keep mbr_num latest_birth_year
	duplicates drop
}

duplicates drop
sort mbr_num latest_birth_year
save temp/mbrlist_1942_1949.dta, replace
