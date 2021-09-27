**********************************
** File: Final.do
**********************************



clear

use pl.cleaned.dta

*Histogram of risk answers:
hist plh0204_h,percent by(syear)
*Mean answer over years:
graph bar (mean) plh0204_h,over(syear)


*******************
**PART1**
*******************
*Generating diff_risk for 1 period differences-We dont have data for 2005-2007
sort pid syear
by pid: gen diff_risk = plh0204_h - plh0204_h[_n-1] if syear>2008
by pid: replace diff_risk = plh0204_h - plh0204_h[_n-2] if syear<2009

*Histogram for diff_risk
hist diff_risk,percent by(syear)


*Employment status dummies
*were employed and unemployed now
by pid: gen unemployed=(plb0022_h[_n-1] == 1 | plb0022_h[_n-1] == 2 | plb0022_h[_n-1] == 4) & plb0022_h==9
*were unemployed employed now
by pid: gen employed = plb0022_h[_n-1] == 9  & (plb0022_h==1 | plb0022_h==2)
*retired 
by pid: gen retired = (plb0022_h[_n-1]==1 | plb0022_h[_n-1]==2 | plb0022_h[_n-1]==9) & plb0022_h==5
*number of children
qui{
merge 1:1 pid syear using num_kids.dta,keepusing(sumkids numchildren)
}

drop if _merge==2
drop _merge
sort pid syear
by pid: gen diff_number_of_kids= numchildren-numchildren[_n-1]


*Marital status dummies
*were married and got divorced
by pid: gen separated = (pld0131[_n-1] == 1 | pld0131[_n-1] == 2) & pld0131 == 4
*were single and married now
by pid: gen married = pld0131[_n-1]==3 &(pld0131 ==1 | pld0131 ==2)
*were married and now widowed
by pid: gen widowed = (pld0131[_n-1] == 1 | pld0131[_n-1] == 2) & pld0131 == 5


*Height
by pid: gen diff_height = ple0006 - ple0006[_n-1]

*Education
sort pid syear
qui{
merge 1:1 pid syear using pgen.dta,keepusing(pgbilzeit pgpbbil02 pgpsbil pgpbbil01)
}
drop if _merge==2
drop _merge
replace pgbilzeit=. if pgbilzeit < 0
rename pgbilzeit years_of_education

sort pid syear
by pid: gen diff_years_of_education = years_of_education - years_of_education[_n-1]
by pid: gen got_university_degree = (pgpbbil02[_n-1] == -2) & (pgpbbil02  > 0)
by pid: gen got_doctoral_degree = (pgpbbil02[_n-1] == -2 | pgpbbil02[_n-1] == -1 | pgpbbil02[_n-1] == 1 | pgpbbil02[_n-1] == 2 | pgpbbil02[_n-1] == 3 | pgpbbil02[_n-1] == 4 | pgpbbil02[_n-1] == 5 | pgpbbil02[_n-1] == 9 | pgpbbil02[_n-1] == 10) & (pgpbbil02 == 6 | pgpbbil02 == 7)
by pid: gen got_abitur = (pgpsbil[_n-1]==-2 | pgpsbil[_n-1] == -1 | pgpsbil[_n-1] == 1 | pgpsbil[_n-1] == 2 | pgpsbil[_n-1] == 3 | pgpsbil[_n-1] == 5 | pgpsbil[_n-1] == 6 | pgpsbil[_n-1] == 7 | pgpsbil[_n-1] == 8) & pgpsbil == 4
by pid: gen got_professional_degree = pgpbbil01[_n-1] == -2 & pgpbbil01 > 0

save pl.cleaned.dta, replace

