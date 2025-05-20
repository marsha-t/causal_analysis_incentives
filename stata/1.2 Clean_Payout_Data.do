//=============================================================================
// Project: Evaluating Incentives for Delaying Pension Payouts
// Author: Marsha Teo
// Description: 
// This script cleans payout data to identify the timing of first payout for each member
//=============================================================================

clear all
set more off

//------------------------------------------------------------------------------
// 0. Set Global Paths
//------------------------------------------------------------------------------
global root_path "C:/path/to/project/data"
cd "$root_path"
//------------------------------------------------------------------------------
// 3. Clean and Aggregate First Payout Data
//------------------------------------------------------------------------------
use temp\ret_m, clear

// Clean first payout date
tostring frst_pyt_dte, replace
g frst_pyt_yr = substr(frst_pyt_dte, 1,4) if frst_pyt_dte != "."
g frst_pyt_mth = substr(frst_pyt_dte, 5,2) if frst_pyt_dte != "."
destring frst_pyt_yr , replace
destring frst_pyt_mth , replace
g frst_pyt_ym = ym(frst_pyt_yr, frst_pyt_mth)
format frst_pyt_ym %tm

// Keep necessary vars
keep mbr_num perd_id frst_pyt_ym pnsn_tag mgs_sts_cde

// Format date
g date = date(perd_id, "DMY")
format %td date 

// Keep latest first payout date 
sort mbr_num date
bys mbr_num: g tag = (_n == _N)

g latest_frst_pyt_ym_t = frst_pyt_ym if tag == 1
bys mbr_num: egen latest_frst_pyt_ym = max(latest_frst_pyt_ym_t) 
format %tm latest_frst_pyt_ym latest_frst_pyt_ym_t frst_pyt_ym
drop latest_frst_pyt_ym_t tag frst_pyt_ym
g latest_frst_pyt_yr = year(latest_frst_pyt_ym)
g latest_frst_pyt_mth = month(latest_frst_pyt_ym)

bys mbr_num latest_frst_pyt_ym: g tag = (_n==1)
bys mbr_num: egen tot = total(tag)
tab tot 
drop tag tot

// Identify specific groups that could be excluded from analysis
g mgs = (mgs_sts_cde == "A" | mgs_sts_cde == "D")
bys mbr_num: egen mgs_mbr = max(mgs)
drop mgs_sts_cde mgs 

// Indicator if Pensionable
g pnsn = (pnsn_tag == "Y")
bys mbr_num: egen pnsn_mbr = max(pnsn)
drop pnsn pnsn_tag

// Collapse to member-level data 
keep mbr_num latest_frst_pyt_ym mgs_mbr pnsn_mbr
duplicates drop 
save temp\ret_m_mbr, replace
