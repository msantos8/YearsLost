/*Manuscript - How much lifetime is lost due to homicides: A cross-national comparison
Version Date: February 22, 2025

-World Health Organization Mortality Database (raw data files; version date 21 February 2024)
https://www.who.int/data/data-collection-tools/who-mortality-database

-UN World Population Prospects 2024
https://population.un.org/wpp/

Notes:
-Please be aware that the code relies on specific file paths relative to the working directory. Please review those paths before running the code, or replace the paths with frames.

*/

**# Trends
use "Replication Data.dta", clear
global scatter_options connect(l) mlcolor(white) mlalign(outside) lwidth(.4)

*Select
drop if Year == 2022 // Only 18 countries with data

*Imputation
tsset eCountry Year, yearly

foreach i of var yld WHO_HomRate GDP_Current_PerCap {
gsort eCountry Year
ipolate `i' Year, gen(i_`i') by(eCountry)
bysort eCountry: replace i_`i' = i_`i'[_n-1] if i_`i'==.
gsort eCountry -Year
bysort eCountry: replace i_`i' = i_`i'[_n-1] if i_`i'==.
gsort eCountry Year
}

*Collapse World
gen Original = 1
gen Population = 1
gen Represented = 1 if i_yld ~= .
gen Countries = 1 / Pop if i_yld ~= . // Interpolated
gen CountriesObs = 1 / Pop if yld ~= . // Actually Observed

preserve
collapse (mean) i_* (sum) Countries CountriesObs Population Represented [pweight=Pop], by(Year)
gen Short = "World"

save "Data/World.dta", replace
restore

*Collapse Regions
preserve
collapse (mean) i_* (sum) Countries CountriesObs Population Represented [pweight=Pop], by(Year Region)
rename Region Short

save "Data/Regions.dta", replace
restore

*Append
append using "Data/World.dta"
append using "Data/Regions.dta"

*Descriptives
// Total Lifetime Lost
list i_yld Population Year if Short == "World"
list i_yld Year if Short == "United States"

tabstat Population if Short == "World" & Year == 2021, format(%20.0f)

gen total_lost = (Population * i_yld) / 365
replace total_lost = (Pop * i_yld) / 365 if Population == 1

tabstat total_lost if Short == "World" & Year == 2021, format(%20.0f)
tabstat total_lost if Short == "United States" & Year == 2021, format(%20.0f)

// Statistical Value (World Health Organization)
gen value_lost = ((i_yld / 365) * (i_GDP_Current_PerCap * 1000)) * Population
replace value_lost = ((i_yld / 365) * (i_GDP_Current_PerCap * 1000)) * Pop if Population == 1

gen value_lost_capita = (i_yld / 365) * (i_GDP_Current_PerCap * 1000)
tabstat value_lost_capita if Short == "World" & Year == 2021, format(%20.0f)

// Total World
sum value_lost if Short == "World" & Year == 2021
di %20.0f r(mean) * 2 // World Health Organization 

sum value_lost_capita if Short == "World" & Year == 2021
di %20.2f r(mean) * 2 // World Health Organization 

// US
sum value_lost if Short == "United States" & Year == 2021
di %20.0f r(mean) * 2 // World Health Organization 

sum value_lost_capita if Short == "United States" & Year == 2021
di %20.2f r(mean) * 2 // World Health Organization 

sum value_lost if Short == "United States" & Year == 2021
di (r(mean) * 2) / 2709800000

// Longitudinal
list Short Year CountriesObs Countries i_yld if Short == "World" & Year >= 1990, sep(0)
list Short Year CountriesObs Countries i_yld if Short == "Americas" & Year >= 1990, sep(0)
list Short Year CountriesObs Countries i_yld if Short == "Asia" & Year >= 1990, sep(0)
list Short Year CountriesObs Countries i_yld if Short == "Europe" & Year >= 1990, sep(0)
list Short Year CountriesObs Countries i_yld if Short == "Oceania" & Year >= 1990, sep(0)

sort Short Year
list Short Year CountriesObs Countries i_yld if Original == . & (Year == 2000 | Year == 2021), sep(0)


*Plot
// US & World 1950
graph twoway (scatter i_yld Year if Short == "United States", $scatter_options color(black)) (scatter i_yld Year if Short == "World", $scatter_options msymbol(triangle) color(gray)), xtitle("") ytitle("Days Lost (Average)") legend(order(1 "United States" 2 "World") position(12) rows(1)) xlabel(1950(5)2025) scale(1.2) subtitle("(A) {it:United States & the World}", span position(11) ring(4) justification(left))

