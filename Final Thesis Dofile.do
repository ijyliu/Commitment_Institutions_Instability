// Thesis Dofile
// Committment Institutions and Instability
// Isaac Liu

clear
macro drop _all

// Set working directory
cd "C:\Users\Isaac Liu\OneDrive - Georgetown University\Senior\Spring Class\Thesis"

// Data collection and cleaning

// VDEM
// Select out critical variables (since Stata version will not accommodate all of them)
use country_name year v2elturnhog v2elturnhos v2eltvrexo v2eltvrig v3eltvriguc e_coups e_wbgi_pve e_mipopula v2petersch e_migdppc e_civil_war e_miinterc e_pt_coup v2elreggov v2x_horacc v3eldirepr v2exhoshog v2lglegplo e_polity2 using V-Dem-CY-Full+Others-v10, clear

label var v2elturnhog "Head of Govt. Turnover"
label var v2elturnhos "Head of State Turnover"
label var v2eltvrig "Lower House Turnover"
label var e_wbgi_pve "WB Political Stability (Absence of Violence)"
label var v2petersch "Tertiary Education Enrollment (V-Dem)"
label var v2exhoshog "HOS = HOG"
label var v2lglegplo "Legislative Efficacy"
label var e_polity2 "Polity Democracy Score (v2)"

// Variables are, respectively, country, year, head of government turnover event, head of state turnover event, executive turnover, lower chamber turnover, upper chamber turnover, coups (PIPE), WGI political stability, total population, tertiary school enrollment, GDP per capita, civil war, internal armed conflict, coups d'etat, existance of regional governments, horizontal accountability (checks and balances).

* The last four added are direct presidential elections, whether hos is the same as hog, whether lower chamber legislates in practice, and the polity revised combined score of democracy

// Notes
// HOG turnover is coded as 0 for the same HOG, 1 for a diff individual or a change in coalition (parli) or leadership, 2 for a loss of position- diff person and diff party, in parli new party, or if first for newly ind.
// Same applies for HOS turnover
// Exec turnover- change in both head of state and govt. 0 for same hos and hog, 1 for change in individual for either hog or hos- in parli if hog ruling coalition change semi-prez cohabitation, 2 if hos and hog lost positions- in presidential new prez and party, in parli- new party for hog, in semi-prez end of cohabitation or total change
// Lower Chamber turnover- 0 if majority the same parties, 1 if minority assumes the lead but is dependent, or if some old and new, 2 if incumbent lost the majority or plurality dom position
// Upper Chamber turnover- 0 if same party, 1 if leading position in coalition changes, 2 if another party or coalition gains control
// e_coups- number of successful coups in a year
// e_wbgi_pve- combo of several vars to determine perception of overthrow threat etc.
// e_mipopula- total population in thousands
// v2petersch percentage of tertiary age population in tertiary school from Barro et al
// GDP per capita- from Maddison project
// Civil war- binary variable for intrastate war with 1K or more deaths
// Internal armed conflict binary
// Coups d'etat- 0 for no attempts, 1 for unsuccessful, 2 for successful
// Regional government existence 0 or 1
// Horizontal accoutnability and checks and balances- a normalized scale representing checks and balances

* Ranges and notes for the last few
* direct presidential elections are 0 for indirect, 1 for direct, adn 2 for mixed.
* whether hos is the same as hog is binary 0 no 1 yes
* whether lower chamber legislates in practice, is a 0 for no, one for usuallly, and 2 for always
* the polity revised combined score of democracy goes from -10 autocratic to 10 democratic

// Create aggregate GDP from per capita values and population
gen aggGDP = e_mipopula*e_migdppc
label var aggGDP "Aggregate GDP (V-Dem)"

// Sample restriction
drop if year < 1970

// Data cleaning
duplicates drop
// Get a sense of the data
sum
// Missing data analysis
// Turnover events appear to be coded as missing in years with no elections, which is good. Unfortunately NO upper chamber turnover observations are available for this period- but hopely lower chamber values will suffice. World governance indicator values for political violence are for recent dates only. Coup data from PIPE is not fully available. GDP data is very broad in coverage. Population is often missing. Internal conflict and civil war data has some gaps. Finally, coverage for the vdem PT coup variable is very good.
// Min-Max sense check
// Country name and year appear to be in order. Turnover events appear to be in the correct 0 to 2 range. Regional government binary is in order. Tertiary schooling percentages are logical if high for nome nations. Horizonal acc and WGI indices appear to be in anticipated ragnes. Coups ranges are good. gdp per capita ranges from 134 to 220717 which seems somewhat high but not unrealistic. Populaiton clocks in the correct ranges up to a billion. Civil war and internal conflict variables also appear to be in correct ranges.

* Of the new additions direct presidential elections data is actually missing in this edition.
* whether hos is the same as hog is in correct range
* whether lower chamber legislates in practice, has a weird normalized/sd looking distribution. Aggregation must be done in a unique fashion.
* the polity revised combined score is exactly in range from -10 to 10

// Create an instability event variable for an attempted coup, civil war, or internal conflict.
gen instabEvent = (e_civil_war | e_miinterc | (e_coups != 0) | (e_pt_coup != 0)) if (e_civil_war != . | e_miinterc != .) & (e_coups != . | e_pt_coup != .)
label var instabEvent "Instability Event Indicator"

* For later- it's already binary really
gen binstabEvent = instabEvent
label var binstabEvent "Instability Event Indicator"

* Binary stability variables
gen bv2elturnhog = (v2elturnhog >= 1) if v2elturnhog != .
gen bv2elturnhos = (v2elturnhos >= 1) if v2elturnhos != .
gen bv2eltvrig = (v2eltvrig >= 1) if v2eltvrig != .
gen be_wbgi_pve = (e_wbgi_pve >= 0) if e_wbgi_pve != .
* For turnover also make extra b2 versions
gen b2v2elturnhog = (v2elturnhog > 1) if v2elturnhog != .
gen b2v2elturnhos = (v2elturnhos > 1) if v2elturnhos != .
gen b2v2eltvrig = (v2eltvrig > 1) if v2eltvrig != .
egen mwbgi = median(e_wbgi_pve)
gen b2e_wbgi_pve = (e_wbgi_pve >= mwbgi) if e_wbgi_pve != .

save Clean_VDem, replace

// From PIPE- actually not super necessary
* autocoups did_not_run salterl

// DPI checks and balances and federalism
use DPI2017_stata13, clear
ren countryname country_name
drop if country_name == ""
drop if year < 1970
keep country_name year checks auton author

// Checks and balances scartascini iadb (DPI) is checks
// federalism measures (DPI): auton, author
// autonomy existence and authority over taxing and spending for subnationals

// Missing value analysis and corrections
local DPIVars "checks auton author"
foreach variable in `DPIVars' {
replace `variable' = . if `variable' == -999
}

sum
// Indices appear to be in correct range for min and max. Large number of author observations are missing, as expected.
duplicates report
// No dups.

// Align country names
replace country_name = "Bosnia and Herzegovina" if country_name == "Bosnia-Herz"
replace country_name = "Burma/Myanmar" if country_name == "Myanmar"
replace country_name = "Central African Republic" if country_name == "Cent. Af. Rep."
replace country_name = "Cape Verde" if country_name == "C. Verde Is."
replace country_name = "China" if country_name == "PRC"
replace country_name = "Comoros" if country_name == "Comoro Is."
replace country_name = "Republic of the Congo" if country_name == "Congo"
replace country_name = "Democratic Republic of the Congo" if country_name == "Congo (DRC)"
replace country_name = "Dominican Republic" if country_name == "Dom. Rep."
replace country_name = "Equatorial Guinea" if country_name == "Eq. Guinea"
replace country_name = "Eswatini" if country_name == "Swaziland"
replace country_name = "Germany" if country_name == "FRG/Germany"
replace country_name = "German Democratic Republic" if country_name == "GDR"
replace country_name = "The Gambia" if country_name == "Gambia"
replace country_name = "Ivory Coast" if country_name == "Cote d'Ivoire"
replace country_name = "North Korea" if country_name == "PRK"
replace country_name = "North Macedonia" if country_name == "Macedonia"
replace country_name = "Papua New Guinea" if country_name == "P. N. Guinea"
replace country_name = "Republic of Vietnam" if country_name == "Vietnam"
replace country_name = "Solomon Islands" if country_name == "Solomon Is."
replace country_name = "South Africa" if country_name == "S. Africa"
replace country_name = "South Korea" if country_name == "ROK"
replace country_name = "South Yemen" if country_name == "Yemen (PDR)"
replace country_name = "Trinidad and Tobago" if country_name == "Trinidad-Tobago"
replace country_name = "United Arab Emirates" if country_name == "UAE"
replace country_name = "United Kingdom" if country_name == "UK"
replace country_name = "United States of America" if country_name == "USA"