*Income
*do this in pgen.dta file:
use pgen.dta
label lang EN
drop if syear<2004
keep pid syear pglabgro pgsndjob pgsndjob1
sort pid syear
foreach var of varlist pglabgro pgsndjob pgsndjob1 {
	qui replace `var' = 0 if `var' < 0
}
gen sum_monthly_income= pglabgro+ pgsndjob+ pgsndjob1
rename pglabgro gross_labor_income
rename pgsndjob gross_secondary_income
rename pgsndjob1 gross_secondary_job_income_1
*still in pgen.dta file without saving:
qui{
merge 1:1 pid syear using pgen.dta,keepusing(pglabgro pgsndjob pgsndjob1)
}
drop if _merge==2
drop _merge
replace sum_monthly_income =. if pglabgro<0 & pgsndjob<0 & pgsndjob1<0
replace sum_monthly_income =. if pglabgro<0 & (pgsndjob==0 | pgsndjob1==0)
save pgen_income.dta,replace
*do this in our main dta file after saving pgen_income.dta:
use pl.cleaned.dta
qui{
merge 1:1 pid syear using pgen_income.dta,keepusing(pglabgro pgsndjob pgsndjob1 sum_monthly_income)
}
drop if _merge==2
drop _merge
sort pid syear
by pid: gen diff_income=sum_monthly_income-sum_monthly_income[_n-1]

*Age-Sex:
qui{
merge m:1 pid using biobirth.dta,keepusing(gebjahr sex)
}
drop if _merge==2
drop _merge
sort pid syear
bys pid syear: gen age=syear-gebjahr

save pl.cleaned_part1.dta, replace


use pl.cleaned_part1.dta


*Regressions-Part 1
*ssc install reghdfe(if you need)
*ssc install ftools(if you need)
*Standard Regression:
eststo clear
eststo: reg diff_risk separated married widowed unemployed employed retired diff_years_of_education got_university_degree got_doctoral_degree got_abitur got_professional_degree diff_income diff_number_of_kids i.syear, nocons robust

esttab est1 using part1.tex, se ar2 replace label compress



************************** PART 2 *****************************
*WORK WİTH PL.CLEANED_PART1.DTA
use pl.cleaned_part1.dta

sort pid syear
*mode-avg mode-mean:
by pid: egen mode_by_person = mode(plh0204_h)
by pid: egen maxmode_by_person = mode(plh0204_h), maxmode
by pid: egen minmode_by_person = mode(plh0204_h), minmode
by pid: gen avg_mode_by_person=(maxmode_by_person+minmode_by_person)/2
by pid: egen mean_by_person = mean(plh0204_h)

*observations for each person:
by pid: egen count_of_obs= count(plh0204_h)


********** CREATE MEASURES OF VARIABILITY IN ANSWERS *****************

// 1. Absolute and squared deviations from mode

bys pid syear: gen dev_mode=plh0204_h-mode_by_person
bys pid syear: gen abs_dev_mode = abs(dev_mode)
by pid: egen ss_dev_mode=sum(dev_mode^2) if mode_by_person!=.


*standardize by number of observations and use only value of all years together (sum gives cumulative values)
by pid: gen abs_dev_mode_std_cumul = sum(abs_dev_mode)/count_of_obs

*As the above gives cumulative values, set all values to the maximum
* 1.1. Absolute deviations from mode
bysort pid: egen abs_dev_mode_std =  max(abs_dev_mode_std_cumul) if mode_by_person!=.
* 1.2. Squared deviations from mode
bysort pid: gen ss_dev_mode_std = ss_dev_mode/count_of_obs


// 2. Absolute and squared deviations from mean

bys pid syear: gen dev_mean=plh0204_h - mean_by_person
by pid: egen ss_dev_mean=sum(dev_mean^2) if mean_by_person!=.
bys pid syear: gen abs_dev_mean = abs(dev_mean)

by pid: gen abs_dev_mean_std_cumul = sum(abs_dev_mean)/count_of_obs

* 2.1 Absolute deviations from mean
bysort pid: egen abs_dev_mean_std =  max(abs_dev_mean_std_cumul) if mean_by_person!=.
* 2.2. Squared deviations from mean
bysort pid: gen ss_dev_mean_std = ss_dev_mean/count_of_obs