// US & World 2000
graph twoway (scatter yld Year if Short == "United States" & Year >= 1990, $scatter_options color(black)) (line i_yld Year if Short == "World" & Year >= 2000, color(black) lwidth(.4) lpattern(shortdash)) ///
, xtitle("") ytitle("Days Lost (Average)") legend(order(1 "United States" 2 "World") position(12) rows(1)) xlabel(1990(5)2025) scale(1.2) subtitle("(A) {it:United States & the World}", span position(11) ring(4) justification(left))

// World & Region 2000
graph twoway ///
(line i_yld Year if Short == "World", color(black) lwidth(.4) lpattern(shortdash)) ///
(scatter i_yld Year if Short == "Americas", $scatter_options color(black)) ///
(scatter i_yld Year if Short == "Asia", $scatter_options color(black) msymbol(triangle)) ///
(scatter i_yld Year if Short == "Europe", $scatter_options color(gs9)) ///
(scatter i_yld Year if Short == "Oceania", $scatter_options color(gs9) msymbol(triangle)) ///
if Year >= 2000, xtitle("") ytitle("Days Lost (Average)") legend(order(1 "World" 2 "Americas" 3 "Asia" 4 "Europe" 5 "Oceania") position(12) rows(1)) xlabel(2000(5)2025) scale(1.2) subtitle("(A) {it:World & Regions}", span position(11) ring(4) justification(left))

// US Standardized
egen std_i_yld = std(i_yld) if Original == 1
egen std_i_WHO_HomRate = std(i_WHO_HomRate) if Original == 1

list Short Year std_i_yld std_i_WHO_HomRate if Short == "United States" & Year >= 1990, sep(0)
cor std_i_yld std_i_WHO_HomRate if Short == "United States" & Year >= 1990

graph twoway (scatter std_i_yld Year if Short == "United States", $scatter_options color(black)) (scatter std_i_WHO_HomRate Year if Short == "United States", $scatter_options msymbol(triangle) color(gray)) ///
if Year >= 1990, xtitle("") ytitle("Z-Score (Standard Deviations)") legend(order(1 "Days Lost" 2 "Homicide Rate") position(12) rows(1)) xlabel(1990(5)2025) scale(1.2) subtitle("(B) {it:United States (Standardized)}", span position(11) ring(4) justification(left))


*Data Availability
// Descriptions
tab Short if Year >= 2000 & yld ~= .
unique Country
unique Country if Region == "Africa"

// Examples of Imputations for Regional Trends
global where "Australia"
list Short Year yld i_yld if Year >= 2000 & Short == "$where"

graph twoway ///
(scatter yld Year if Short == "$where" & Year >= 2000, $scatter_options color(black)) ///
(scatter i_yld Year if Short == "$where" & Year >= 2000 & yld == ., mlcolor(black) msize(1.4) mcolor(white)) ///
, xtitle("") ytitle("Days Lost (Average)") legend(order(1 "Observed" 2 "Imputed") position(12) rows(1)) xlabel(2000(5)2025) scale(1.2) subtitle("{it:$where}", span position(11) ring(4) justification(left))

// Countries with data per region
list Short Year CountriesObs Countries Population Represented if Short == "World" & Year >= 1990, sep(0)
list Short Year CountriesObs Countries Population Represented if Short == "Americas" & Year >= 1990, sep(0)
list Short Year CountriesObs Countries Population Represented if Short == "Asia" & Year >= 1990, sep(0)
list Short Year CountriesObs Countries Population Represented if Short == "Europe" & Year >= 1990, sep(0)
list Short Year CountriesObs Countries Population Represented if Short == "Oceania" & Year >= 1990, sep(0)
list Short Year CountriesObs Countries Population Represented if Short == "Africa" & Year >= 1990, sep(0)

graph twoway ///
(line CountriesObs Year if Short == "World", color(black) lwidth(.4) lpattern(shortdash)) ///
(scatter CountriesObs Year if Short == "Americas", $scatter_options color(black)) ///
(scatter CountriesObs Year if Short == "Asia", $scatter_options color(black) msymbol(triangle)) ///
(scatter CountriesObs Year if Short == "Europe", $scatter_options color(gs9)) ///
(scatter CountriesObs Year if Short == "Oceania", $scatter_options color(gs9) msymbol(triangle)) ///
if Year >= 2000, xtitle("") ytitle("Countries w/ Data") legend(order(1 "World" 2 "Americas" 3 "Asia" 4 "Europe" 5 "Oceania") position(12) rows(1)) xlabel(2000(5)2025) scale(1.2) subtitle("(A) {it:World & Regions}", span position(11) ring(4) justification(left))