save Clean_DPI, replace

// Visser's index of corporatism
import excel Visser_Corp, sheet("ICTWSS6.0") firstrow clear
rename country country_name
keep country_name year Coord Type
// Coordination goes from 1 for fragmented wage bargaining to 5 with centralized. Type goes from 0 for no govt intervention to 6 for governmetn imposed bargaining/statutory controls.
destring Coord, replace
destring Type, replace
drop if year < 1970

// Data cleaning
sum
// There is an OK amount of missing data. Index values seem to be in line.
duplicates report
// No duplicates

// Align country names
replace country_name = "Hong Kong" if country_name == "Hong Kong, China"
replace country_name = "South Korea" if country_name == "Korea, Republic of"
replace country_name = "Russia" if country_name == "Russian Federation"
replace country_name = "Slovakia" if country_name == "Slovak Republic"
replace country_name = "Taiwan" if country_name == "Taiwan, China"

save Clean_Visser, replace

* Not really needed:
// CSP Armed Conflict- CIVVIOL CIVWAR ETHVIOL ETHWAR CIVTOT
// WB world governance indicators PV.EST

// CBI Garriga statutory
use "CBI Data", clear

// Variables are creation, reform, direction, increase, decrease, regional, lvau_garriga, lvaw_garriga, cuk_ceo, cuk_obj, cuk_pol, cuk_limlen, lvau_garriga_old, lvaw_garriga_old.
// We have when a cb was created, when there was a reform, inc or decrease, and whether the cb is regional/for more than one country. Most reforms increase CWN's weighted index.
// The components of CWN are ceo characteristics/laws on appointment dismissal and term of office, objectives of the CB, policy fromulation attribution- role in the budget and monetary policy, and limits on lending to the public sector.
// LVAU is the unweighted CBI index, and LVAW is weighted. Index is normalized from 0 to 1.

// Cleaning
sum
// Data goes from 1970 to 2012.
// Min-Max Check
// All of the binary variables appear to be 0 and 1. The direction variable indicates -1 or 1 or zero for inc and dec correctly. Indices do appear to be normalized 0 to 1.
// Missing data- all countries and years appear to be filled in on binaries. The full index is missing in about 1000 cases, but this is still plenty of data.

// Create CBI dummy variables
gen uHighCBI = (lvau_garriga > 0.5) if lvau_garriga != .
gen wHighCBI = (lvaw_garriga > 0.5) if lvau_garriga != .

duplicates report
// No duplicates.

// Prepare for merging
rename cname country_name

// Align country names
replace country_name = "Bosnia and Herzegovina" if country_name == "Bosnia-Herzegovina"
replace country_name = "Burma/Myanmar" if country_name == "Myanmar (Burma)"
replace country_name = "Democratic Republic of the Congo" if country_name == "Congo, Democratic Republic of / Za"
replace country_name = "Eswatini" if country_name == "Swaziland"
replace country_name = "Ethiopia" if country_name == "Ethiopia (incl. Eritrea)"
replace country_name = "Republic of the Congo" if country_name == "Congo, Repbulic of"
replace country_name = "Russia" if country_name == "Russian Federation"
replace country_name = "Serbia" if country_name == "Serbia and Montenegro"
replace country_name = "South Korea" if country_name == "Korea, Republic of"
replace country_name = "Yemen" if country_name == "Yemen, North/Yemen Arab Rep."
replace country_name = "Democratic Republic of the Congo" if country_name == "Zaire"

// Country-year duplicates appear to be an issue
duplicates report country_name year
duplicates list country_name year
// invesigate Yemen obs 5318 to 5358
browse if country_name == "Yemen"
// No data in all the situations, so it does not matter what is dropped
duplicates drop country_name year, force

save Clean_Garriga_CBI, replace

// Romelli Grilli CBI extension- de facto CBI
* import excel "C:\Users\Isaac Liu\OneDrive - Georgetown University\Senior\Spring Class\Thesis\Romelli CBI.xlsx", sheet("CBI Indices") firstrow

* order country year

// Prepare for merging.
* rename country country_name

// Align country names
* replace country_name 

* save Clean_Grilli_CBI, replace

// Governor Turnover from Axel, Strum De Haan
. import excel "C:\Users\Isaac Liu\OneDrive - Georgetown University\Senior\Spring Class\Thesis\Axel Sturm De Haan Gov Turnover.xlsx", sheet("data v2018") firstrow clear

// Tidy up variables
drop countcentralbanks codewdi
rename country country_name
destring timetoregularturnover, replace
destring numberofactualturnovers, replace
destring regularturnoverdummy, replace
destring irregularturnoverdummy, replace
destring timeinoffice, replace
destring legalduration, replace

// Cleaning
sum

// Check codebook.
// Strange values- -999 no CB exists, -991 first gov after unavailable data, -881 first governor of this cb, -882 first two govs, -774 fourth reapp, -773, third reapp, -772 second reapp, -771 first reapp, -666 indefinite term in office, -555 position vacant

// NOTE- could consider no CB existing being a state of basically no central bank independence in later analysis.

local AxelVars "timetoregularturnover numberofactualturnovers regularturnoverdummy irregularturnoverdummy timeinoffice legalduration"

foreach variable in `AxelVars' {
tab `variable'
replace `variable' = . if `variable' == -999
* For now exclude cases where no CB exists. Could also come back later and sort back all the weird values for number of turnovers, legal duration, etc. if these variables should be used.
* For time in office, also handle the (few) vacant cb governor position cases
replace `variable' = . if `variable' == -555
}

// Missing values- only really an issue for time to regular turnover, legal duration. Coverage is generally extremely good.
// Duplicates
duplicates report
// No duplicates.

// Prep for merging

// Align country names
replace country_name = strtrim(country_name)
replace country_name = stritrim(country_name)
replace country_name = "Burma/Myanmar" if country_name == "Myanmar"
replace country_name = "Democratic Republic of the Congo" if country_name == "Congo, Dem. Rep."
replace country_name = "Egypt" if country_name == "Egypt, Arab Rep."
replace country_name = "Eswatini" if country_name == "Swaziland/Eswatini"
replace country_name = "Hong Kong" if country_name == "Hong Kong, China"
replace country_name = "Iran" if country_name == "Iran, Islamic Rep."
replace country_name = "Kyrgyzstan" if country_name == "Kyrgyz Republic"
replace country_name = "Laos" if country_name == "Lao PDR"
replace country_name = "Netherlands" if country_name == "Netherlands, The"
replace country_name = "North Macedonia" if country_name == "Macedonia, FYR"
replace country_name = "Republic of Vietnam" if country_name == "Vietnam"
replace country_name = "Russia" if country_name == "Russian Federation"
replace country_name = "South Korea" if country_name == "Korea, Rep."
replace country_name = "Syria" if country_name == "Syrian Arab Republic"
replace country_name = "The Gambia" if country_name == "Gambia, The"
replace country_name = "United States of America" if country_name == "United States"
replace country_name = "Venezuela" if country_name == "Venezuela, RB"
replace country_name = "Yemen" if country_name == "Yemen, Rep."
// Central bank of west african states
// Benin, Burkina Faso, Ivory Coast, Guinea Bissau, Mali, Niger, Senegal, Togo
// CB of central african states
// Cameroon, CAR, Chad, Rep of Congo, Eq Guinea, Gabon
// Eastern Carribean CB
// Anguilla, Antigua and Barbuda, Dominica, Grenada, Monteserrat, St Kitts and Nevis, St Lucia, St Vincent and the Grenadines

rename country_name cb_name