// 3. Absolute and squared deviations from average of maximum and minimum mode
bys pid syear: gen dev_avg_mode= plh0204_h - avg_mode_by_person
by pid: egen ss_dev_avg_mode=sum(dev_avg_mode^2) if avg_mode_by_person!=.
bys pid syear: gen abs_dev_avg_mode = abs(dev_avg_mode)

by pid: gen abs_dev_avg_mode_std_cumul = sum(abs_dev_avg_mode)/count_of_obs


* 3.1. Absolute deviations from average mode
bysort pid: egen abs_dev_avg_mode_std = max(abs_dev_avg_mode_std_cumul) if avg_mode_by_person!=.

* 3.2. Squared deviations from average mode
bysort pid: gen ss_dev_avg_mode_std = ss_dev_avg_mode/count_of_obs


***Generate residual of regression of risk answers on year-fixed effects
reg plh0204_h i.syear
predict fitted
gen corrected_fitted=fitted-fitted[1]
gen risk_residual_corrected= plh0204_h - corrected_fitted
sort pid syear
by pid: egen residual_mean_by_person = mean(risk_residual_corrected)


// 4. Absolute and squared deviations of the residual from the mean
bys pid syear: gen dev_resid_mean = risk_residual_corrected-residual_mean_by_person
by pid: egen ss_dev_resid_mean=sum(dev_resid_mean^2) if residual_mean_by_person!=.
bys pid syear: gen abs_dev_resid_mean = abs(dev_resid_mean)

by pid: gen abs_dev_resid_mean_std_cumul = sum(abs_dev_resid_mean)/count_of_obs

* 4.1. Absolute deviation of residual from mean
bysort pid: egen abs_dev_resid_mean_std = max(abs_dev_resid_mean_std_cumul) if residual_mean_by_person!=.

* 4.2. Squared deviation of residual from mean
bysort pid: gen ss_dev_resid_mean_std = ss_dev_resid_mean/count_of_obs

*Correlations btw variability measures:
corr abs*std ss*std if syear == 2006
corr abs*std ss*std
corr abs*mean_std ss*mean_std if syear == 2006


drop *cumul


*ADDING VARIABLES ON COGNITIVE ABILITIES

capture drop _merge
merge m:1 pid syear using cognit.dta
drop _merge

foreach var of varlist f99* f96*{
	replace `var' = . if `var'  < 0 
}

*ADDING VARIABLES ON PERSONAL TRAITS
do big_five_jan01.do

*Create averages of big five variables:
sort pid syear
foreach var of varlist std_bigfive*{
	by pid: egen `var'_mean = mean(`var')
}

*Create averages of individual traits:
foreach var of varlist plh021*{
	by pid: egen `var'_mean = mean(`var')
}

foreach var of varlist plh022*{
	by pid: egen `var'_mean = mean(`var')
}

*Add labels for singular questions on traits:
label var plh0222_mean "Conscientousness 1 (Carry out tasks efficiently)"
label var plh0212_mean "Conscientousness 2 (Thorough worker)"
label var plh0218r_mean "Conscientousness 3 (Lazy)"

label var plh0223r_mean "Extraversion 1 (Reservedness-Reversed)"
label var plh0213_mean "Extraversion 2 (Communicative)"
label var plh0219_mean "Extraversion 3 (Sociable)"

label var plh0224_mean "Agreeableness 1 (Friendly with others)"
label var plh0214r_mean "Agreeableness 2 (Sometimes coarse with others-Reversed)"
label var plh0217_mean "Agreeableness 3 (Able to forgive)"

label var plh0225_mean "Openness 1 (Lively imagination)"
label var plh0220_mean "Openness 2 (Value artistic experiences)"
label var plh0215_mean "Openness 3 (Original)"

label var plh0221_mean "Neuroticism 1 (Nervous)"
label var plh0216_mean "Neuroticism 2 (Worry a lot)"
label var plh0226r_mean "Neuroticism 3 (Deal with stress-Reversed)"


*** TREAT MISSING VALUES *****
* with big five traits
gen f99z90s_ =f99z90s
replace f99z90s_ =0 if f99z90s ==.