*Table
tab Short Year if (Year == 2000 | Year == 2011 | Year == 2021) & (Short == "World" | Short == "Americas" | Short == "Asia" | Short == "Europe" | Short == "Oceania" | Short == "United States"), sum(i_yld) mean

tab Year Short if Year >= 2000 & (Short == "World" | Short == "Americas" | Short == "Asia" | Short == "Europe" | Short == "Oceania" | Short == "United States"), sum(i_yld) mean

**# Scatterplot
use "Replication Data.dta", clear
global scatter_options mlcolor(white) mlalign(outside) lwidth(.4)
// ssc install egenmore

// Select
drop if pop2022 <= 1000000

gen esample = 0
replace esample = 1 if yld ~= .
bysort Country: egen Years = total(esample)
drop if Years < 10

drop if Year < 2010

// Standardized
foreach i of var yld WHO_HomRate {
	egen std_`i' = std(`i')
}

// Collapse
collapse (mean) yld WHO_HomRate, by(ISO2 eCountry)

// Gen
gen ln_WHO_HomRate = log(WHO_HomRate)
gen ln_yld = log(yld)

// Residual
reg yld WHO_HomRate
predict resid, resid

reg ln_yld ln_WHO_HomRate
predict ln_resid, resid

sort ln_resid
list eCountry ISO2 ln_resid resid


// Plot
graph twoway (scatter yld WHO_HomRate, $scatter_options color(black)) (lfit yld WHO_HomRate, color(gray) lpattern(shortdash)), legend(off) xtitle("Homcide Rate (pcm)") ytitle("Days Lost (Average)")

graph twoway (scatter yld WHO_HomRate, $scatter_options color(black) mlabel(ISO2) mlabcolor(black) ) (lfit yld WHO_HomRate)
graph twoway (scatter yld WHO_HomRate, $scatter_options color(black) msymbol(i) mlabel(ISO2) mlabcolor(black) mlabposition(0)) (lfit yld WHO_HomRate, color(gray) lpattern(shortdash)), legend(off)

// Log-Log
graph twoway (scatter ln_yld ln_WHO_HomRate, $scatter_options color(black) mlabel(ISO2) mlabcolor(black)) (lfit ln_yld ln_WHO_HomRate, color(gray) lpattern(shortdash)), legend(off)

// Labels
graph twoway (scatter yld WHO_HomRate, $scatter_options msize(1.4) color(black)) (lfit yld WHO_HomRate, lwidth(.6) color(gray) lpattern(shortdash)), legend(off) xtitle("Homcide Rate (pcm)") ytitle("Days Lost (Average)") subtitle("(A) {it:Full Sample (Markers)}", span position(11) ring(4) justification(left)) scale(1.2) 

graph twoway (scatter yld WHO_HomRate, $scatter_options msize(1.4) color(black) msymbol(i) mlabel(ISO2) mlabcolor(black) mlabposition(0)) (lfit yld WHO_HomRate, lwidth(.6) color(gray) lpattern(shortdash)), legend(off) xtitle("Homcide Rate (pcm)") ytitle("Days Lost (Average)") subtitle("(A) {it:Extreme Cases (Labels)}", span position(11) ring(4) justification(left)) scale(1.2) xlabel(0(20)60) ylabel(0(2)8)

// Jittered
	// Does not work with labels
graph twoway (scatter yld WHO_HomRate, jitter(10) $scatter_options msize(1.4) color(black)) (lfit yld WHO_HomRate, lwidth(.6) color(gray) lpattern(shortdash)), legend(off) xtitle("Homcide Rate (pcm)") ytitle("Days Lost (Average)") subtitle("(A) {it:Full Sample (Markers)}", span position(11) ring(4) justification(left)) scale(1.2) 


// Selected Labels
	// https://www.statalist.org/forums/forum/general-stata-discussion/general/1393421-markers-on-scatter-plot-overlapping-the-labels
	// All Labels
graph twoway (scatter yld WHO_HomRate, $scatter_options msize(1.4) color(black) msymbol(i) mlabel(ISO2) mlabcolor(black) mlabposition(0) mlabsize(medium)) (lfit yld WHO_HomRate, lwidth(.6) color(gray) lpattern(shortdash)), legend(off) xtitle("Homcide Rate (pcm)") ytitle("Days Lost (Average)") subtitle("(A) {it:Extreme Cases (Labels)}", span position(11) ring(4) justification(left)) scale(1.2) xlabel(0(20)60) ylabel(0(2)8)