// Save file
save Clean_CBI_Turnover, replace

// Reinhart Rog ex reg class
import excel "C:\Users\Isaac Liu\OneDrive - Georgetown University\Senior\Spring Class\Thesis\ERA_Classification_Annual_1940-2016_Mod.xlsx", sheet("Fine") firstrow clear

// Tidying up variables
destring year, replace
order country_name year
sort country_name year

// Note on classifications
// Fine classifications for rate_regime are 1 for currency union, 2 for pre announced peg or board, 3 for narrow band (under 2 percent), 4 for de facto peg, 5 for crawling peg, 6 for crawling band, 7 for de facto crawling peg, 8 for de facto crawling band, 9 for pre announced crawling band of more than 2 percent, 10 for de facto crawling band under 5 percent, 11 for moving band under 2 percent, 12 for de facto moving band of more than 5 percent and managed float, 13 for free floating, 14 for free falling. 15 is for missing data.
replace rate_regime = . if rate_regime == 15
// As stated in the main text, I classify 1-8 as a fixed regime and 9-14 as floating.
gen float_rate = (rate_regime >= 9 & rate_regime <= 14) if rate_regime != .
gen fixed_rate = 1 - float_rate if float_rate != .

replace rate_regime = 15 - rate_regime

sum
// Min-max check. Rate regimes and years are in range.
// Missing values check. No missing values.
// Duplicates check. No duplicates.

// Align country names
replace country_name = strtrim(country_name)
replace country_name = stritrim(country_name)
replace country_name = "Azerbaijan" if country_name == "Azerbaijan Rep. of"
replace country_name = "Bahrain" if country_name == "Bahrain Kingdom of"
replace country_name = "Bosnia and Herzegovina" if country_name == "Bosnia & Herzegovina"
replace country_name = "Burma/Myanmar" if country_name == "Myanmar"
replace country_name = "Cape Verde" if country_name == "Cabo Verde"
replace country_name = "Central African Republic" if country_name == "Central African Rep."
replace country_name = "China" if country_name == "China, PR"
replace country_name = "Democratic Republic of the Congo" if country_name == "Congo Dem. Rep. of"
replace country_name = "Eswatini" if country_name == "Swaziland"
replace country_name = "Guinea-Bissau" if country_name == "Guinea Bissau"
replace country_name = "Ivory Coast" if country_name == `"Cote D"Ivoire"'
replace country_name = "Kyrgyzstan" if country_name == "Krygyz Rep."
replace country_name = "Laos" if country_name == "Lao Dem. Rep."
replace country_name = "South Korea" if country_name == "Korea"
replace country_name = "North Macedonia" if country_name == "Macedonia FYR"
replace country_name = "Palestine/West Bank" if country_name == "West Bank and Gaza"
replace country_name = "Papua New Guinea" if country_name == "PNG"
replace country_name = "Republic of Vietnam" if country_name == "Vietnam"
replace country_name = "Republic of the Congo" if country_name == "Congo Rep. of"
replace country_name = "Sao Tome and Principe" if country_name == "Sao Tome & Principe"
replace country_name = "Serbia" if country_name == "Serbia, Rep. of"
replace country_name = "Slovakia" if country_name == "Slovak Republic"
replace country_name = "Syria" if country_name == "Syrian Arab Rep."
replace country_name = "Trinidad and Tobago" if country_name == "Trinidad Tobago"
replace country_name = "United Arab Emirates" if country_name == "UAE"
replace country_name = "United States of America" if country_name == "United States"
replace country_name = "Yemen" if country_name == "Yemen Rep. of"

save Clean_RR, replace

// AREARS IMF on de jure rates and cap controls
// Rate data is only available since 2008! :(
import excel "C:\Users\Isaac Liu\OneDrive - Georgetown University\Senior\Spring Class\Thesis\AREARforCapConandDJRates.xlsx", sheet("AREAER-DataQueryReport_03.28.20") firstrow clear

gen stat = (Status == "yes") if Status != ""
drop Status

ren Country country_name
ren Year year
replace Category = subinstr(Category, " ", "_", .)
replace Category = "Capital_Controls" if Category == "Controls_on_capital_transactions"
replace Category = "Horizontal_Bands" if Category == "Pegged_exchange_rate_within_horizontal_bands"
replace Category = "Crawl" if Category == "Crawl-like_arrangement"

reshape wide stat, i(year country_name) j(Category) string

// Data cleaning
sum
// Huge number of observations missing for erates before 2008. Also, capital controls appear to be over-labeled with a mean of 0.91.

* I think this code is not needed.
*local erateDummies "statConventional_peg statCrawl statCrawling_peg statCurrency_board statFloating statFree_floating statHorizontal_Bands statNo_separate_legal_tender statOther_managed_arrangement statStabilized_arrangement"
*foreach variable in `erateDummies'{
*replace `variable' = 0 if `variable' == . & year > 2008
*}

egen floatAR = rowtotal(statFloating statFree_floating) if year > 2008

// Align country names

save Clean_AREARS, replace

// Polity IV
import excel p4v2018, firstrow clear

// Keep only relevant variables
keep country year xconst xrcomp xropen parreg parcomp
// These are respectively country, year, executive contraints, exec competitiveness, exec openness of recruitment, regulation of participation, and competitiveness of participation.
// Notes- xconst is on a scale from 1 meaning no limitations to 7 of parity or subordination. xrcomp is on a scale of 1 to 3 with 1 being selection or heriditary or designation, 3 being election. xropen or openness of selection to the population goes from 1 of closed succession/hereditary to 4 of elite designation or some form of election. parreg goes from 1 and no regulation to 5 and totally regulated and stable groups. parcomp is the competitiveness of participation- with there being a parreg not unregulated. 0 is not app, 1 repressed, 5 competitive.
// Transitions are often denoted -88. Foriegn interruption is -66. Interregnum or anarchy is -77.