gen dummy_99 =1 if f99z90s == .
replace dummy_99 =0 if f99z90s != .

gen f96t90s_ =f96t90s
replace f96t90s_ =0 if f96t90s==.

gen dummy_96 =1 if f96t90s ==.
replace dummy_96 =0 if f96t90s !=.


foreach var of varlist std_bigfive*mean{
	gen `var'_adjusted = `var'
	replace `var'_adjusted = 0 if `var' == .
	gen `var'_dummy_missing = 1 if `var' == .
	replace `var'_dummy_missing = 0 if `var' != .
}


foreach var of varlist plh0222_mean plh0212_mean plh0218r_mean plh0223r_mean plh0213_mean plh0219_mean plh0224_mean plh0214r_mean plh0217_mean plh0225_mean plh0220_mean plh0215_mean plh0221_mean plh0216_mean plh0226r_mean{
	egen `var'_std = std(`var') 
	replace `var'_std = . if `var'_std == 0
	by pid: gen `var'_adjusted = `var'_std
	replace `var'_adjusted = 0 if `var'_std == .
	gen `var'_dummy_missing = 1 if `var'_std == . 
	replace `var'_dummy_missing = 0 if `var'_std != .
}


*Add labels for singular questions on traits:
label var plh0222_mean_adjusted "Conscientousness 1 (Carry out tasks efficiently)"
label var plh0212_mean_adjusted "Conscientousness 2 (Thorough worker)"
label var plh0218r_mean_adjusted "Conscientousness 3 (Lazy)"

label var plh0223r_mean_adjusted "Extraversion 1 (Reservedness-Reversed)"
label var plh0213_mean_adjusted "Extraversion 2 (Communicative)"
label var plh0219_mean_adjusted "Extraversion 3 (Sociable)"

label var plh0224_mean_adjusted "Agreeableness 1 (Friendly with others)"
label var plh0214r_mean_adjusted "Agreeableness 2 (Sometimes coarse with others-Reversed)"
label var plh0217_mean_adjusted "Agreeableness 3 (Able to forgive)"

label var plh0225_mean_adjusted "Openness 1 (Lively imagination)"
label var plh0220_mean_adjusted "Openness 2 (Value artistic experiences)"
label var plh0215_mean_adjusted "Openness 3 (Original)"

label var plh0221_mean_adjusted "Neuroticism 1 (Nervous)"
label var plh0216_mean_adjusted "Neuroticism 2 (Worry a lot)"
label var plh0226r_mean_adjusted "Neuroticism 3 (Deal with stress-Reversed)"


save pl.cleaned_part2.dta, replace

*REGRESSIONS FOR PART 2:
*Year 2006 now contains all information per individual (except for singular traits)
*Do all regressions for syear == 2006 only!

use pl.cleaned_part2.dta

*ANALYSIS: REGRESSIONS OF DIFFERENT MEASURES ON TRAIT AND COGNITION VARIABLES

// 1. DEP VARIABLE MODE

* 1.1.
eststo clear
eststo: reg abs_dev_mode_std f99z90s_ f96t90s_ dummy_96 dummy_99 plh*adjusted plh*dummy_missing if syear == 2006 & count_of_obs > 1
eststo: reg abs_dev_mode_std std_bigfive*mean_adjusted *std_bigfive*dummy_missing f99z90s_ f96t90s_ dummy_99 dummy_96 if syear == 2006  & count_of_obs > 1

* 1.2.
eststo: reg ss_dev_mode_std f99z90s_ f96t90s_ dummy_96 dummy_99 plh*adjusted plh*dummy_missing if syear == 2006 & count_of_obs > 1
eststo: reg ss_dev_mode_std std_bigfive*mean_adjusted *std_bigfive*dummy_missing f99z90s_ f96t90s_ dummy_99 dummy_96 if syear == 2006 & count_of_obs > 1


// 2. DEP VARIABLE MEAN