gen selected = 0
gen pos = 3

replace selected = 2 if ISO2 == "US"
replace selected = 1 if ISO2 == "RU" | ISO2 == "UA" | ISO2 == "TM" | ISO2 == "LV" | ISO2 == "PH" // Negative Residuals (Lower years lost than predicted by the homicide rate)
replace selected = 2 if ISO2 == "SV" | ISO2 == "CO" | ISO2 == "PR" | ISO2 == "VE" | ISO2 == "PA" | ISO2 == "BR" | ISO2 == "CR" // Positive Residuals (Higher years lost than predicted by the homicide rate)

replace pos = 12 if ISO2 == "US"
replace pos = 12 if selected == 2
replace pos = 6 if selected == 1

graph twoway ///
(scatter yld WHO_HomRate, mlcolor(black) msize(1.4) color(white)) /// 
(scatter yld WHO_HomRate if selected ~= 0, $scatter_options msize(2) color(black) mlabel(ISO2) mlabcolor(black) mlabv(pos) mlabsize(medium)) ///
(lfit yld WHO_HomRate, lwidth(.6) color(gray) lpattern(shortdash)) ///
, legend(off) xtitle("Homcide Rate (pcm)") ytitle("Days Lost (Average)") subtitle("(B) {it:Selected Labels}", span position(11) ring(4) justification(left)) scale(1.2) xlabel(0(20)60) ylabel(0(2)8)


// Final
graph twoway (scatter yld WHO_HomRate,  mlcolor(black) msize(1.4) color(white)) (lfit yld WHO_HomRate, lwidth(.6) color(gray) lpattern(shortdash)), legend(off) xtitle("Homcide Rate (pcm)") ytitle("Days Lost (Average)") subtitle("(A) {it:Full Sample Markers}", span position(11) ring(4) justification(left)) scale(1.2) 

graph twoway (scatter yld WHO_HomRate if selected == 1, $scatter_options msize(1.4) color(black) msymbol(i) mlabel(ISO2) mlabcolor(black) mlabposition(0) mlabsize(medium) ) (lfit yld WHO_HomRate, lwidth(.6) color(gray) lpattern(shortdash)), legend(off) xtitle("Homcide Rate (pcm)") ytitle("Days Lost (Average)") subtitle("(B) {it:Selected Labels}", span position(11) ring(4) justification(left)) scale(1.2) xlabel(0(20)60) ylabel(0(2)8)

// Most negative residuals are from the former USSR; positive are from the Americas



**# Age Table
use "Replication Data.dta", clear

keep if Year == 2021
keep Short Code Country Region Subregion tl_0_4-tl_95_99 pop_0_4-pop_95_99

foreach i in 0_4 5_9 10_14 15_19 20_24 25_29 30_34 35_39 40_44 45_49 50_54 55_59 60_64 65_69 70_74 75_79 80_84 85_89 90_94 95_99 {
	preserve
	collapse (mean) tl_`i' [pweight=pop_`i']
	save "Data/Ages/World_`i'", replace
	restore
	
	preserve
	collapse (mean) tl_`i' [pweight=pop_`i'], by(Region)
	save "Data/Ages/Region_`i'", replace
	restore
}

use Data/Ages/Region_0_4, clear
foreach i in 5_9 10_14 15_19 20_24 25_29 30_34 35_39 40_44 45_49 50_54 55_59 60_64 65_69 70_74 75_79 80_84 85_89 90_94 95_99 {
	merge 1:1 Region using "Data/Ages/Region_`i'", nogenerate
}

save "Data/Ages/Region", replace

use Data/Ages/World_0_4, clear
foreach i in 5_9 10_14 15_19 20_24 25_29 30_34 35_39 40_44 45_49 50_54 55_59 60_64 65_69 70_74 75_79 80_84 85_89 90_94 95_99 {
	merge 1:1 _n using "Data/Ages/World_`i'", nogenerate
}

gen Region = "World", before(tl_0_4)
save "Data/Ages/World", replace

// Append
use "Replication Data.dta", clear

keep if Year == 2021
keep Short Code Country Region Subregion tl_0_4-tl_95_99 pop_0_4-pop_95_99

keep if Short == "United States"
keep Region tl_*
replace Region = "United States"

