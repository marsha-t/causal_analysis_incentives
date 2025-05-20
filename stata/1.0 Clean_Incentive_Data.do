//=============================================================================
// Project: Evaluating Incentives for Delaying Pension Payouts
// Author: Marsha Teo
// Description: 
// This script cleans incentive transaction data to create a member-level (non-panel) dataset
//=============================================================================

clear all
set more off

//------------------------------------------------------------------------------
// 0. Set Global Paths
//------------------------------------------------------------------------------
global root_path "C:/path/to/project/data"
cd "$root_path"

//------------------------------------------------------------------------------
// 1. Clean Incentive Transaction Panel Data to Member-Level
//------------------------------------------------------------------------------
use .\raw\incentive_txn.dta, clear

// Drop irrelevant variables
drop sch_lvl_1 sch_lvl_2 sch_lvl_3 tp_lvl_1 tp_lvl_2 tp_lvl_4 ma_ovrf_amt con_dte trns_rm trns_ry

// Format transaction dates
g date = date(perd_id, "DMY")
format %td date
g year = year(date)
g mth = month(date)

g trns_date = date(trns_dte, "DMY")
format %td trns_date
g trns_year = year(trns_date)
g trns_mth = month(trns_date)

compare year trns_year 
compare trns_mth mth 
drop trns_*

// Identify incentive instances
sort mbr_num perd_id
tab acct_tp_cde
tab tp_lvl_3, g(bonus_num_t)
forval x =1(1)3{
	g bonus_num`x'_date_t = date if bonus_num_t`x' ==1
	format %td bonus_num`x'_date_t 
	g bonus_num`x'_year_t = year(bonus_num`x'_date_t)
}

forval x =1(1)3 {
	bys mbr_num: egen  bonus_num`x' = max(bonus_num_t`x')
	bys mbr_num: egen  bonus_num`x'_date = max(bonus_num`x'_date_t)
	format %td  bonus_num`x'_date 
	bys mbr_num: egen  bonus_num`x'_year = max(bonus_num`x'_year_t)
}

sort mbr_num perd_id
encode tp_lvl_3, g(bonus_num) label(bonus_num_lab)
bys mbr_num: g mbr_dup  = _N
bys mbr_num: egen max_incentive = max(bonus_num)
label var max_incentive "Maximum incentive received by member"
tab tp_lvl_3 year if mbr_dup != max_incentive

drop perd_id tp_lvl_3 acct_tp_cde date year mth *_t *_t? bonus_num

duplicates drop 

bys mbr_num : g dup = _N
tab dup
drop dup
save temp\incentive_txn_mbr.dta, replace