* 2.1.
eststo: reg abs_dev_mean_std f99z90s_ f96t90s_ dummy_96 dummy_99 plh*adjusted plh*dummy_missing if syear == 2006 & count_of_obs > 1
eststo: reg abs_dev_mean_std std_bigfive*mean_adjusted *std_bigfive*dummy_missing f99z90s_ f96t90s_ dummy_99 dummy_96 if syear == 2006 & count_of_obs > 1
* 2.2.
eststo: reg ss_dev_mean_std f99z90s_ f96t90s_ dummy_96 dummy_99 plh*adjusted plh*dummy_missing if syear == 2006 & count_of_obs > 1
eststo: reg ss_dev_mean_std std_bigfive*mean_adjusted *std_bigfive*dummy_missing f99z90s_ f96t90s_ dummy_99 dummy_96 if syear == 2006 & count_of_obs > 1


// 3. RESIDUAL - MEAN

* 3.1.
eststo: reg abs_dev_resid_mean_std f99z90s_ f96t90s_ dummy_96 dummy_99 plh*adjusted plh*dummy_missing if syear == 2006 & count_of_obs > 1
eststo: reg abs_dev_resid_mean_std std_bigfive*mean_adjusted *std_bigfive*dummy_missing f99z90s_ f96t90s_ dummy_99 dummy_96 if syear == 2006 & count_of_obs > 1

* 3.2.
eststo: reg ss_dev_resid_mean_std f99z90s_ f96t90s_ dummy_96 dummy_99 plh*adjusted plh*dummy_missing if syear == 2006 & count_of_obs > 1
eststo: reg ss_dev_resid_mean_std std_bigfive*mean_adjusted *std_bigfive*dummy_missing f99z90s_ f96t90s_ dummy_99 dummy_96 if syear == 2006 & count_of_obs > 1

* est1 is absolute dev from mode for individual traits, est2 for bigfive
* est3 is squared dev from mode for individual traits, est4 for bigfive
* est5 is abs dev from mean for ind, est6 for bigfive, est7 for squared dev. from mean ind, est8 for bigfive
* est9 is abs dev of residual from mean for ind, est10 for bigfive
* est11 is square dev of residual from mean for ind, est12 for bigfive

* So individual traits: est1, est3, est5, est7, est9, est11, where 9 and 11 are corrected by year FE
* bigfive traits: est2, est4, est6, est8, est10, est12, where est1 and est12 are corrected by year FE 


*Add labels for output
label var f96t90s_ "Cognition (Animal Test)"
label var f99z90s_ "Cognition (Number Symbol Test)"
label var std_bigfive_g_mean_adjusted "Conscientousness"
label var std_bigfive_e_mean_adjusted "Extraversion"
label var std_bigfive_v_mean_adjusted "Agreeableness"
label var std_bigfive_o_mean_adjusted "Openness"
label var std_bigfive_n_mean_adjusted "Neuroticism"
label var abs_dev_mode_std "Abs. dev. from mode"
label var abs_dev_mean_std "Abs. dev. from mean"
label var ss_dev_mode_std "Sq. dev. from mode"
label var ss_dev_mean_std "Sq. dev. from mean"
label var abs_dev_resid_mean_std "Abs. dev. from mean"
label var ss_dev_resid_mean_std "Sq. dev. from mean"


* Store output for individual traits:
esttab est1 est3 est5 est7 est9 est11 using individual_part2.tex, se ar2 replace label compress drop(plh*dummy_missing dummy*)
esttab est2 est4 est6 est8 est10 est12 using bigfive_part2.tex, se ar2 replace label compress drop(*std_bigfive*dummy_missing dummy*)


************************** PART 3 *****************************

*Calculate fraction of people who give 5 as an answer
gen dummy_5 =1 if plh0204_h == 5
replace dummy_5 = 0 if dummy_5 ==.

*find out how many times people answered 5 and overall how many years each person particiated in survey
by pid: egen sum_dummy_5 = sum(dummy_5)
by pid: egen num_years = count(syear) if plh0204_h !=.
by pid: gen frac_dummy_5 = sum_dummy_5/num_years