// Clean data
sum
// No data is missing.
duplicates drop
// Two observations gone.
sum
// Min and max analysis- the max for each variable appears to be good.
// Clear out transitions and negative values:
foreach variable in xrcomp xropen xconst parreg parcomp {
replace `variable' = . if `variable' == -88 | `variable' == -77 | `variable' == -66
}
sum
// Still a lot of 0 observations for xrcomp and xropen that don't match to anything in the codebook.
replace xrcomp = . if xrcomp == 0
replace xropen = . if xropen == 0

// Align country names
rename country country_name

replace country_name = "Bosnia and Herzegovina" if country_name == "Bosnia"
replace country_name = "Burma/Myanmar" if country_name == "Myanmar (Burma)"
replace country_name = "Democratic Republic of the Congo" if country_name == "Congo Kinshasa"
replace country_name = "Eswatini" if country_name == "Swaziland"
replace country_name = "German Democratic Republic" if country_name == "Germany East"
replace country_name = "North Korea" if country_name == "Korea North"
replace country_name = "North Macedonia" if country_name == "Macedonia"
replace country_name = "Slovakia" if country_name == "Slovak Republic"
replace country_name = "South Korea" if country_name == "Korea South"
replace country_name = "Timor-Leste" if country_name == "Timor Leste"
replace country_name = "United Arab Emirates" if country_name == "UAE"
replace country_name = "United States of America" if country_name == "United States"

drop if year < 1970

// Create binaries for high/low exec contraints and openness.
// Executive constraints.
hist xconst
sum xconst, detail
// Given a 50th percentile for xconst at 5 on a scale of 1-7 and mean above 4, we should set 1-4 as low exec constraints and 5-7 as high ones.
// (No need to account for missing data since there is none in polity.)
gen hxconst4 = (xconst > 4)
// As an alternative:
gen hxconst5 = (xconst > 5)
// Openness
hist xropen
// Vast majority of nations are open with a score of 4. Only several monarchies have scores under 4. parcomp may be a better variable.
hist parcomp
sum parcomp, detail
// Mean around 3, fiftieth percentile at 3.
gen hcomp3 = (parcomp > 3)

// Save.
save Clean_Polity4, replace

// Chinn Ito KAOPEN index capital control openness
use kaopen_2017, clear
keep country_name year ka_open

* Cleaning
sum
* Data availability is very good: 1970 up to 2017 as desired. And 7.2K observations. ka_open is the normalized index from zero to one. It is compiled from IMF data, and higher values mean a more open capital account/fewer capital controls. Range appears to be good.
duplicates drop

* Align country names
replace country_name = "Burma/Myanmar" if country_name == "Myanmar"
replace country_name = "Democratic Republic of the Congo" if country_name == "Congo, Dem. Rep."
replace country_name = "Egypt" if country_name == "Egypt, Arab Rep."
replace country_name = "Eswatini" if country_name == "Swaziland"
replace country_name = "Hong Kong" if country_name == "Hong Kong, China"
replace country_name = "Iran" if country_name == "Iran, Islamic Rep."
replace country_name = "Ivory Coast" if country_name == "C?e d'Ivoire"
replace country_name = "Kyrgyzstan" if country_name == "Kyrgyz Republic"
replace country_name = "Laos" if country_name == "Lao PDR"
replace country_name = "North Macedonia" if country_name == "Macedonia, FYR"
replace country_name = "Republic of the Congo" if country_name == "Congo, Rep."
replace country_name = "Russia" if country_name == "Russian Federation"
replace country_name = "Sao Tome and Principe" if country_name == "S? Tom�and Principe"
replace country_name = "Slovakia" if country_name == "Slovak Republic"
replace country_name = "South Korea" if country_name == "Korea, Rep."
replace country_name = "Syria" if country_name == "Syrian Arab Republic"
replace country_name = "The Gambia" if country_name == "Gambia, The"
replace country_name = "United States of America" if country_name == "United States"
replace country_name = "Venezuela" if country_name == "Venezuela, RB"
replace country_name = "Yemen" if country_name == "Yemen, Rep."

save Clean_kaopen, replace

// OECD social science and biz grad
import excel "C:\Users\Isaac Liu\OneDrive - Georgetown University\Senior\Spring Class\Thesis\OECD Tert Grads.xlsx", sheet("DP_LIVE_22032020015002769") firstrow clear
keep LOCATION SUBJECT TIME Value
keep if SUBJECT == "SOC_SCI" | SUBJECT == "BUSINESS"
order LOCATION TIME

// Combine Social Science and Business Numbers
collapse (sum) Value, by(LOCATION TIME)

// Data Cleaning
sum
tab Value
// Suspiciously large number of 0 observations, which seem very unrealistic
replace Value = . if Value == 0
sum
// The share now ranges from 19 percent to 56 percent.
duplicates report
// No duplicates
// Make value more readily interpretable
replace Value = Value/100
ren LOCATION country_name
ren TIME year
ren Value ssbizsh

// Align country names
replace country_name = strtrim(country_name)
replace country_name = "Argentina" if country_name == "ARG"
replace country_name = "Australia" if country_name == "AUS"
replace country_name = "Austria" if country_name == "AUT"
replace country_name = "Belgium" if country_name == "BEL"
replace country_name = "Brazil" if country_name == "BRA"
replace country_name = "Canada" if country_name == "CAN"
replace country_name = "Switzerland" if country_name == "CHE"
replace country_name = "Chile" if country_name == "CHL"
replace country_name = "China" if country_name == "CHN"
replace country_name = "Colombia" if country_name == "COL"
replace country_name = "Costa Rica" if country_name == "CRI"
replace country_name = "Czech Republic" if country_name == "CZE"
replace country_name = "Germany" if country_name == "DEU"
replace country_name = "Denmark" if country_name == "DNK"
replace country_name = "Spain" if country_name == "ESP"
replace country_name = "Estonia" if country_name == "EST"
replace country_name = "Finland" if country_name == "FIN"
replace country_name = "France" if country_name == "FRA"
replace country_name = "United Kingdom" if country_name == "GBR"
replace country_name = "Greece" if country_name == "GRC"
replace country_name = "Hungary" if country_name == "HUN"
replace country_name = "Indonesia" if country_name == "IDN"
replace country_name = "India" if country_name == "IND"
replace country_name = "Ireland" if country_name == "IRL"
replace country_name = "Iceland" if country_name == "ISL"
replace country_name = "Israel" if country_name == "ISR"
replace country_name = "Italy" if country_name == "ITA"
replace country_name = "Japan" if country_name == "JPN"
replace country_name = "South Korea" if country_name == "KOR"
replace country_name = "Lithuania" if country_name == "LTU"
replace country_name = "Luxembourg" if country_name == "LUX"
replace country_name = "Latvia" if country_name == "LVA"
replace country_name = "Mexico" if country_name == "MEX"
replace country_name = "Netherlands" if country_name == "NLD"
replace country_name = "Norway" if country_name == "NOR"
replace country_name = "New Zealand" if country_name == "NZL"
replace country_name = "Poland" if country_name == "POL"
replace country_name = "Portugal" if country_name == "PRT"
replace country_name = "Russia" if country_name == "RUS"
replace country_name = "Saudi Arabia" if country_name == "SAU"
replace country_name = "Slovakia" if country_name == "SVK"
replace country_name = "Slovenia" if country_name == "SVN"
replace country_name = "Sweden" if country_name == "SWE"
replace country_name = "Turkey" if country_name == "TUR"
replace country_name = "United States of America" if country_name == "USA"
replace country_name = "South Africa" if country_name == "ZAF"

save Clean_OECD_Thesis, replace

* World Bank data on population, GDP PPP 2011 IDollars, tertiary education enrollment percent.
wbopendata, indicator(SP.POP.TOTL; NY.GDP.MKTP.PP.KD; SE.TER.ENRR) year(1970:2019) long clear
ren countryname country_name
keep country_name year sp_pop_totl ny_gdp_mktp_pp_kd se_ter_enrr
label var ny_gdp_mktp_pp_kd "Aggregate GDP, 2011 PP (WB)"

* Missing values and min/max sense checks
sum
* Data is very good for population, reasonable for gdp in 2011 idollars, also very good for teritary enrollment. These are all about 50% coverage
* Pop goes to about 8 billion for the world which makes sense. GDP into correct trillions. Tertiary ed enrollment goes a little high to 136%.
replace se_ter_enrr = 100 if se_ter_enrr != . & se_ter_enrr > 100
* Duplicates
duplicates drop

* Align country names with VDem
replace country_name = "Burma/Myanmar" if country_name == "Myanmar"
replace country_name = "Cape Verde" if country_name == "Cabo Verde"
replace country_name = "Democratic Republic of the Congo" if country_name == "Congo, Dem. Rep."
replace country_name = "Egypt" if country_name == "Egypt, Arab Rep."
replace country_name = "Hong Kong" if country_name == "Hong Kong SAR, China"
replace country_name = "Iran" if country_name == "Iran, Islamic Rep."
replace country_name = "Kyrgyzstan" if country_name == "Kyrgyz Republic"
replace country_name = "Laos" if country_name == "Lao PDR"
replace country_name = "North Korea" if country_name == "Korea, Dem. People's Rep."
replace country_name = "Palestine/West Bank" if country_name == "West Bank and Gaza"
replace country_name = "Republic of the Congo" if country_name == "Congo, Rep."
replace country_name = "Russia" if country_name == "Russian Federation"
replace country_name = "Slovakia" if country_name == "Slovak Republic"
replace country_name = "South Korea" if country_name == "Korea, Rep."
replace country_name = "Syria" if country_name == "Syrian Arab Republic"
replace country_name = "The Gambia" if country_name == "Gambia, The"
replace country_name = "United States of America" if country_name == "United States"
replace country_name = "Venezuela" if country_name == "Venezuela, RB"
replace country_name = "Yemen" if country_name == "Yemen, Rep."

save Clean_Thesis_WB, replace

// Merging datasets
use Clean_VDem, clear
merge 1:1 country_name year using Clean_Garriga_CBI, gen(merge1)
merge 1:1 country_name year using Clean_RR, gen(merge2)
merge 1:1 country_name year using Clean_Polity4, gen(merge3)
// Special merge for gov turnover data
gen cb_name = country_name
replace cb_name = "Central Bank of West African States" if ((country_name == "Benin" | country_name == "Burkina Faso" | country_name == "Ivory Coast" | country_name == "Mali" | country_name == "Niger" | country_name == "Senegal" | country_name == "Togo") & year >= 1994) | (country_name == "Guinea-Bissau" & year >= 1997)
replace cb_name = "Bank of Central African States" if ((country_name == "Cameroon" | country_name == "Central African Republic" | country_name == "Chad" | country_name == "Republic of the Congo" | country_name == "Gabon") & year >= 1972) | (country_name == "Equatorial Guinea" & year >= 1985)
replace cb_name = "Eastern Carribean Central Bank" if (country_name == "Anguilla" & year >= 1987) | ((country_name == "Antigua and Barbuda" | country_name == "Dominica" | country_name == "Grenada" | country_name == "Monteserrat" | country_name == "St. Kitts and Nevis" | country_name == "St. Lucia" | country_name == "St. Vincent and the Grenadines") & year >= 1983)
* Probably not needed for eastern car cb since almost none of the countries are in other data sets.
replace cb_name = "European Central Bank" if (country_name == "Cyprus" & year >= 2008) | (country_name == "Estonia" & year >= 2011) | (country_name == "Greece" & year >= 2001) | (country_name == "Latvia" & year >= 2014) | (country_name == "Lithuania" & year >= 2015) | (country_name == "Malta" & year >= 2008) | (country_name == "Slovenia" & year >= 2007) | (country_name == "Slovakia" & year >= 2009) | ((country_name == "Austria" | country_name == "Belgium" | country_name == "Finland" | country_name == "France" | country_name == "Germany" | country_name == "Ireland" | country_name == "Italy" | country_name == "Luxembourg" | country_name == "Netherlands" | country_name == "Portugal" | country_name == "Spain") & year >= 1999)
// Central bank of west african states since 1994 and 1997 for Guinea-Bissau
// Benin, Burkina Faso, Ivory Coast, Guinea Bissau, Mali, Niger, Senegal, Togo
// CB of central african states- since 1972 and 1985 for Equatorial Guinea
// Cameroon, CAR, Chad, Rep of Congo, Eq Guinea, Gabon
// Eastern Carribean CB
// Anguilla, Antigua and Barbuda, Dominica, Grenada, Monteserrat, St Kitts and Nevis, St Lucia, St Vincent and the Grenadines from 1983 and from 1987 for Anguilla.
// For some strange reason the ECB is already classified as individual CBs.
// But just to be sure, ECB founded 1999, member cyprus since 2008, estonia 2011, greece 2001, latvia 2014, lith 2015, malta 2008, slovenia 2007, slovakia 2009, original members austria belgium finland france germany, ireland, italy, luxembourg, netherlands, portugal, spain
merge m:1 cb_name year using Clean_CBI_Turnover, gen(merge4)
drop cb_name
drop if country_name == ""
merge 1:1 country_name year using Clean_OECD_Thesis, gen(merge5)
merge 1:1 country_name year using Clean_Thesis_WB, gen(merge6)

// Cut down on unneeded observations- run one last time to make sure
drop if year < 1970

// Panel Regressions
encode country_name, gen(country)
order country year
drop if country == .

// Check for duplicates before setup
duplicates list country year
xtset country year

// For convenient groupings
// Shorten Variable Names
ren timetoregularturnover ttregturn
ren numberofactualturnovers noaturn
ren regularturnoverdummy regtd
ren irregularturnoverdummy irregtd
label var irregtd "(Lack of) Irregular CB Governor Turnover (higher = more de facto CBI)"
replace irregtd = 1 - irregtd
ren timeinoffice tinoff
ren legalduration legdur
ren lvau_garriga lvau_gar
ren lvaw_garriga lvaw_gar
label var lvaw_gar "De Jure CBI (CNW Index)"
ren rate_regime RRrate
label var RRrate "Exchange Rate Classification (RR inverted, higher = more fixed)"
// Dep Variables
local ElStabVars "v2elturnhog v2elturnhos v2eltvrig"
local PolStabVars "e_wbgi_pve instabEvent"
local StabVars "`ElStabVars' `PolStabVars'"

// Create and test binary stab variables and output with xtlogit
*Code for redeployment:
*xtlogit `stabVar' `commVar', fe
*eststo logFE_`stabVar'`commVar'
*logFE_`stabVar'`commVar'

// All independent variables in the same regressions
* To avoid multicolinearity, need to pick independent variables carefully.
* Use the weighted CBI index from CNW. More interpretable and significant in more single regressions.
* Use the irregular turnover variable; in the past regtd (reg turnover) and tinoff (time in office) were also used, but these basically never turn out significant.
local primCommInstVars "lvaw_gar irregtd RRrate"
foreach stabVar in `StabVars' {
reg `stabVar' `primCommInstVars', robust
eststo miols_`stabVar'
xtreg `stabVar' `primCommInstVars', fe cluster(country)
eststo miFE_`stabVar'
}
esttab miols_v2elturnhog miols_v2elturnhos miols_v2eltvrig miols_e_wbgi_pve miols_instabEvent using "multIndOLS.rtf", label replace compress

esttab miFE_v2elturnhog miFE_v2elturnhos miFE_v2eltvrig miFE_e_wbgi_pve miFE_instabEvent using "multIndFE.rtf", label replace compress

eststo clear

* Interaction terms:
* First, Check interrelation of CBI and Fixed Rates- complement/subsitutute?
reg lvau_gar RRrate
reg lvaw_gar RRrate
reg irregtd RRrate
* try de facto cbi too

* Run interactions
foreach stabVar in `StabVars' {
reg `stabVar' `primCommInstVars' c.lvaw_gar#c.irregtd c.lvaw_gar#c.RRrate c.irregtd#c.RRrate, robust
eststo imiols_`stabVar'
xtreg `stabVar' `primCommInstVars' c.lvaw_gar#c.irregtd c.lvaw_gar#c.RRrate c.irregtd#c.RRrate, fe cluster(country)
eststo imiFE_`stabVar'
}
esttab imiols_v2elturnhog imiols_v2elturnhos imiols_v2eltvrig imiols_e_wbgi_pve imiols_instabEvent using "imultIndOLS.rtf", label replace compress

esttab imiFE_v2elturnhog imiFE_v2elturnhos imiFE_v2eltvrig imiFE_e_wbgi_pve imiFE_instabEvent using "imultIndFE.rtf", label replace compress

eststo clear

* Binary dependent variables.
* NOT REALLY NEEDED
local bStabVars "bv2elturnhog bv2elturnhos bv2eltvrig be_wbgi_pve binstabEvent b2v2elturnhog b2v2elturnhos b2v2eltvrig b2e_wbgi_pve"

local primCommInstVars "lvaw_gar irregtd RRrate"
foreach stabVar in `bStabVars' {
*reg `stabVar' `primCommInstVars', robust
*eststo miols_`stabVar'
*xtreg `stabVar' `primCommInstVars', fe cluster(country)
*eststo miFE_`stabVar'
xtlogit `stabVar' `primCommInstVars', fe
eststo lF_`stabVar'
}
*esttab miols_bv2elturnhog miols_bv2elturnhos miols_bv2eltvrig miols_be_wbgi_pve using "bmultIndOLS.rtf", replace compress

*esttab miFE_bv2elturnhog miFE_bv2elturnhos miFE_bv2eltvrig miFE_be_wbgi_pve using "bmultIndFE.rtf", replace compress

esttab lF_bv2elturnhog lF_bv2elturnhos lF_bv2eltvrig lF_be_wbgi_pve lF_binstabEvent using "logitFEMultInd.rtf", label replace compress

*esttab miols_b2v2elturnhog miols_b2v2elturnhos miols_b2v2eltvrig miols_b2e_wbgi_pve using "b2multIndOLS.rtf", replace compress

*esttab miFE_b2v2elturnhog miFE_b2v2elturnhos miFE_b2v2eltvrig miFE_b2e_wbgi_pve using "b2multIndFE.rtf", replace compress

esttab lF_b2v2elturnhog lF_b2v2elturnhos lF_b2v2eltvrig lF_b2e_wbgi_pve using "logitFEMultInd2.rtf", label replace compress

* JUST binary instab event:
xtlogit binstabEvent `primCommInstVars', fe
eststo cbinstabEvent
esttab cbinstabEvent using "coeffsjustBinInstabEvent.rtf", label replace compress
xtlogit binstabEvent `primCommInstVars', fe
eststo mlf_binstabEvent: margins, dydx(`primCommInstVars') post
esttab mlf_binstabEvent using "justBinInstabEvent.rtf", label replace compress

* Binary independent variables all at the same time.
* Maybe use later if want a combined cbi and fixed rate var
* gen committedW = (!float_rate & wHighCBI) if float_rate != . & wHighCBI != .
label var wHighCBI "High De Jure CBI (CNW Index)"
label var fixed_rate "Fixed Exchange Rate Classification (RR 1-8)"
foreach stabVar in `StabVars' {
reg `stabVar' wHighCBI irregtd fixed_rate, robust
eststo bols_`stabVar'
xtreg `stabVar' wHighCBI irregtd fixed_rate, fe cluster(country)
eststo bFE_`stabVar'
}
esttab bols_v2elturnhog bols_v2elturnhos bols_v2eltvrig bols_e_wbgi_pve bols_instabEvent using "binaryIndOLS.rtf", label replace compress
esttab bFE_v2elturnhog bFE_v2elturnhos bFE_v2eltvrig bFE_e_wbgi_pve bFE_instabEvent using "binaryIndFE.rtf", label replace compress

eststo clear

* Controls
merge 1:1 country_name year using Clean_DPI, gen(merge7)
merge 1:1 country_name year using Clean_Visser, gen(merge8)

local noCorpControls "v2elreggov v2x_horacc checks auton author"
local fullcontrols "`noCorpControls' Coord Type"

local StabVarsnoWBPV "`ElStabVars' instabEvent"
* Exclude world bank violence indicator due to insufficient observations.
* Stop collinearity

*Full controls and all independents
foreach stabVar in `StabVars' {
reg `stabVar' `primCommInstVars' `fullcontrols', robust
eststo fullcmiols_`stabVar'
xtreg `stabVar' `primCommInstVars' `fullcontrols', fe cluster(country)
eststo fullcmiFE_`stabVar'
}
esttab fullcmiols_v2elturnhog fullcmiols_v2elturnhos fullcmiols_v2eltvrig fullcmiols_e_wbgi_pve fullcmiols_instabEvent using "fullcmultIndOLS.rtf", label replace compress

esttab fullcmiFE_v2elturnhog fullcmiFE_v2elturnhos fullcmiFE_v2eltvrig fullcmiFE_e_wbgi_pve fullcmiFE_instabEvent using "fullcmultIndFE.rtf", label replace compress

eststo clear

foreach stabVar in `StabVars' {
reg `stabVar' `primCommInstVars' `noCorpControls', robust
eststo nccmiols_`stabVar'
xtreg `stabVar' `primCommInstVars' `noCorpControls', fe cluster(country)
eststo nccmiFE_`stabVar'
}
esttab nccmiols_v2elturnhog nccmiols_v2elturnhos nccmiols_v2eltvrig nccmiols_e_wbgi_pve nccmiols_instabEvent using "nccmultIndOLS.rtf", label replace compress

