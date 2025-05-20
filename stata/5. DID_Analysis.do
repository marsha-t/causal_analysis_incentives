//=============================================================================
// Project: Evaluating Incentives for Delaying Pension Payouts
// Author: Marsha Teo
// Description:
// This script implements difference-in-difference analysis, 
// including the initial summary statistics and regressions (including robustness checks)
// There are two variations: (1) sample restricted to those born in Jan-Jul 1944-45 and 
// 							 (2) restricted to those born in Jan-Jun 1944-45 
//=============================================================================

clear all
set more off

//------------------------------------------------------------------------------
// 0. Set Global Paths
//------------------------------------------------------------------------------
global root_path "C:/path/to/project/data"
cd "$root_path"

//------------------------------------------------------------------------------
// 1. DID Summary Statistics: Naive DiD estimates
//------------------------------------------------------------------------------
log using "log\sumstats_prepost (Jan-Jul 1944-1945)" , replace
use temp\did_4445, clear

g control_pre = 1  if latest_birth_year == 1944 & yr == 2006 & mth == 8
g control_post = 1 if latest_birth_year == 1944 & yr == 2007 & mth == 7

g treated_pre = 1  if latest_birth_year == 1945 & yr == 2007 & mth == 8
g treated_post = 1 if latest_birth_year == 1945 & yr == 2008 & mth == 7

// Summary of outcome variable in each group
foreach var in control_pre control_post treated_pre treated_post {
    tab start if `var'
}

log close

//------------------------------------------------------------------------------
// 2. Jan–July Sample Regressions (Main DiD and Placebo)
//------------------------------------------------------------------------------
log using "log\did_4445_janjul", replace
use temp\did_4445, clear

local placebo_list placebo_mth_b4_1 placebo_mth_b4_2 placebo_mth_b4_3
local controls lastyr_med i.l.emp_status l.wage2 i.l.bal_quant

* Placebo tests
foreach p in `placebo_list' {
    // Placebo without controls
    xtreg start treat##`p', fe r
    outreg2 using "reg/did_4445_janjul_placebo.xls", append nocons
    
    // With health and income
    xtreg start treat##`p' lastyr_med i.l.emp_status l.wage2, fe r
    outreg2 using "reg/did_4445_janjul_placebo.xls", append nocons

    // Full model
    xtreg start treat##`p' `controls', fe r
    outreg2 using "reg/did_4445_janjul_placebo.xls", append nocons
}


// Baseline DiD
xtreg start treat##post, fe r 
outreg2 using "reg\did_4445_janjul_post.xls", nocons

xtreg start treat##i.mth_since_announce_7is0, fe r
outreg2 using "reg\did_4445_janjul_mths.xls", nocons

// Add controls to baseline
xtreg start treat##post lastyr_med i.l.emp_status l.wage2, fe r 
outreg2 using "reg\did_4445_janjul_post.xls", nocons

xtreg start treat##i.mth_since_announce_7is0 lastyr_med i.l.emp_status l.wage2, fe r
outreg2 using "reg\did_4445_janjul_mths.xls", nocons

xtreg start treat##post lastyr_med i.l.emp_status l.wage2 i.l.bal_quant, fe r 
outreg2 using "reg\did_4445_janjul_post.xls", nocons

xtreg start treat##i.mth_since_announce_7is0 lastyr_med i.l.emp_status l.wage2 i.l.bal_quant, fe r
outreg2 using "reg\did_4445_janjul_mths.xls", nocons

log close 

	
//------------------------------------------------------------------------------
// 3. Jan–June Sample Regressions (Sensitivity Check)
//------------------------------------------------------------------------------
log using "log\did_4445_janjun", replace
use temp\did_4445, clear
keep if latest_birth_mth < 7
	
foreach p in `placebo_list' {
    xtreg start treat##`p', fe r
    outreg2 using "reg/did_4445_janjun_placebo.xls", append nocons

    xtreg start treat##`p' lastyr_med i.l.emp_status l.wage2, fe r
    outreg2 using "reg/did_4445_janjun_placebo.xls", append nocons

    xtreg start treat##`p' `controls', fe r
    outreg2 using "reg/did_4445_janjun_placebo.xls", append nocons
}

xtreg start treat##post, fe r
outreg2 using "reg/did_4445_janjun_post.xls", replace nocons

xtreg start treat##i.mth_since_announce_7is0, fe r
outreg2 using "reg/did_4445_janjun_mths.xls", replace nocons

xtreg start treat##post lastyr_med i.l.emp_status l.wage2, fe r
outreg2 using "reg/did_4445_janjun_post.xls", append nocons

xtreg start treat##i.mth_since_announce_7is0 lastyr_med i.l.emp_status l.wage2, fe r
outreg2 using "reg/did_4445_janjun_mths.xls", append nocons

xtreg start treat##post `controls', fe r
outreg2 using "reg/did_4445_janjun_post.xls", append nocons

xtreg start treat##i.mth_since_announce_7is0 `controls', fe r
outreg2 using "reg/did_4445_janjun_mths.xls", append nocons

log close
	
//------------------------------------------------------------------------------
// 4. Additional Placebo with Treat#Post Interactions
//------------------------------------------------------------------------------	
log using "log\did_4445_placebo2", replace
use temp\did_4445, clear

foreach subset in "latest_birth_mth <= 7" "." {
    foreach p in `placebo_list' {
        xtreg start treat##`p' treat##post if `subset', fe r
        outreg2 using "reg/did_4445_`=cond("`subset'"=="." , "janjul", "janjun")'_placebo2.xls", append nocons

        xtreg start treat##`p' treat##post lastyr_med i.l.emp_status l.wage2 if `subset', fe r
        outreg2 using "reg/did_4445_`=cond("`subset'"=="." , "janjul", "janjun")'_placebo2.xls", append nocons

        xtreg start treat##`p' treat##post `controls' if `subset', fe r
        outreg2 using "reg/did_4445_`=cond("`subset'"=="." , "janjul", "janjun")'_placebo2.xls", append nocons
    }
}

log close