*Fraction of 5-Regressions
eststo clear 
eststo: reg frac_dummy_5 std_bigfive*mean f99z90s_ f96t90s_ dummy_99 dummy_96 if syear == 2006
eststo: reg frac_dummy_5 std_bigfive*mean f99z90s_ f96t90s_ dummy_99 dummy_96 if syear == 2006 & frac_dummy_5>0.9
eststo: reg frac_dummy_5 std_bigfive*mean f99z90s_ f96t90s_ dummy_99 dummy_96 if syear == 2006 & frac_dummy_5>0.75
eststo: reg frac_dummy_5 std_bigfive*mean f99z90s_ f96t90s_ dummy_99 dummy_96 if syear == 2006 & frac_dummy_5>0.5
eststo: reg frac_dummy_5 std_bigfive*mean f99z90s_ f96t90s_ dummy_99 dummy_96 if syear == 2006 & frac_dummy_5>0.25

esttab est1 est2 est3 est4 est5 using frac_dummy_regressions.tex, se ar2 replace label compress drop(dummy_96)

eststo clear 
// 1. DEP VARIABLE MODE
*1.1 
eststo: reg abs_dev_mode_std f99z90s_ f96t90s_ dummy_99 dummy_96 plh*adjusted plh*dummy_missing if syear == 2006 & count_of_obs > 1 & frac_dummy_5<0.75
eststo: reg abs_dev_mode_std std_bigfive*mean_adjusted *std_bigfive*dummy_missing f99z90s_ f96t90s_ dummy_99 dummy_96 if syear == 2006 & count_of_obs > 1 & frac_dummy_5<0.75

*1.2 

eststo: reg ss_dev_mode_std f99z90s_ f96t90s_ dummy_99 dummy_96 plh*adjusted plh*dummy_missing if syear == 2006 & count_of_obs > 1 & frac_dummy_5<0.75
eststo: reg ss_dev_mode_std std_bigfive*mean_adjusted *std_bigfive*dummy_missing f99z90s_ f96t90s_ dummy_99 dummy_96 if syear == 2006 & count_of_obs > 1 & frac_dummy_5<0.75

// 2. DEP VARIABLE MEAN

* 2.1.
eststo: reg abs_dev_mean_std f99z90s_ f96t90s_ dummy_99 dummy_96 plh*adjusted plh*dummy_missing if syear == 2006 & count_of_obs > 1 & frac_dummy_5<0.75
eststo: reg abs_dev_mean_std std_bigfive*mean_adjusted *std_bigfive*dummy_missing f99z90s_ f96t90s_ dummy_99 dummy_96 if syear == 2006 & count_of_obs > 1 & frac_dummy_5<0.75

* 2.2.
eststo: reg ss_dev_mean_std f99z90s_ f96t90s_ dummy_99 dummy_96 plh*adjusted plh*dummy_missing if syear == 2006 & count_of_obs > 1 & frac_dummy_5<0.75
eststo: reg ss_dev_mean_std std_bigfive*mean_adjusted *std_bigfive*dummy_missing f99z90s_ f96t90s_ dummy_99 dummy_96 if syear == 2006 & count_of_obs > 1 & frac_dummy_5<0.75

// 3. RESIDUAL - MEAN

* 3.1.
eststo: reg abs_dev_resid_mean_std f99z90s_ f96t90s_ dummy_99 dummy_96 plh*adjusted plh*dummy_missing if syear == 2006 & count_of_obs > 1 & frac_dummy_5<0.75
eststo: reg abs_dev_resid_mean_std std_bigfive*mean_adjusted *std_bigfive*dummy_missing f99z90s_ f96t90s_ dummy_99 dummy_96 if syear == 2006 & count_of_obs > 1 & frac_dummy_5<0.75

* 3.2.
eststo: reg ss_dev_resid_mean_std f99z90s_ f96t90s_ dummy_99 dummy_96 plh*adjusted plh*dummy_missing if syear == 2006 & count_of_obs > 1 & frac_dummy_5<0.75
eststo: reg ss_dev_resid_mean_std std_bigfive*mean_adjusted *std_bigfive*dummy_missing f99z90s_ f96t90s_ dummy_99 dummy_96 if syear == 2006 & count_of_obs > 1 & frac_dummy_5<0.75