esttab nccmiFE_v2elturnhog nccmiFE_v2elturnhos nccmiFE_v2eltvrig nccmiFE_e_wbgi_pve nccmiFE_instabEvent using "nccmultIndFE.rtf", label replace compress

eststo clear

*Once binaries are in order
*xtlogit `stabVar' `commVar' `fullcontrols', fe
*eststo clogFE_`stabVar'`commVar'
*clogFE_`stabVar'`commVar' 

*xtlogit `stabVar' `commVar' `noCorpControls', fe
*eststo nclogFE_`stabVar'`commVar'
*nclogFE_`stabVar'`commVar'

*Go back and look at c results and maybe chuck some controls.

save OLS_FEanalysis_Ready, replace

// Arellano Bond etc.

// Hazard Model?- requires a bit of coding...

* Instrumental variables!
* Variables we care about list for reference
* dependent: v2elturnhog v2elturnhos v2eltvrig e_wbgi_pve instabEvent
* independent: lvaw_gar irregtd RRrate

*Prepare oecd ss biz share variable
replace v2petersch = v2petersch/100
gen vssbizagg = v2petersch*ssbizsh

* Using not VDEM, but original world bank variables for tert. And preparing the oecd var. Data availability looks to be better
replace se_ter_enrr = se_ter_enrr/100
gen ssbizagg = se_ter_enrr*ssbizsh
label var ssbizagg "Pop. Share of Tertiary Ed. Social Science/Business Graduates"

