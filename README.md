# Causal Analysis of Pension Deferral Incentives

This project evaluates the **causal impact of a financial incentive on pension payout timing**. It demonstrates the ability to clean large-scale data, construct treatment-control cohorts, and apply causal inference methods to real-world policy evaluation.

This analysis was first conducted in Stata. I plan to produce a corresponding implementation in **Python**.

> ⚠️ **Note:** Due to data confidentiality, raw data and output files are not shared in this repository.

---

## 🧠 Policy Context & Research Design

In 2008, a financial incentive was introduced to encourage individuals to defer their pension payouts. The policy was announced mid-2007 and applied only to individuals who were not yet eligible to start receiving payouts. Consequently, only a subset of the 1945 birth cohort - specifically those who had not reached 62 by the time of the announcement - were eligible for the incentive. 

Individuals are eligible to start their pension payouts when they have reached the potential payout start age, which varies by birth year. For those born in 1944 and 1945, the potential payout start age was 62. However, those born in Jan-Jul 1945 would receive a small finanical incentive if they had not started their payouts by age 63. 

This created a natural quasi-experimental setting. We compare behavior across adjacent cohorts:
- **Control group:** Individuals born in **Jan-Jul 1944**, unaffected by the policy
- **Treatment group:** Individuals born in **Jan-Jul 1945**, **eligible** for the incentive

The DiD compares the change in payout behavior **before and after** the incentive was introduced, isolating the treatment effect under the assumption of parallel trends.

The primary sample was restricted to those born between January and July, as only this group in the 1945 cohort would have still been eligible for the incentive at the time of the policy. To match this treatment group, the control group is correspondingly restricted to those born between January and June. 

---
## 🔍 Analysis & Robustness Checks

To strengthen the credibility of the estimates, the following robustness checks and sensitivity analyses were conducted:

- ✅ **Covariate Controls**: Multiple specifications were conducted with different sets of covariates. Leveraging the panel data available, some covariates were entered into the model as lagged values. By showing that estimates remain stable across multiple specifications, these checks support the credibility of the estimated effects and mitigate concerns about confounding effects.

- ✅ **Placebo Tests**: 
Falsification checks were run using lead indicators (placebo treatment dummies) up to three months before the actual announcement. No significant effects in these periods would support the parallel trends assumption and reduce concern about anticipation effects.

- ✅ **Sensitivity Analyses**: A narrower sample using January–June births was also tested for consistency.

Taken together, these tests strengthen one's confidence that the DiD estimates can be interpreted causally. 

---

## 🛠 Skills Demonstrated

### 🧹 Data Preparation
- Efficiently managed **large panel datasets**
- Merged and cleaned high-dimensional panel data

### 📊 Causal Inference
- Designed and implemented a **Difference-in-Differences** strategy
- Conducted **placebo and sensitivity checks**

### 📁 Workflow and Reproducibility
- Modular code organization with clearly scoped `.do` files
- Logging of results and saving of intermediate outputs
- Demonstrates best practices in reproducible analytical pipelines

---
## 📂 File Overview

| File | Purpose |
|------|---------|
| `0. Import_Data.do` | Imports raw CSVs (from SAS exports) into Stata `.dta` format |
| `1.0 Clean_Incentive_Data.do` | Cleans data on the incentive given (data is used to identify the treatment group) |
| `1.1 Clean_Balances_Data.do` | Cleans quarterly data to extract individuals' demographic variables (data is used for summary statistics and group identification) |
| `1.2 Clean_Payout_Data.do` | Cleans pension payout data (data is used to construct the outcome variable) |
| `1.3 Merge_Data.do` | Merges member-level into a unified dataset for further cleaning |
| `1.4 Clean_Wage_Data.do` | Cleans panel data on wages (data is used as covariates) |
| `1.5 Clean_Balances_Emp_Status_Data.do` | Extracts panel data on balances and employment status (data is used as covariates) |
| `1.6 Clean_Medical_Bill_Data.do` | Extracts panel data on medical bills (data is used as covariates) |
| `2. Merge_Data.do` | Combines cleaned dataset to generate the baseline analytical sample |
| `3. Sum_Stats_by_Cohort.do` | Generates summary statistics of the months between the potential and actual payout start date by birth cohort |
| `4. Generate_DID_Data.do` | Constructs DiD-ready panel with cohort, time and treatment indicators | 
| `5. DID_Analysis.do` | Runs fixed-effects DiD regressions to estimate causal treatment effects, with robustness and placebo checks |