append using "Data/Ages/World"
append using "Data/Ages/Region"

save "Data/Ages/Merged", replace

// Reshape
use "Data/Ages/Merged", clear

reshape long tl_, i(Region) j(age_string) string 

gen age = trim(substr(age_string, 1, strpos(age_string, "_") - 1)), before(age_string)
destring age, replace
replace age = age / 5
gsort Region age

// Label
label define lab_age 0 "0-4" 1 "5-9" 2 "10-14" 3 "15-19" 4 "20-24" 5 "25-29" 6 "30-34" 7 "35-39" 8 "40-44" 9 "45-49" 10 "50-54" 11 "55-59" 12 "60-64" 13 "65-69" 14 "70-74" 15 "75-79" 16 "80-84" 17 "85-89" 18 "90-94" 19 "95-99"

label val age lab_age

save "Data/Ages/Long", replace

*Descriptives
use "Data/Ages/Long", clear

list tl_ age if Region == "World"
list tl_ age if Region == "Americas"
list tl_ age if Region == "Asia"
list tl_ age if Region == "Europe"
list tl_ age if Region == "Oceania"

list tl_ age if Region == "United States"

// Sum
encode Region, gen (eRegion)
total tl_, over(eRegion)

*Plot
use "Data/Ages/Long", clear
global scatter_options connect(l) mlcolor(white) mlalign(outside) lwidth(.4)

// World & Regions
graph twoway ///
(line tl_ age if Region == "World", color(black) lwidth(.4) lpattern(shortdash)) ///
(scatter tl_ age if Region == "Americas", $scatter_options color(black)) ///
(scatter tl_ age if Region == "Asia", $scatter_options color(black) msymbol(triangle)) ///
(scatter tl_ age if Region == "Europe", $scatter_options color(gs9)) ///
(scatter tl_ age if Region == "Oceania", $scatter_options color(gs9) msymbol(triangle)) ///
, xtitle("Age Group") ytitle("Days Lost (Average)") legend(order(1 "World" 2 "Americas" 3 "Asia" 4 "Europe" 5 "Oceania") position(12) rows(1)) xlabel(0 "0-4" 1 "5-9" 2 "10-14" 3 "15-19" 4 "20-24" 5 "25-29" 6 "30-34" 7 "35-39" 8 "40-44" 9 "45-49" 10 "50-54" 11 "55-59" 12 "60-64" 13 "65-69" 14 "70-74" 15 "75-79" 16 "80-84" 17 "85-89" 18 "90-94" 19 "95-99", angle(45)) scale(1.2) subtitle("(A) {it:World & Regions}", span position(11) ring(4) justification(left))

// US & World
graph twoway (scatter tl_ age if Region == "United States", $scatter_options color(black)) (line tl_ age if Region == "World", color(black) lwidth(.4) lpattern(shortdash)) ///
, xtitle("Age Group") ytitle("Days Lost (Average)") legend(order(1 "United States" 2 "World") position(12) rows(1)) xlabel(0 "0-4" 1 "5-9" 2 "10-14" 3 "15-19" 4 "20-24" 5 "25-29" 6 "30-34" 7 "35-39" 8 "40-44" 9 "45-49" 10 "50-54" 11 "55-59" 12 "60-64" 13 "65-69" 14 "70-74" 15 "75-79" 16 "80-84" 17 "85-89" 18 "90-94" 19 "95-99", angle(45)) ylabel(0(2)8) scale(1.2) subtitle("(B) {it:United States & the World}", span position(11) ring(4) justification(left))



**# Descriptions
use "Replication Data.dta", clear

*Data availability
tab Year if WHO_Hom ~= .


**# List of Countries
use "Replication Data.dta", clear

drop if Year == 2022 // Only 18 countries with data

*Imputation
tsset eCountry Year, yearly

foreach i of var yld WHO_HomRate GDP_Current_PerCap {
gsort eCountry Year
ipolate `i' Year, gen(i_`i') by(eCountry)
bysort eCountry: replace i_`i' = i_`i'[_n-1] if i_`i'==.
gsort eCountry -Year
bysort eCountry: replace i_`i' = i_`i'[_n-1] if i_`i'==.
gsort eCountry Year
}

gen esample = 0
replace esample = 1 if yld ~= .

unique Short
unique Short if Region == "Africa"

drop if yld == .
drop if Year <= 2000

collapse (last) i_yld Pop Last = Year i_WHO_HomRate i_GDP_Current_PerCap (first) First = Year (sum) Years = esample, by(Short Region)