* First stages check, since for some reason they aren't showing up in loop results.

* CBI
xtreg lvaw_gar v2petersch, fe vce(cluster country)
* Very significant
xtreg irregtd v2petersch, fe vce(cluster country)
* Also very significant. hmm.
xtreg lvaw_gar se_ter_enrr, fe vce(cluster country)
* Very significant
xtreg irregtd se_ter_enrr, fe vce(cluster country)
* Also very significant. hmm.
xtreg lvaw_gar ssbizagg, fe vce(cluster country)
reg lvaw_gar ssbizagg, robust
* This squeezes through, just barely with p of 0.025!
reg irregtd ssbizagg, robust
* Sadly DOES NOT WORK for irregtd

* Rates
xtreg RRrate ny_gdp_mktp_pp_kd, fe vce(cluster country)
* GDP NOT working out in fes panel. BUT note
reg RRrate ny_gdp_mktp_pp_kd, robust
*does do the trick
xtreg RRrate aggGDP, fe vce(cluster country)
* GDP NOT working out in fes panel. BUT note
reg RRrate aggGDP, robust
*does do the trick

* For all instruments: consider FILLING the missing data somehow. Sample size is pretty much always too small.

* Tertiary education enrollment
* Use full knowledge of both datasets. Average out.
gen atertEd = (v2petersch + se_ter_enrr)/2
replace atertEd = v2petersch if se_ter_enrr == .
replace atertEd = se_ter_enrr if v2petersch == .

* Interpolate gaps
* Tert ed
sort country
by country: ipolate atertEd year, gen(itertEd)
* SSBiz share
by country: ipolate ssbizsh year, gen(issbizsh)

* Aggregate GDP from VDEM
by country: ipolate aggGDP year, gen(ivaggGDP)
* Aggregate GDP from WB
by country: ipolate ny_gdp_mktp_pp_kd year, gen(iwbaggGDP)

* New OECD ssbizagg with interpolated
gen issbizagg = issbizsh*itertEd

* Interpolated first stages check.
* CBI
xtreg lvaw_gar itertEd, fe vce(cluster country)
* Very sign
xtreg irregtd itertEd, fe vce(cluster country)
* NOT sign. Wah.
reg irregtd itertEd, robust
* Still not significant.
xtreg lvaw_gar issbizagg, fe vce(cluster country)
* Not significant
reg lvaw_gar issbizagg, robust
* Very significant
xtreg irregtd issbizagg, fe vce(cluster country)
* Not significant
reg irregtd issbizagg, robust
* Still not significant

* Rates
xtreg RRrate ivaggGDP, fe vce(cluster country)
* GDP NOT working out in fes panel. BUT note
reg RRrate ivaggGDP, robust
*does do the trick
xtreg RRrate iwbaggGDP, fe vce(cluster country)
* GDP NOT working out in fes panel. BUT note
reg RRrate iwbaggGDP, robust
*does do the trick