esttab est1 est3 est5 est7 est9 est11 using individual_part3.tex, b(3) se(3) ar2 replace label compress drop(dummy_96)
esttab est2 est4 est6 est8 est10 est12 using bigfive_part3.tex, b(3) se(3) ar2 replace label compress drop(dummy_96)

eststo clear 
save pl.cleaned_part3.dta, replace

// ****Weight thing(need to be edited)
reg abs_dev_mode_std f99z90s_ f96t90s_ dummy_96 dummy_99 plh*adjusted plh*dummy_missing if syear == 2006 & count_of_obs > 1 [iweight = 1/count_of_obs]
reg abs_dev_mode_std f99z90s_ f96t90s_ dummy_96 dummy_99 plh*adjusted plh*dummy_missing if syear == 2006 & count_of_obs > 1 [fweight = 1/count_of_obs]
reg abs_dev_mode_std f99z90s_ f96t90s_ dummy_96 dummy_99 plh*adjusted plh*dummy_missing if syear == 2006 & count_of_obs > 1 [pweight = 1/count_of_obs]

*** Regressing outcomes on the risk attitude and controls for two different samples:
* People with high and people with low variability in answers.

use pl.cleaned_part3.dta
merge 1:1 pid syear using pwealth.dta


sort pid syear
egen risk_median = median(abs_dev_mean_std) if syear == 2018
egen risk_median_2007 = median(abs_dev_mean_std) if syear == 2007

*** Smoking 
* modify smoking variable such that 0 means not smoking and 1 means smoking
eststo clear
replace ple0081_h = 0 if ple0081_h == 2

eststo: logit ple0081_h plh0204_h age sex ple0006 if syear == 2018 & abs_dev_mean_std > risk_median
eststo: logit ple0081_h plh0204_h age sex ple0006 if syear == 2018 & abs_dev_mean_std < risk_median

eststo clear
*** Active sports
gen active_sports = 1 if  pli0092_h != 5 & pli0092_h != 4 & pli0092_h != 3
replace active_sports = 0 if active_sports == .

eststo: logit active_sports plh0204_h age sex ple0006 if syear == 2018 & abs_dev_mean_std > risk_median & age < 66
eststo: logit active_sports plh0204_h age sex ple0006 if syear == 2018 & abs_dev_mean_std < risk_median & age < 66

eststo clear
*** Financial assets
* Financial asset variable is available for 2007 only; so we do logit with risk attitude from 2006 and other variables from 2007
* and control for debts a person has (plc0421)
gen financial_assets = f10000
gen debts = plc0421
replace debts = 0 if debts == 2
* so debt equal to one if debt from private credit and zero otherwise

sort pid syear
by pid: gen risk_2007 = plh0204_h[_n-1]
by pid: gen height_2007 = ple0006[_n-1]

eststo: logit financial_assets risk_2007 height_2007 age sex debt if syear == 2007 & abs_dev_mean_std > risk_median_2007 
eststo: logit financial_assets risk_2007 height_2007 age sex debt if syear == 2007 & abs_dev_mean_std < risk_median_2007 

* plan to get selfemployed in next to years:

gen selfemployed = plb0428

eststo: reg selfemployed risk_2007 age sex height_2007 debt if syear == 2007 & abs_dev_mean_std > risk_median_2007 & age < 66
eststo: reg selfemployed risk_2007 age sex height_2007 debt if syear == 2007 & abs_dev_mean_std < risk_median_2007 & age < 66

label var selfemployed "Self-employed"
label var debts "1 if debts from private loans"
label var financial_assets "Holding financial assets"
label var active_sports "Practicing active sports"

																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																						esttab est1 est2 est3 est4 est5 est6 est7 est8 using "/media/mattis/MB/highlow.tex", se ar2 label compress b(3) se(3) replace