order Region Short i_yld Pop Years First Last i_WHO_HomRate i_GDP_Current_PerCap

sort Region Short
list Region Short i_yld i_WHO_HomRate i_GDP_Current_PerCap Years First Last Pop

list Region Short i_yld Years First Last Pop

export excel using "Results\List of Countries.xlsx", firstrow(variables) replace


**# US Age & Crime Figure
use "Replication Data.dta", clear

egen WHO_Hom_0_4 = rowtotal(WHO_Hom_0 WHO_Hom_1 WHO_Hom_2 WHO_Hom_3 WHO_Hom_4)

egen Pop_0_4 = rowtotal(Pop_0 Pop_1 Pop_2 Pop_3 Pop_4)
egen Pop_5_9 = rowtotal(Pop_5 Pop_6 Pop_7 Pop_8 Pop_9)

forvalues x = 1/9 {
	egen Pop_`x'0_`x'4 = rowtotal(Pop_`x'0 Pop_`x'1 Pop_`x'2 Pop_`x'3 Pop_`x'4)
	egen Pop_`x'5_`x'9 = rowtotal(Pop_`x'5 Pop_`x'6 Pop_`x'7 Pop_`x'8 Pop_`x'9)
}

egen Pop_95_ = rowtotal(Pop_95 Pop_96 Pop_97 Pop_98 Pop_99 Pop_100_)


foreach i in 0_4 5_9 10_14 15_19 20_24 25_29 30_34 35_39 40_44 45_49 50_54 55_59 60_64 65_69 70_74 75_79 80_84 85_89 90_94 95_ {
	gen HomRate_`i' = (WHO_Hom_`i' / Pop_`i') * 100000
}

egen WHO_Hom_80_ = rowtotal(WHO_Hom_80_84 WHO_Hom_85_89 WHO_Hom_90_94 WHO_Hom_95_)
egen Pop_80_ = rowtotal(Pop_80-Pop_100_)

gen HomRate_80_ = (WHO_Hom_80_ / Pop_80_) * 100000

save "Data/Ages/Age_Crime", replace


* Reshape
use "Data/Ages/Age_Crime", clear

keep Code Year WHO_Hom WHO_HomRate HomRate_0_4 HomRate_5_9 HomRate_10_14 HomRate_15_19 HomRate_20_24 HomRate_25_29 HomRate_30_34 HomRate_35_39 HomRate_40_44 HomRate_45_49 HomRate_50_54 HomRate_55_59 HomRate_60_64 HomRate_65_69 HomRate_70_74 HomRate_75_79 HomRate_80_

keep if Code == "USA"

reshape long HomRate_, i(Year) j(age_string) string 

gen age = trim(substr(age_string, 1, strpos(age_string, "_") - 1)), before(age_string)
destring age, replace
replace age = age / 5
gsort Year age

// Label
label define lab_age 0 "0-4" 1 "5-9" 2 "10-14" 3 "15-19" 4 "20-24" 5 "25-29" 6 "30-34" 7 "35-39" 8 "40-44" 9 "45-49" 10 "50-54" 11 "55-59" 12 "60-64" 13 "65-69" 14 "70-74" 15 "75-79" 16 "80+"

label val age lab_age


* Plot
global scatter_options connect(l) mlcolor(white) mlalign(outside) lwidth(.4)

// US
graph twoway ///
(scatter HomRate_ age if Year == 1990, $scatter_options color(gs9) msymbol(triangle)) ///
(scatter HomRate_ age if Year == 2000, $scatter_options color(gs9)) ///
(scatter HomRate_ age if Year == 2010, $scatter_options color(black) msymbol(triangle)) ///
(scatter HomRate_ age if Year == 2020, $scatter_options color(black)) ///
, xtitle("Age Group") ytitle("Homicide Rate (p/ 100k pop.)") legend(order(1 "1990" 2 "2010" 3 "2015" 4 "2020") position(12) rows(1)) xlabel(0 "0-4" 1 "5-9" 2 "10-14" 3 "15-19" 4 "20-24" 5 "25-29" 6 "30-34" 7 "35-39" 8 "40-44" 9 "45-49" 10 "50-54" 11 "55-59" 12 "60-64" 13 "65-69" 14 "70-74" 15 "75-79" 16 "80+", angle(45)) scale(1.2) subtitle("(A) {it:United States}", span position(11) ring(4) justification(left))

// Descriptives
list HomRate_ age if Year == 2020