* All instruments treatment. Without interpolation.
*foreach stabVar in `StabVars' { 
*ivregress 2sls `stabVar' (lvaw_gar irregtd RRrate = se_ter_enrr v2petersch ssbizaggGDP aggGDP), robust
*eststo fivs_`stabVar'
*}
*esttab fivs_v2elturnhog fivs_v2elturnhos fivs_v2eltvrig fivs_e_wbgi_pve fivs_instabEvent using "fivs.rtf", replace compress

* All instruments treatment with interpolated.
* First need to cut issbizagg as an instrument since observation problems. Also deal with world bank rather than vdem gdp data. Also for now look only at de jure cbi and rates.
* Variables we care about list for reference
* dependent: v2elturnhog v2elturnhos v2eltvrig e_wbgi_pve instabEvent
* independent: lvaw_gar irregtd RRrate
eststo clear

* De jure independence check
* Loop is broken somehow.
ivregress 2sls v2elturnhog (lvaw_gar RRrate = itertEd iwbaggGDP), robust
eststo ifivs_v2elturnhog
ivregress 2sls v2elturnhos (lvaw_gar RRrate = itertEd iwbaggGDP), robust
eststo ifivs_v2elturnhos
ivregress 2sls v2eltvrig (lvaw_gar RRrate = itertEd iwbaggGDP), robust
eststo ifivs_v2eltvrig
ivregress 2sls e_wbgi_pve (lvaw_gar RRrate = itertEd iwbaggGDP), robust
eststo ifivs_e_wbgi_pve
ivregress 2sls instabEvent (lvaw_gar RRrate = itertEd iwbaggGDP), robust
eststo ifivs_instabEvent

esttab ifivs_v2elturnhog ifivs_v2elturnhos ifivs_v2eltvrig ifivs_e_wbgi_pve ifivs_instabEvent using "ifivs.rtf", label replace compress

* De facto independence check
ivregress 2sls v2elturnhog (irregtd RRrate = itertEd iwbaggGDP), robust
eststo ifivs2_v2elturnhog
ivregress 2sls v2elturnhos (irregtd RRrate = itertEd iwbaggGDP), robust
eststo ifivs2_v2elturnhos
ivregress 2sls v2eltvrig (irregtd RRrate = itertEd iwbaggGDP), robust
eststo ifivs2_v2eltvrig
ivregress 2sls e_wbgi_pve (irregtd RRrate = itertEd iwbaggGDP), robust
eststo ifivs2_e_wbgi_pve
ivregress 2sls instabEvent (irregtd RRrate = itertEd iwbaggGDP), robust
eststo ifivs2_instabEvent

esttab ifivs2_v2elturnhog ifivs2_v2elturnhos ifivs2_v2eltvrig ifivs2_e_wbgi_pve ifivs2_instabEvent using "ifivs2.rtf", label replace compress

* Try the OECD instrument, with de jure cbi
ivregress 2sls v2elturnhog (lvaw_gar RRrate = ssbizagg iwbaggGDP), robust
eststo ifivs3_v2elturnhog
ivregress 2sls v2elturnhos (lvaw_gar RRrate = ssbizagg iwbaggGDP), robust
eststo ifivs3_v2elturnhos
ivregress 2sls v2eltvrig (lvaw_gar RRrate = ssbizagg iwbaggGDP), robust
eststo ifivs3_v2eltvrig
ivregress 2sls e_wbgi_pve (lvaw_gar RRrate = ssbizagg iwbaggGDP), robust
eststo ifivs3_e_wbgi_pve
ivregress 2sls instabEvent (lvaw_gar RRrate = ssbizagg iwbaggGDP), robust noconstant
eststo ifivs3_instabEvent

esttab ifivs3_v2elturnhog ifivs3_v2elturnhos ifivs3_v2eltvrig ifivs3_e_wbgi_pve ifivs3_instabEvent using "ifivs3.rtf", label replace compress

* Mini regressions for RRrate standalone
ivregress 2sls v2eltvrig (RRrate = ivaggGDP), robust
eststo miniLH
ivregress 2sls e_wbgi_pve (RRrate = ivaggGDP), robust
eststo miniWB
esttab miniLH miniWB using "miniRRIVs.rtf", label replace compress

*xtivreg: I don't think this is doable, as a lot of the first stages don't work out anymore.

save IV_Analysis_Ready, replace

* Capital controls (capital account) level robustness
merge 1:1 country_name year using Clean_kaopen, gen(merge9)

hist ka_open
* Set high as "above median/50th percentile"
egen mka_open = median(ka_open)
gen highka_open = (ka_open > mka_open) if ka_open != .

* Repeat regs for high and low samples. Determine which things to run by results of earlier regressions.

foreach stabVar in `StabVars' {
xtreg `stabVar' `primCommInstVars' if highka_open, fe cluster(country)
eststo hkmiFE_`stabVar'
}

esttab hkmiFE_v2elturnhog hkmiFE_v2elturnhos hkmiFE_v2eltvrig hkmiFE_e_wbgi_pve hkmiFE_instabEvent using "hkmultIndFE.rtf", label replace compress

foreach stabVar in `StabVars' {
xtreg `stabVar' `primCommInstVars' if !highka_open, fe cluster(country) 
eststo lkmiFE_`stabVar'
}

esttab lkmiFE_v2elturnhog lkmiFE_v2elturnhos lkmiFE_v2eltvrig lkmiFE_e_wbgi_pve lkmiFE_instabEvent using "lkmultIndFE.rtf", label replace compress

eststo clear

* Interaction term analysis for ka_open
* primCommInstVars "lvaw_gar irregtd RRrate"

foreach stabVar in `StabVars' {
xtreg `stabVar' c.lvaw_gar##c.ka_open i.irregtd##c.ka_open c.RRrate##c.ka_open, fe cluster(country)
eststo ikmiFE_`stabVar'
}

esttab ikmiFE_v2elturnhog ikmiFE_v2elturnhos ikmiFE_v2eltvrig ikmiFE_e_wbgi_pve ikmiFE_instabEvent using "ikmultIndFE.rtf", label replace compress

eststo clear

save capaccount_Analysis_Ready,  replace

* Deeper political institutional analysis.
* HOS = HOG
local HOSHOGStabVars = "v2elturnhog v2elturnhos"
foreach stabVar in `HOSHOGStabVars' {
xtreg `stabVar' c.lvaw_gar##i.v2exhoshog i.irregtd##i.v2exhoshog c.RRrate##i.v2exhoshog, fe cluster(country)
eststo hoshogmiFE_`stabVar'
}
esttab hoshogmiFE_v2elturnhog hoshogmiFE_v2elturnhos using "hoshogmultIndFE.rtf", label replace compress

* WHAT IN THE WORLD IS GOING ON?
browse if v2exhoshog == 0

eststo clear

* Lower chamber legislates in practice
xtreg v2eltvrig c.lvaw_gar##c.v2lglegplo i.irregtd##c.v2lglegplo c.RRrate##c.v2lglegplo, fe cluster(country)
eststo llpFE_v2eltvrig
esttab llpFE_v2eltvrig using "llpFE.rtf", label replace compress

* Polity combined scores
* Note factor variables may not contain negative values hence
replace e_polity2 = e_polity2 + 10 if e_polity2 != .
foreach stabVar in `StabVars' {
xtreg `stabVar' `primCommInstVars' c.lvaw_gar##c.e_polity2 i.irregtd##c.e_polity2 c.RRrate##e_polity2, fe cluster(country)
eststo demcmiFE_`stabVar'
}
esttab demcmiFE_v2elturnhog demcmiFE_v2elturnhos demcmiFE_v2eltvrig demcmiFE_e_wbgi_pve demcmiFE_instabEvent using "demcmultIndFE.rtf", label replace compress

eststo clear

*Binary polity variable.
gen deme_polity2 = (e_polity2 > 10) if e_polity2 != .
foreach stabVar in `StabVars' {
xtreg `stabVar' `primCommInstVars' c.lvaw_gar##i.deme_polity2 i.irregtd##i.deme_polity2 c.RRrate##i.deme_polity2, fe cluster(country)
eststo idemcmiFE_`stabVar'
}
esttab idemcmiFE_v2elturnhog idemcmiFE_v2elturnhos idemcmiFE_v2eltvrig idemcmiFE_e_wbgi_pve idemcmiFE_instabEvent using "binarydemcmultIndFE.rtf", label replace compress

* Split sample for democracy/nondemocracy
* Democracies
foreach stabVar in `StabVars' {
xtreg `stabVar' `primCommInstVars' if deme_polity2 == 1, fe cluster(country)
eststo demFE_`stabVar'
}
esttab demFE_v2elturnhog demFE_v2elturnhos demFE_v2eltvrig demFE_e_wbgi_pve demFE_instabEvent using "democraciesFE.rtf", label replace compress

* Nondemocracies
foreach stabVar in `StabVars' {
xtreg `stabVar' `primCommInstVars' if deme_polity2 == 0, fe cluster(country)
eststo nondemFE_`stabVar'
}
esttab nondemFE_v2elturnhog nondemFE_v2elturnhos nondemFE_v2eltvrig nondemFE_e_wbgi_pve nondemFE_instabEvent using "nondemocraciesFE.rtf", label replace compress

* Bring all of these together.
foreach stabVar in `StabVars' {
xtreg `stabVar' `primCommInstVars' c.lvaw_gar##i.v2exhoshog i.irregtd##i.v2exhoshog c.RRrate##i.v2exhoshog c.lvaw_gar##c.v2lglegplo i.irregtd##c.v2lglegplo c.RRrate##c.v2lglegplo c.lvaw_gar##c.e_polity2 i.irregtd##c.e_polity2 c.RRrate##c.e_polity2, fe cluster(country)
eststo fullicmiFE_`stabVar'
}
esttab fullicmiFE_v2elturnhog fullicmiFE_v2elturnhos fullicmiFE_v2eltvrig fullicmiFE_e_wbgi_pve fullicmiFE_instabEvent using "fullicmultIndFE.rtf", label replace compress

eststo clear

* Bring all of these together edit for binary democracy
foreach stabVar in `StabVars' {
xtreg `stabVar' `primCommInstVars' c.lvaw_gar##i.v2exhoshog i.irregtd##i.v2exhoshog c.RRrate##i.v2exhoshog c.lvaw_gar##c.v2lglegplo i.irregtd##c.v2lglegplo c.RRrate##c.v2lglegplo c.lvaw_gar##i.deme_polity2 i.irregtd##i.deme_polity2 c.RRrate##i.deme_polity2, fe cluster(country)
eststo ifullicmiFE_`stabVar'
}
esttab ifullicmiFE_v2elturnhog ifullicmiFE_v2elturnhos ifullicmiFE_v2eltvrig ifullicmiFE_e_wbgi_pve ifullicmiFE_instabEvent using "ifullicmultIndFE.rtf", label replace compress

eststo clear


* OECD Monetary Institutions aid as an IV?

save latepriorities_Ready, replace

use latepriorities_Ready, clear
duplicates drop country year, force
xtset country year

local primCommInstVars "lvaw_gar irregtd RRrate"

* Independent variable lags
foreach stabVar in `StabVars' {
xtreg `stabVar' `primCommInstVars' L(1/10).lvaw_gar L(1/10).RRrate L(1/10).irregtd, fe vce(cluster country)
eststo lags_`stabVar'
}
esttab lags_v2elturnhog lags_v2elturnhos lags_v2eltvrig lags_e_wbgi_pve lags_instabEvent using "lags.rtf", label replace compress
eststo clear

* Ordinal regression (logistic)
* Loop again mysteriously broken
xtologit v2elturnhog `primCommInstVars', vce(cluster country)
eststo ordLogv2elturnhog: margins, dydx(`primCommInstVars') post
* Be patient as the above command takes a long time to compute...
xtologit v2elturnhos `primCommInstVars', vce(cluster country)
eststo ordLogv2elturnhos: margins, dydx(`primCommInstVars') post
xtologit v2eltvrig `primCommInstVars', vce(cluster country)
eststo ordLogv2eltvrig: margins, dydx(`primCommInstVars') post

esttab ordLogv2elturnhog ordLogv2elturnhos ordLogv2eltvrig using "ordLog.rtf", label replace compress
eststo clear

* Lagged Ordinal Logit: Margins computation does not run.
xtologit v2elturnhog `primCommInstVars' L(1/10).lvaw_gar L(1/10).RRrate L(1/10).irregtd, vce(cluster country)
eststo lagordLogv2elturnhog
*eststo mlagordLogv2elturnhog: margins, dydx(`primCommInstVars' L(1/10).lvaw_gar L(1/10).RRrate L(1/10).irregtd) post
* Be patient as the above command takes a long time to compute...
xtologit v2elturnhos `primCommInstVars' L(1/10).lvaw_gar L(1/10).RRrate L(1/10).irregtd, vce(cluster country)
eststo lagordLogv2elturnhos
*eststo mlagordLogv2elturnhos: margins, dydx(`primCommInstVars' L(1/10).lvaw_gar L(1/10).RRrate L(1/10).irregtd) post
xtologit v2eltvrig `primCommInstVars' L(1/10).lvaw_gar L(1/10).RRrate L(1/10).irregtd, vce(cluster country)
eststo lagordLogv2eltvrig
*eststo mlagordLogv2eltvrig: margins, dydx(`primCommInstVars' L(1/10).lvaw_gar L(1/10).RRrate L(1/10).irregtd) post
xtlogit binstabEvent `primCommInstVars' L(1/10).lvaw_gar L(1/10).RRrate L(1/10).irregtd, vce(cluster country)
eststo laglogInstab

esttab lagordLogv2elturnhog lagordLogv2elturnhos lagordLogv2eltvrig laglogInstab using "lagordLogLog.rtf", label replace compress
eststo clear

* Lagged Bin Stab Logit: Margins computation does not run.
*xtlogit binstabEvent `primCommInstVars' L(1/10).lvaw_gar L(1/10).RRrate L(1/10).irregtd, fe
*eststo mlaglf_binstabEvent: margins, dydx(`primCommInstVars' L(1/10).lvaw_gar L(1/10).RRrate L(1/10).irregtd) post
*esttab laglf_binstabEvent using "laglogBinInstabEvent.rtf", label replace compress

* Arellano Bond Specification

* Summary Statistics for the entire dataset
estpost sum
esttab . using "sumstatsAll.rtf", label cells("mean sd count") noobs replace

use latepriorities_Ready, clear

* Recreating Appendix Table A1 and A2
reg v2elturnhog irregtd, robust
eststo a11
xtreg v2elturnhog irregtd, fe vce(cluster country)
eststo a12
esttab a11 a12 using "a1.rtf", label replace compress

reg v2elturnhog tinoff, robust
eststo a21
xtreg v2elturnhog tinoff, fe vce(cluster country)
eststo a22
esttab a21 a22 using "a2.rtf", label replace compress

* Capture ordered logit coeffs
duplicates drop country year, force
local primCommInstVars "lvaw_gar irregtd RRrate"
xtset country year
xtologit v2elturnhog `primCommInstVars', vce(cluster country)
eststo cordLogv2elturnhog
xtologit v2elturnhos `primCommInstVars', vce(cluster country)
eststo cordLogv2elturnhos
xtologit v2eltvrig `primCommInstVars', vce(cluster country)
eststo cordLogv2eltvrig

esttab cordLogv2elturnhog cordLogv2elturnhos cordLogv2eltvrig using "coeffordLog.rtf", label replace compress
eststo clear

* IVs and a democracy investigation
*Binary polity variable.
gen deme_polity2 = (e_polity2 > 10) if e_polity2 != .
foreach stabVar in `StabVars' {
xtreg `stabVar' `primCommInstVars' c.lvaw_gar##i.deme_polity2 i.irregtd##i.deme_polity2 c.RRrate##i.deme_polity2, fe cluster(country)
eststo idemcmiFE_`stabVar'
}
esttab idemcmiFE_v2elturnhog idemcmiFE_v2elturnhos idemcmiFE_v2eltvrig idemcmiFE_e_wbgi_pve idemcmiFE_instabEvent using "binarydemcmultIndFE.rtf", label replace compress

* Split sample for democracy/nondemocracy
* Democracies
foreach stabVar in `StabVars' {
xtreg `stabVar' `primCommInstVars' if deme_polity2 == 1, fe cluster(country)
eststo demFE_`stabVar'
}
esttab demFE_v2elturnhog demFE_v2elturnhos demFE_v2eltvrig demFE_e_wbgi_pve demFE_instabEvent using "democraciesFE.rtf", label replace compress

* Nondemocracies
foreach stabVar in `StabVars' {
xtreg `stabVar' `primCommInstVars' if deme_polity2 == 0, fe cluster(country)
eststo nondemFE_`stabVar'
}
esttab nondemFE_v2elturnhog nondemFE_v2elturnhos nondemFE_v2eltvrig nondemFE_e_wbgi_pve nondemFE_instabEvent using "nondemocraciesFE.rtf", label replace compress

* IVs and a cap controls investigation

* Lags and a democracy investigation

* Lags and a cap controls investigation