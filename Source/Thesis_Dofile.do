// Thesis Dofile
// Commitment Institutions and Instability
// Isaac Liu

*****************************************************************************

*Pre-Run Settings

clear
macro drop _all

// Set paths
* The root directory line below should be the only setting which a user has to customize for their computer
global Root = "~/repo/Commitment_Institutions_Instability"
global Input = "${Root}/Input"
global Output = "${Root}/Output"
global Intermediate_Data = "${Output}/Intermediate_Data"
global Tables = "${Output}/Tables"

* Programs needed
ssc install wbopendata, replace
ssc install estout, replace

*****************************************************************************

// Data collection and cleaning

// VDEM
// Select out critical variables (since Stata version will not accommodate all of them)
use country_name year v2elturnhog v2elturnhos v2eltvrexo v2eltvrig v3eltvriguc e_coups e_wbgi_pve e_mipopula v2petersch e_migdppc e_civil_war e_miinterc e_pt_coup v2elreggov v2x_horacc v3eldirepr v2exhoshog v2lglegplo e_polity2 using "${Input}/V-Dem-CY-Full+Others-v10", clear

label var v2elturnhog "Head of Govt. Turnover"
label var v2elturnhos "Head of State Turnover"
label var v2eltvrig "Lower House Turnover"
label var e_wbgi_pve "WB Political Stability (Absence of Violence)"
label var v2petersch "Tertiary Education Enrollment (V-Dem)"
label var v2exhoshog "HOS = HOG"
label var v2lglegplo "Legislative Efficacy"
label var e_polity2 "Polity Democracy Score (v2)"

// Variables are, respectively, country, year, head of government turnover event, head of state turnover event, executive turnover, lower chamber turnover, upper chamber turnover, coups (PIPE), WGI political stability, total population, tertiary school enrollment, GDP per capita, civil war, internal armed conflict, coups d'etat, existence of regional governments, horizontal accountability (checks and balances).

* The last four added are direct presidential elections, whether hos is the same as hog, whether lower chamber legislates in practice, and the polity revised combined score of democracy

// Notes
// HOG turnover is coded as 0 for the same HOG, 1 for a diff individual or a change in coalition (parliamentary) or leadership, 2 for a loss of position- diff person and diff party, in parli system new party, or if first for newly ind.
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
// Horizontal accountability and checks and balances- a normalized scale representing checks and balances

* Ranges and notes for the last few
* direct presidential elections are 0 for indirect, 1 for direct, adn 2 for mixed.
* whether hos is the same as hog is binary 0 no 1 yes
* whether lower chamber legislates in practice, is a 0 for no, one for usually, and 2 for always
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
// Turnover events appear to be coded as missing in years with no elections, which is good. Unfortunately NO upper chamber turnover observations are available for this period- but hopefully lower chamber values will suffice. World governance indicator values for political violence are for recent dates only. Coup data from PIPE is not fully available. GDP data is very broad in coverage. Population is often missing. Internal conflict and civil war data has some gaps. Finally, coverage for the vdem PT coup variable is very good.
// Min-Max sense check
// Country name and year appear to be in order. Turnover events appear to be in the correct 0 to 2 range. Regional government binary is in order. Tertiary schooling percentages are logical if high for nome nations. Horizontal acc and WGI indices appear to be in anticipated ranges. Coups ranges are good. gdp per capita ranges from 134 to 220717 which seems somewhat high but not unrealistic. Population clocks in the correct ranges up to a billion. Civil war and internal conflict variables also appear to be in correct ranges.

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

save "${Intermediate_Data}/Clean_VDem", replace

*****************************************************************************

// DPI checks and balances and federalism
use "${Input}/DPI2017_stata13", clear
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
// No duplicates.

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

save "${Intermediate_Data}/Clean_DPI", replace

*****************************************************************************

// Visser's index of corporatism
import excel "${Input}/Visser_Corp.xlsx", sheet("ICTWSS6.0") firstrow clear
rename country country_name
keep country_name year Coord Type
// Coordination goes from 1 for fragmented wage bargaining to 5 with centralized. Type goes from 0 for no govt intervention to 6 for government imposed bargaining/statutory controls.
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

save "${Intermediate_Data}/Clean_Visser", replace

*****************************************************************************

* Not really needed:
// CSP Armed Conflict- CIVVIOL CIVWAR ETHVIOL ETHWAR CIVTOT
// WB world governance indicators PV.EST

// CBI Garriga statutory
use "${Input}/CBI Data", clear

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

save "${Intermediate_Data}/Clean_Garriga_CBI", replace

*****************************************************************************

// Romelli Grilli CBI extension- de facto CBI
* import excel "C:\Users\Isaac Liu\OneDrive - Georgetown University\Senior\Spring Class\Thesis\Romelli CBI.xlsx", sheet("CBI Indices") firstrow

* order country year

// Prepare for merging.
* rename country country_name

// Align country names
* replace country_name 

* save Clean_Grilli_CBI, replace

// Governor Turnover from Axel, Strum De Haan
import excel "${Input}/Axel Sturm De Haan Gov Turnover.xlsx", sheet("data v2018") firstrow clear

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
save "${Intermediate_Data}/Clean_CBI_Turnover", replace

*****************************************************************************

// Reinhart Rog ex reg class
import excel "${Input}/ERA_Classification_Annual_1940-2016_Mod.xlsx", sheet("Fine") firstrow clear

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

save "${Intermediate_Data}/Clean_RR", replace

*****************************************************************************

// AREARS IMF on de jure rates and cap controls
// Rate data is only available since 2008! :(
import excel "${Input}/AREARforCapConandDJRates.xlsx", sheet("AREAER-DataQueryReport_03.28.20") firstrow clear

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

save "${Intermediate_Data}/Clean_AREARS", replace

*****************************************************************************

// Polity IV
import excel "${Input}/p4v2018.xls", firstrow clear

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
save "${Intermediate_Data}/Clean_Polity4", replace

*****************************************************************************

// Chinn Ito KAOPEN index capital control openness
use "${Input}/kaopen_2017", clear
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

save "${Intermediate_Data}/Clean_kaopen", replace

*****************************************************************************

// OECD social science and biz grad
import excel "${Input}/OECD Tert Grads.xlsx", sheet("DP_LIVE_22032020015002769") firstrow clear
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

save "${Intermediate_Data}/Clean_OECD_Thesis", replace

*****************************************************************************

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

save "${Intermediate_Data}/Clean_Thesis_WB", replace

*****************************************************************************

// Merging datasets
use "${Intermediate_Data}/Clean_VDem", clear
merge 1:1 country_name year using "${Intermediate_Data}/Clean_Garriga_CBI", gen(merge1)
merge 1:1 country_name year using "${Intermediate_Data}/Clean_RR", gen(merge2)
merge 1:1 country_name year using "${Intermediate_Data}/Clean_Polity4", gen(merge3)
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
merge m:1 cb_name year using "${Intermediate_Data}/Clean_CBI_Turnover", gen(merge4)
drop cb_name
drop if country_name == ""
merge 1:1 country_name year using "${Intermediate_Data}/Clean_OECD_Thesis", gen(merge5)
merge 1:1 country_name year using "${Intermediate_Data}/Clean_Thesis_WB", gen(merge6)

// Cut down on unneeded observations- run one last time to make sure
drop if year < 1970

*****************************************************************************

// Panel Tables
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

*****************************************************************************

// All independent variables in the same Tables
* To avoid multicolinearity, need to pick independent variables carefully.
* Use the weighted CBI index from CNW. More interpretable and significant in more single regressions.
* Use the irregular turnover variable; in the past regtd (reg turnover) and tinoff (time in office) were also used, but these basically never turn out significant.

* The big correction: split into de jure and de facto CBI versions
* This is due to the bad controls problem: de jure likely affects de facto.
local primCommInstVarsDJ "lvaw_gar RRrate"
local primCommInstVarsDF "irregtd RRrate"

foreach stabVar in `StabVars' {
    reg `stabVar' `primCommInstVarsDJ', robust
    eststo miolsDJ_`stabVar'
    xtreg `stabVar' `primCommInstVarsDJ', fe cluster(country)
    eststo miFEDJ_`stabVar'
}

esttab miolsDJ_v2elturnhog miolsDJ_v2elturnhos miolsDJ_v2eltvrig miolsDJ_e_wbgi_pve miolsDJ_instabEvent using "${Tables}/multIndOLSDJ.tex", title(De Jure CBI, Ordinary Least Squares with Robust Standard Errors \label{multIndOLSDJ}) label replace compress booktabs wrap varwidth(40)

esttab miFEDJ_v2elturnhog miFEDJ_v2elturnhos miFEDJ_v2eltvrig miFEDJ_e_wbgi_pve miFEDJ_instabEvent using "${Tables}/multIndFEDJ.tex", title(De Jure CBI, Fixed Effects Regression with Clustered Standard Errors \label{multIndFEDJ}) label replace compress booktabs wrap varwidth(40)

eststo clear

foreach stabVar in `StabVars' {
    reg `stabVar' `primCommInstVarsDF', robust
    eststo miolsDF_`stabVar'
    xtreg `stabVar' `primCommInstVarsDF', fe cluster(country)
    eststo miFEDF_`stabVar'
}
esttab miolsDF_v2elturnhog miolsDF_v2elturnhos miolsDF_v2eltvrig miolsDF_e_wbgi_pve miolsDF_instabEvent using "${Tables}/multIndOLSDF.tex", title(De Facto CBI, Ordinary Least Squares with Robust Standard Errors \label{multIndOLSDJ}) label replace compress booktabs wrap varwidth(40)

esttab miFEDF_v2elturnhog miFEDF_v2elturnhos miFEDF_v2eltvrig miFEDF_e_wbgi_pve miFEDF_instabEvent using "${Tables}/multIndFEDF.tex", title(De Facto CBI, Fixed Effects Regression with Clustered Standard Errors \label{multIndFEDF}) label replace compress booktabs wrap varwidth(40)

eststo clear

*****************************************************************************

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
esttab imiols_v2elturnhog imiols_v2elturnhos imiols_v2eltvrig imiols_e_wbgi_pve imiols_instabEvent using "${Tables}/imultIndOLS.tex", title(\label{imultIndOLS}) label replace compress booktabs wrap varwidth(40)

esttab imiFE_v2elturnhog imiFE_v2elturnhos imiFE_v2eltvrig imiFE_e_wbgi_pve imiFE_instabEvent using "${Tables}/imultIndFE.tex", title(\label{imultIndFE}) label replace compress booktabs wrap varwidth(40)

eststo clear

*****************************************************************************

* CORRECTED Interactions

* DJ
    foreach stabVar in `StabVars' {
    reg `stabVar' `primCommInstVarsDJ' c.lvaw_gar#c.RRrate, robust
    eststo imiolsDJ_`stabVar'
    xtreg `stabVar' `primCommInstVarsDJ' c.lvaw_gar#c.RRrate, fe cluster(country)
    eststo imiFEDJ_`stabVar'
}
esttab imiolsDJ_v2elturnhog imiolsDJ_v2elturnhos imiolsDJ_v2eltvrig imiolsDJ_e_wbgi_pve imiolsDJ_instabEvent using "${Tables}/imultIndOLSDJ.tex", title(De Jure CBI Interaction with Exchange Rate Regime, Ordinary Least Squares with Robust Standard Errors \label{imultIndOLSDJ}) label replace compress booktabs wrap varwidth(40)

esttab imiFEDJ_v2elturnhog imiFEDJ_v2elturnhos imiFEDJ_v2eltvrig imiFEDJ_e_wbgi_pve imiFEDJ_instabEvent using "${Tables}/imultIndFEDJ.tex", title(De Jure CBI Interaction with Exchange Rate Regime, Fixed Effects Regression with Clustered Standard Errors \label{imultIndFEDJ}) label replace compress booktabs wrap varwidth(40)

eststo clear

*DF
foreach stabVar in `StabVars' {
reg `stabVar' `primCommInstVarsDF' i.irregtd#c.RRrate, robust
eststo imiolsDF_`stabVar'
xtreg `stabVar' `primCommInstVarsDF' i.irregtd#c.RRrate, fe cluster(country)
eststo imiFEDF_`stabVar'
}
esttab imiolsDF_v2elturnhog imiolsDF_v2elturnhos imiolsDF_v2eltvrig imiolsDF_e_wbgi_pve imiolsDF_instabEvent using "${Tables}/imultIndOLSDF.tex", title(De Facto CBI Interaction with Exchange Rate Regime, Ordinary Least Squares with Robust Standard Errors \label{imultIndOLSDF}) label replace compress booktabs wrap varwidth(40)

esttab imiFEDF_v2elturnhog imiFEDF_v2elturnhos imiFEDF_v2eltvrig imiFEDF_e_wbgi_pve imiFEDF_instabEvent using "${Tables}/imultIndFEDF.tex", title(De Facto CBI Interaction with Exchange Rate Regime, Fixed Effects Regression with Clustered Standard Errors \label{imultIndFEDF}) label replace compress booktabs wrap varwidth(40)

eststo clear

*****************************************************************************

* Binary dependent variables.
* NOT REALLY NEEDED
local bStabVars "bv2elturnhog bv2elturnhos bv2eltvrig be_wbgi_pve binstabEvent b2v2elturnhog b2v2elturnhos b2v2eltvrig b2e_wbgi_pve"

*DJ
foreach stabVar in `bStabVars' {
xtlogit `stabVar' `primCommInstVarsDJ', fe
eststo lFDJ_`stabVar'
}

esttab lFDJ_bv2elturnhog lFDJ_bv2elturnhos lFDJ_bv2eltvrig lFDJ_be_wbgi_pve lFDJ_binstabEvent using "${Tables}/logitFEMultIndDJ.tex", title(\label{logitFEMultIndDJ}) label replace compress booktabs wrap varwidth(40)

esttab lFDJ_b2v2elturnhog lFDJ_b2v2elturnhos lFDJ_b2v2eltvrig lFDJ_b2e_wbgi_pve using "${Tables}/logitFEMultInd2DJ.tex", title(\label{logitFEMultInd2DJ}) label replace compress booktabs wrap varwidth(40)

*DF
foreach stabVar in `bStabVars' {
xtlogit `stabVar' `primCommInstVarsDF', fe
eststo lFDF_`stabVar'
}

esttab lFDF_bv2elturnhog lFDF_bv2elturnhos lFDF_bv2eltvrig lFDF_be_wbgi_pve lFDF_binstabEvent using "${Tables}/logitFEMultIndDF.tex", title(\label{logitFEMultIndDF}) label replace compress booktabs wrap varwidth(40)

esttab lFDF_b2v2elturnhog lFDF_b2v2elturnhos lFDF_b2v2eltvrig lFDF_b2e_wbgi_pve using "${Tables}/logitFEMultInd2DF.tex", title(\label{logitFEMultInd2DF}) label replace compress booktabs wrap varwidth(40)

*****************************************************************************

* JUST binary instab event:

* DJ
xtlogit binstabEvent `primCommInstVarsDJ', fe
eststo cbinstabEventDJ
esttab cbinstabEventDJ using "${Tables}/coeffsJustBinInstabEventDJ.tex", label replace compress booktabs wrap varwidth(40)
xtlogit binstabEvent `primCommInstVarsDJ', fe
eststo mlf_binstabEventDJ: margins, dydx(`primCommInstVarsDJ') post
esttab mlf_binstabEventDJ using "${Tables}/margsJustBinInstabEventDJ.tex", title(De Jure CBI, Instability Event Panel Logit, Fixed Effects and Clustered Standard Errors, Mean Marginal Effects \label{margsJustBinInstabEventDJ}) label replace compress booktabs wrap varwidth(40)

* DF
xtlogit binstabEvent `primCommInstVarsDF', fe
eststo cbinstabEventDF
esttab cbinstabEventDF using "${Tables}/coeffsJustBinInstabEventDF.tex", label replace compress booktabs wrap varwidth(40)
xtlogit binstabEvent `primCommInstVarsDF', fe
eststo mlf_binstabEventDF: margins, dydx(`primCommInstVarsDF') post
esttab mlf_binstabEventDF using "${Tables}/margsJustBinInstabEventDF.tex", title(De Facto CBI, Instability Event Panel Logit, Fixed Effects and Clustered Standard Errors, Mean Marginal Effects \label{margsJustBinInstabEventDF}) label replace compress booktabs wrap varwidth(40)

*****************************************************************************

* Binary independent variables.
* Maybe use later if want a combined cbi and fixed rate var
* gen committedW = (!float_rate & wHighCBI) if float_rate != . & wHighCBI != .
label var wHighCBI "High De Jure CBI (CNW Index)"
label var fixed_rate "Fixed Exchange Rate Classification (RR 1-8)"

* DJ
foreach stabVar in `StabVars' {
reg `stabVar' wHighCBI fixed_rate, robust
eststo bolsDJ_`stabVar'
xtreg `stabVar' wHighCBI fixed_rate, fe cluster(country)
eststo bFEDJ_`stabVar'
}
esttab bolsDJ_v2elturnhog bolsDJ_v2elturnhos bolsDJ_v2eltvrig bolsDJ_e_wbgi_pve bolsDJ_instabEvent using "${Tables}/binaryIndOLSDJ.tex", title(\label{binaryIndOLSDJ}) label replace compress booktabs wrap varwidth(40)
esttab bFEDJ_v2elturnhog bFEDJ_v2elturnhos bFEDJ_v2eltvrig bFEDJ_e_wbgi_pve bFEDJ_instabEvent using "${Tables}/binaryIndFEDJ.tex", title(\label{binaryIndFEDJ}) label replace compress booktabs wrap varwidth(40)

eststo clear

*DF
foreach stabVar in `StabVars' {
reg `stabVar' irregtd fixed_rate, robust
eststo bolsDF_`stabVar'
xtreg `stabVar' irregtd fixed_rate, fe cluster(country)
eststo bFEDF_`stabVar'
}
esttab bolsDF_v2elturnhog bolsDF_v2elturnhos bolsDF_v2eltvrig bolsDF_e_wbgi_pve bolsDF_instabEvent using "${Tables}/binaryIndOLSDF.tex", title(\label{binaryIndOLSDF}) label replace compress booktabs wrap varwidth(40)
esttab bFEDF_v2elturnhog bFEDF_v2elturnhos bFEDF_v2eltvrig bFEDF_e_wbgi_pve bFEDF_instabEvent using "${Tables}/binaryIndFEDF.tex", title(\label{binaryIndFEDF}) label replace compress booktabs wrap varwidth(40)

eststo clear

*****************************************************************************

* Controls
merge 1:1 country_name year using "${Intermediate_Data}/Clean_DPI", gen(merge7)
merge 1:1 country_name year using "${Intermediate_Data}/Clean_Visser", gen(merge8)

local noCorpControls "v2elreggov v2x_horacc checks auton author"
local fullcontrols "`noCorpControls' Coord Type"

local StabVarsnoWBPV "`ElStabVars' instabEvent"
* Exclude world bank violence indicator due to insufficient observations.
* Stop collinearity

*Full controls and all independents

*DJ
foreach stabVar in `StabVars' {
reg `stabVar' `primCommInstVarsDJ' `fullcontrols', robust
eststo fullcmiolsDJ_`stabVar'
xtreg `stabVar' `primCommInstVarsDJ' `fullcontrols', fe cluster(country)
eststo fullcmiFEDJ_`stabVar'
}
esttab fullcmiolsDJ_v2elturnhog fullcmiolsDJ_v2elturnhos fullcmiolsDJ_v2eltvrig fullcmiolsDJ_e_wbgi_pve fullcmiolsDJ_instabEvent using "${Tables}/fullcmultIndOLSDJ.tex", title(\label{fullcmultIndOLSDJ}) label replace compress booktabs wrap varwidth(40)

esttab fullcmiFEDJ_v2elturnhog fullcmiFEDJ_v2elturnhos fullcmiFEDJ_v2eltvrig fullcmiFEDJ_e_wbgi_pve fullcmiFEDJ_instabEvent using "${Tables}/fullcmultIndFEDJ.tex", title(\label{fullcmultIndFEDJ}) label replace compress booktabs wrap varwidth(40)

eststo clear

*DF
foreach stabVar in `StabVars' {
reg `stabVar' `primCommInstVarsDF' `fullcontrols', robust
eststo fullcmiolsDF_`stabVar'
xtreg `stabVar' `primCommInstVarsDF' `fullcontrols', fe cluster(country)
eststo fullcmiFEDF_`stabVar'
}
esttab fullcmiolsDF_v2elturnhog fullcmiolsDF_v2elturnhos fullcmiolsDF_v2eltvrig fullcmiolsDF_e_wbgi_pve fullcmiolsDF_instabEvent using "${Tables}/fullcmultIndOLSDF.tex", title(\label{fullcmultIndOLSDF}) label replace compress booktabs wrap varwidth(40)

esttab fullcmiFEDF_v2elturnhog fullcmiFEDF_v2elturnhos fullcmiFEDF_v2eltvrig fullcmiFEDF_e_wbgi_pve fullcmiFEDF_instabEvent using "${Tables}/fullcmultIndFEDF.tex", title(\label{fullcmultIndFEDF}) label replace compress booktabs wrap varwidth(40)

eststo clear

*****************************************************************************

*No corp controls

*DJ
foreach stabVar in `StabVars' {
reg `stabVar' `primCommInstVarsDJ' `noCorpControls', robust
eststo nccmiolsDJ_`stabVar'
xtreg `stabVar' `primCommInstVarsDJ' `noCorpControls', fe cluster(country)
eststo nccmiFEDJ_`stabVar'
}
esttab nccmiolsDJ_v2elturnhog nccmiolsDJ_v2elturnhos nccmiolsDJ_v2eltvrig nccmiolsDJ_e_wbgi_pve nccmiolsDJ_instabEvent using "${Tables}/nccmultIndOLSDJ.tex", title(\label{nccmultIndOLSDJ}) label replace compress booktabs wrap varwidth(40)

esttab nccmiFEDJ_v2elturnhog nccmiFEDJ_v2elturnhos nccmiFEDJ_v2eltvrig nccmiFEDJ_e_wbgi_pve nccmiFEDJ_instabEvent using "${Tables}/nccmultIndFEDJ.tex", title(\label{nccmultIndFEDJ}) label replace compress booktabs wrap varwidth(40)

eststo clear

*DF
foreach stabVar in `StabVars' {
reg `stabVar' `primCommInstVarsDF' `noCorpControls', robust
eststo nccmiolsDF_`stabVar'
xtreg `stabVar' `primCommInstVarsDF' `noCorpControls', fe cluster(country)
eststo nccmiFEDF_`stabVar'
}
esttab nccmiolsDF_v2elturnhog nccmiolsDF_v2elturnhos nccmiolsDF_v2eltvrig nccmiolsDF_e_wbgi_pve nccmiolsDF_instabEvent using "${Tables}/nccmultIndOLSDF.tex", title(\label{nccmultIndOLSDF}) label replace compress booktabs wrap varwidth(40)

esttab nccmiFEDF_v2elturnhog nccmiFEDF_v2elturnhos nccmiFEDF_v2eltvrig nccmiFEDF_e_wbgi_pve nccmiFEDF_instabEvent using "${Tables}/nccmultIndFEDF.tex", title(\label{nccmultIndFEDF}) label replace compress booktabs wrap varwidth(40)

eststo clear

*Once binaries are in order- logit check with controls?
*xtlogit `stabVar' `commVar' `fullcontrols', fe
*eststo clogFE_`stabVar'`commVar'
*clogFE_`stabVar'`commVar' 
*xtlogit `stabVar' `commVar' `noCorpControls', fe
*eststo nclogFE_`stabVar'`commVar'
*nclogFE_`stabVar'`commVar'

*Go back and look at c results and maybe chuck some controls.

save "${Intermediate_Data}/OLS_FEanalysis_Ready", replace

*****************************************************************************

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
*esttab fivs_v2elturnhog fivs_v2elturnhos fivs_v2eltvrig fivs_e_wbgi_pve fivs_instabEvent using "${Tables}/fivs.tex", replace compress wrap varwidth(40) tex

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

esttab ifivs_v2elturnhog ifivs_v2elturnhos ifivs_v2eltvrig ifivs_e_wbgi_pve ifivs_instabEvent using "${Tables}/ifivs.tex", title(\label{ifivs}) label replace compress booktabs wrap varwidth(40)

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

esttab ifivs2_v2elturnhog ifivs2_v2elturnhos ifivs2_v2eltvrig ifivs2_e_wbgi_pve ifivs2_instabEvent using "${Tables}/ifivs2.tex", title(\label{ifivs2}) label replace compress booktabs wrap varwidth(40)

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

esttab ifivs3_v2elturnhog ifivs3_v2elturnhos ifivs3_v2eltvrig ifivs3_e_wbgi_pve ifivs3_instabEvent using "${Tables}/ifivs3.tex", title(\label{ifivs3}) label replace compress booktabs wrap varwidth(40)

* OECD instrument with de facto cbi
ivregress 2sls v2elturnhog (irregtd RRrate = ssbizagg iwbaggGDP), robust
eststo ifivs4_v2elturnhog
ivregress 2sls v2elturnhos (irregtd RRrate = ssbizagg iwbaggGDP), robust
eststo ifivs4_v2elturnhos
ivregress 2sls v2eltvrig (irregtd RRrate = ssbizagg iwbaggGDP), robust
eststo ifivs4_v2eltvrig
ivregress 2sls e_wbgi_pve (irregtd RRrate = ssbizagg iwbaggGDP), robust
eststo ifivs4_e_wbgi_pve

esttab ifivs4_v2elturnhog ifivs4_v2elturnhos ifivs4_v2eltvrig ifivs4_e_wbgi_pve using "${Tables}/ifivs4.tex", title(\label{ifivs4}) label replace compress booktabs wrap varwidth(40)

* Mini regressions for RRrate standalone
ivregress 2sls v2eltvrig (RRrate = ivaggGDP), robust
eststo miniLH
ivregress 2sls e_wbgi_pve (RRrate = ivaggGDP), robust
eststo miniWB
esttab miniLH miniWB using "${Tables}/miniRRIVs.tex", title(\label{miniRRIVs}) label replace compress booktabs wrap varwidth(40)

*xtivreg: I don't think this is doable, as a lot of the first stages don't work out anymore.

save "${Intermediate_Data}/IV_Analysis_Ready", replace

*****************************************************************************

* Capital controls (capital account) level robustness
merge 1:1 country_name year using "${Intermediate_Data}/Clean_kaopen", gen(merge9)

hist ka_open
* Set high as "above median/50th percentile"
egen mka_open = median(ka_open)
gen highka_open = (ka_open > mka_open) if ka_open != .

* Repeat regs for high and low samples. Determine which things to run by results of earlier regressions.

*DJ High
foreach stabVar in `StabVars' {
xtreg `stabVar' `primCommInstVarsDJ' if highka_open, fe cluster(country)
eststo hkmiFEDJ_`stabVar'
}

esttab hkmiFEDJ_v2elturnhog hkmiFEDJ_v2elturnhos hkmiFEDJ_v2eltvrig hkmiFEDJ_e_wbgi_pve hkmiFEDJ_instabEvent using "${Tables}/hkmultIndFEDJ.tex", title(\label{hkmultIndFEDJ}) label replace compress booktabs wrap varwidth(40)

*DF High
foreach stabVar in `StabVars' {
xtreg `stabVar' `primCommInstVarsDF' if highka_open, fe cluster(country)
eststo hkmiFEDF_`stabVar'
}

esttab hkmiFEDF_v2elturnhog hkmiFEDF_v2elturnhos hkmiFEDF_v2eltvrig hkmiFEDF_e_wbgi_pve hkmiFEDF_instabEvent using "${Tables}/hkmultIndFEDF.tex", title(\label{hkmultIndFEDF}) label replace compress booktabs wrap varwidth(40)

*DJ Low
foreach stabVar in `StabVars' {
xtreg `stabVar' `primCommInstVarsDJ' if !highka_open, fe cluster(country) 
eststo lkmiFEDJ_`stabVar'
}

esttab lkmiFEDJ_v2elturnhog lkmiFEDJ_v2elturnhos lkmiFEDJ_v2eltvrig lkmiFEDJ_e_wbgi_pve lkmiFEDJ_instabEvent using "${Tables}/lkmultIndFEDJ.tex", title(\label{lkmultIndFEDJ}) label replace compress booktabs wrap varwidth(40)

eststo clear

*DF Low
foreach stabVar in `StabVars' {
xtreg `stabVar' `primCommInstVarsDF' if !highka_open, fe cluster(country) 
eststo lkmiFEDF_`stabVar'
}

esttab lkmiFEDF_v2elturnhog lkmiFEDF_v2elturnhos lkmiFEDF_v2eltvrig lkmiFEDF_e_wbgi_pve lkmiFEDF_instabEvent using "${Tables}/lkmultIndFEDF.tex", title(\label{lkmultIndFEDF}) label replace compress booktabs wrap varwidth(40)

eststo clear

* Interaction term analysis for ka_open

*DJ
foreach stabVar in `StabVars' {
xtreg `stabVar' c.lvaw_gar##c.ka_open c.RRrate##c.ka_open, fe cluster(country)
eststo ikmiFEDJ_`stabVar'
}

esttab ikmiFEDJ_v2elturnhog ikmiFEDJ_v2elturnhos ikmiFEDJ_v2eltvrig ikmiFEDJ_e_wbgi_pve ikmiFEDJ_instabEvent using "${Tables}/ikmultIndFEDJ.tex", title(\label{ikmultIndFEDJ}) label replace compress booktabs wrap varwidth(40)

eststo clear

*DF
foreach stabVar in `StabVars' {
xtreg `stabVar' i.irregtd##c.ka_open c.RRrate##c.ka_open, fe cluster(country)
eststo ikmiFEDF_`stabVar'
}

esttab ikmiFEDF_v2elturnhog ikmiFEDF_v2elturnhos ikmiFEDF_v2eltvrig ikmiFEDF_e_wbgi_pve ikmiFEDF_instabEvent using "${Tables}/ikmultIndFEDF.tex", title(\label{ikmultIndFEDF}) label replace compress booktabs wrap varwidth(40)

eststo clear

save "${Intermediate_Data}/capaccount_Analysis_Ready",  replace

*****************************************************************************

* Deeper political institutional analysis.
* HOS = HOG
local HOSHOGStabVars = "v2elturnhog v2elturnhos"

*DJ
foreach stabVar in `HOSHOGStabVars' {
xtreg `stabVar' c.lvaw_gar##i.v2exhoshog c.RRrate##i.v2exhoshog, fe cluster(country)
eststo hoshogmiFEDJ_`stabVar'
}
esttab hoshogmiFEDJ_v2elturnhog hoshogmiFEDJ_v2elturnhos using "${Tables}/hoshogmultIndFEDJ.tex", title(\label{hoshogmultIndFEDJ}) label replace compress booktabs wrap varwidth(40)

*DF
foreach stabVar in `HOSHOGStabVars' {
xtreg `stabVar' i.irregtd##i.v2exhoshog c.RRrate##i.v2exhoshog, fe cluster(country)
eststo hoshogmiFEDF_`stabVar'
}
esttab hoshogmiFEDF_v2elturnhog hoshogmiFEDF_v2elturnhos using "${Tables}/hoshogmultIndFEDF.tex", title(\label{hoshogmultIndFEDF}) label replace compress booktabs wrap varwidth(40)

* WHAT IN THE WORLD IS GOING ON?
browse if v2exhoshog == 0

eststo clear

* Lower chamber legislates in practice
*DJ
xtreg v2eltvrig c.lvaw_gar##c.v2lglegplo c.RRrate##c.v2lglegplo, fe cluster(country)
eststo llpFEDJ_v2eltvrig
esttab llpFEDJ_v2eltvrig using "${Tables}/llpFEDJ.tex", title(\label{llpFEDJ}) label replace compress booktabs wrap varwidth(40)
*DF
xtreg v2eltvrig i.irregtd##c.v2lglegplo c.RRrate##c.v2lglegplo, fe cluster(country)
eststo llpFEDF_v2eltvrig
esttab llpFEDF_v2eltvrig using "${Tables}/llpFEDF.tex", title(\label{llpFEDF}) label replace compress booktabs wrap varwidth(40)

* Polity combined scores
* Note factor variables may not contain negative values hence
replace e_polity2 = e_polity2 + 10 if e_polity2 != .

*****************************************************************************

*Binary polity variable.
gen deme_polity2 = (e_polity2 > 10) if e_polity2 != .

*DJ
foreach stabVar in `StabVars' {
xtreg `stabVar' `primCommInstVarsDJ' c.lvaw_gar##i.deme_polity2 c.RRrate##i.deme_polity2, fe cluster(country)
eststo idemcmiFEDJ_`stabVar'
}
esttab idemcmiFEDJ_v2elturnhog idemcmiFEDJ_v2elturnhos idemcmiFEDJ_v2eltvrig idemcmiFEDJ_e_wbgi_pve idemcmiFEDJ_instabEvent using "${Tables}/binarydemcmultIndFEDJ.tex", title(\label{binarydemcmultIndFEDJ}) label replace compress booktabs wrap varwidth(40)

*DF
foreach stabVar in `StabVars' {
xtreg `stabVar' `primCommInstVarsDF' i.irregtd##i.deme_polity2 c.RRrate##i.deme_polity2, fe cluster(country)
eststo idemcmiFEDF_`stabVar'
}
esttab idemcmiFEDF_v2elturnhog idemcmiFEDF_v2elturnhos idemcmiFEDF_v2eltvrig idemcmiFEDF_e_wbgi_pve idemcmiFEDF_instabEvent using "${Tables}/binarydemcmultIndFEDF.tex", title(\label{binarydemcmultIndFEDF}) label replace compress booktabs wrap varwidth(40)

*****************************************************************************

* Split sample for democracy/nondemocracy
* Democracies
* DJ
foreach stabVar in `StabVars' {
xtreg `stabVar' `primCommInstVarsDJ' if deme_polity2 == 1, fe cluster(country)
eststo demFEDJ_`stabVar'
}
esttab demFEDJ_v2elturnhog demFEDJ_v2elturnhos demFEDJ_v2eltvrig demFEDJ_e_wbgi_pve demFEDJ_instabEvent using "${Tables}/democraciesFEDJ.tex", title(\label{democraciesFEDJ}) label replace compress booktabs wrap varwidth(40)
* DF
foreach stabVar in `StabVars' {
xtreg `stabVar' `primCommInstVarsDF' if deme_polity2 == 1, fe cluster(country)
eststo demFEDF_`stabVar'
}
esttab demFEDF_v2elturnhog demFEDF_v2elturnhos demFEDF_v2eltvrig demFEDF_e_wbgi_pve demFEDF_instabEvent using "${Tables}/democraciesFEDF.tex", title(\label{democraciesFEDF}) label replace compress booktabs wrap varwidth(40)

* Nondemocracies
* DJ
foreach stabVar in `StabVars' {
xtreg `stabVar' `primCommInstVarsDJ' if deme_polity2 == 0, fe cluster(country)
eststo nondemFEDJ_`stabVar'
}
esttab nondemFEDJ_v2elturnhog nondemFEDJ_v2elturnhos nondemFEDJ_v2eltvrig nondemFEDJ_e_wbgi_pve nondemFEDJ_instabEvent using "${Tables}/nondemocraciesFEDJ.tex", title(\label{nondemocraciesFEDJ}) label replace compress booktabs wrap varwidth(40)
* DF
foreach stabVar in `StabVars' {
xtreg `stabVar' `primCommInstVarsDF' if deme_polity2 == 0, fe cluster(country)
eststo nondemFEDF_`stabVar'
}
esttab nondemFEDF_v2elturnhog nondemFEDF_v2elturnhos nondemFEDF_v2eltvrig nondemFEDF_e_wbgi_pve nondemFEDF_instabEvent using "${Tables}/nondemocraciesFEDF.tex", title(\label{nondemocraciesFEDF}) label replace compress booktabs wrap varwidth(40)

* Bring all of these together edit for binary democracy
*DJ
foreach stabVar in `StabVars' {
xtreg `stabVar' `primCommInstVarsDJ' c.lvaw_gar##i.v2exhoshog c.RRrate##i.v2exhoshog c.lvaw_gar##c.v2lglegplo c.RRrate##c.v2lglegplo c.lvaw_gar##i.deme_polity2 c.RRrate##i.deme_polity2, fe cluster(country)
eststo ifullicmiFEDJ_`stabVar'
}
esttab ifullicmiFEDJ_v2elturnhog ifullicmiFEDJ_v2elturnhos ifullicmiFEDJ_v2eltvrig ifullicmiFEDJ_e_wbgi_pve ifullicmiFEDJ_instabEvent using "${Tables}/ifullicmultIndFEDJ.tex", title(\label{ifullicmultIndFEDJ}) label replace compress booktabs wrap varwidth(40)

eststo clear

*DF
foreach stabVar in `StabVars' {
xtreg `stabVar' `primCommInstVarsDF' i.irregtd##i.v2exhoshog c.RRrate##i.v2exhoshog i.irregtd##c.v2lglegplo c.RRrate##c.v2lglegplo i.irregtd##i.deme_polity2 c.RRrate##i.deme_polity2, fe cluster(country)
eststo ifullicmiFEDF_`stabVar'
}
esttab ifullicmiFEDF_v2elturnhog ifullicmiFEDF_v2elturnhos ifullicmiFEDF_v2eltvrig ifullicmiFEDF_e_wbgi_pve ifullicmiFEDF_instabEvent using "${Tables}/ifullicmultIndFEDF.tex", title(\label{ifullicmultIndFEDF}) label replace compress booktabs wrap varwidth(40)

eststo clear

* OECD Monetary Institutions aid as an IV?

save "${Intermediate_Data}/latepriorities_Ready", replace

*****************************************************************************

use "${Intermediate_Data}/latepriorities_Ready", clear
duplicates drop country year, force
xtset country year

* Independent variable lags
*DJ
foreach stabVar in `StabVars' {
xtreg `stabVar' `primCommInstVarsDJ' L(1/10).lvaw_gar L(1/10).RRrate, fe vce(cluster country)
eststo lagsDJ_`stabVar'
}
esttab lagsDJ_v2elturnhog lagsDJ_v2elturnhos lagsDJ_v2eltvrig lagsDJ_e_wbgi_pve lagsDJ_instabEvent using "${Tables}/lagsDJ.tex", title(\label{lagsDJ}) label replace compress longtable
eststo clear
*DF
foreach stabVar in `StabVars' {
xtreg `stabVar' `primCommInstVarsDF' L(1/10).irregtd L(1/10).RRrate, fe vce(cluster country)
eststo lagsDF_`stabVar'
}
esttab lagsDF_v2elturnhog lagsDF_v2elturnhos lagsDF_v2eltvrig lagsDF_e_wbgi_pve lagsDF_instabEvent using "${Tables}/lagsDF.tex", title(\label{lagsDF}) label replace compress longtable
eststo clear

* Ordinal regression (logistic), random effects
* Loop again mysteriously broken
*DJ
xtologit v2elturnhog `primCommInstVarsDJ', vce(cluster country)
eststo ordLogv2elturnhogDJ: margins, dydx(`primCommInstVarsDJ') post
* Be patient as the above command takes a long time to compute...
xtologit v2elturnhos `primCommInstVarsDJ', vce(cluster country)
eststo ordLogv2elturnhosDJ: margins, dydx(`primCommInstVarsDJ') post
xtologit v2eltvrig `primCommInstVarsDJ', vce(cluster country)
eststo ordLogv2eltvrigDJ: margins, dydx(`primCommInstVarsDJ') post

esttab ordLogv2elturnhogDJ ordLogv2elturnhosDJ ordLogv2eltvrigDJ using "${Tables}/ordLogDJ.tex", title(\label{ordLogDJ}) label replace compress booktabs wrap varwidth(40)
eststo clear

*DF
xtologit v2elturnhog `primCommInstVarsDF', vce(cluster country)
eststo ordLogv2elturnhogDF: margins, dydx(`primCommInstVarsDF') post
* Be patient as the above command takes a long time to compute...
xtologit v2elturnhos `primCommInstVarsDF', vce(cluster country)
eststo ordLogv2elturnhosDF: margins, dydx(`primCommInstVarsDF') post
xtologit v2eltvrig `primCommInstVarsDF', vce(cluster country)
eststo ordLogv2eltvrigDF: margins, dydx(`primCommInstVarsDF') post

esttab ordLogv2elturnhogDF ordLogv2elturnhosDF ordLogv2eltvrigDF using "${Tables}/ordLogDF.tex", title(\label{ordLogDF}) label replace compress booktabs wrap varwidth(40)
eststo clear

* Lagged Ordinal Logit: Margins computation does not run.
*DJ
xtologit v2elturnhog `primCommInstVarsDJ' L(1/10).lvaw_gar L(1/10).RRrate, vce(cluster country)
eststo lagordLogv2elturnhogDJ
*eststo mlagordLogv2elturnhog: margins, dydx(`primCommInstVars' L(1/10).lvaw_gar L(1/10).RRrate L(1/10).irregtd) post
* Be patient as the above command takes a long time to compute...
xtologit v2elturnhos `primCommInstVarsDJ' L(1/10).lvaw_gar L(1/10).RRrate, vce(cluster country)
eststo lagordLogv2elturnhosDJ
*eststo mlagordLogv2elturnhos: margins, dydx(`primCommInstVars' L(1/10).lvaw_gar L(1/10).RRrate L(1/10).irregtd) post
xtologit v2eltvrig `primCommInstVarsDJ' L(1/10).lvaw_gar L(1/10).RRrate, vce(cluster country)
eststo lagordLogv2eltvrigDJ
*eststo mlagordLogv2eltvrig: margins, dydx(`primCommInstVars' L(1/10).lvaw_gar L(1/10).RRrate L(1/10).irregtd) post
xtlogit binstabEvent `primCommInstVarsDJ' L(1/10).lvaw_gar L(1/10).RRrate, vce(cluster country)
eststo laglogInstabDJ

esttab lagordLogv2elturnhogDJ lagordLogv2elturnhosDJ lagordLogv2eltvrigDJ laglogInstabDJ using "${Tables}/lagordLogLogDJ.tex", title(\label{lagordLogLogDJ}) label replace compress longtable
eststo clear

*DF
xtologit v2elturnhog `primCommInstVarsDF' L(1/10).irregtd L(1/10).RRrate, vce(cluster country)
eststo lagordLogv2elturnhogDF
*eststo mlagordLogv2elturnhog: margins, dydx(`primCommInstVars' L(1/10).lvaw_gar L(1/10).RRrate L(1/10).irregtd) post
* Be patient as the above command takes a long time to compute...
xtologit v2elturnhos `primCommInstVarsDF' L(1/10).irregtd L(1/10).RRrate, vce(cluster country)
eststo lagordLogv2elturnhosDF
*eststo mlagordLogv2elturnhos: margins, dydx(`primCommInstVars' L(1/10).lvaw_gar L(1/10).RRrate L(1/10).irregtd) post
xtologit v2eltvrig `primCommInstVarsDF' L(1/10).irregtd L(1/10).RRrate, vce(cluster country)
eststo lagordLogv2eltvrigDF
*eststo mlagordLogv2eltvrig: margins, dydx(`primCommInstVars' L(1/10).lvaw_gar L(1/10).RRrate L(1/10).irregtd) post
xtlogit binstabEvent `primCommInstVarsDF' L(1/10).irregtd L(1/10).RRrate, vce(cluster country)
eststo laglogInstabDF

esttab lagordLogv2elturnhogDF lagordLogv2elturnhosDF lagordLogv2eltvrigDF laglogInstabDF using "${Tables}/lagordLogLogDF.tex", title(\label{lagordLogLogDF}) label replace compress longtable
eststo clear

* Lagged Bin Stab Logit: Margins computation does not run.
*xtlogit binstabEvent `primCommInstVars' L(1/10).lvaw_gar L(1/10).RRrate L(1/10).irregtd, fe
*eststo mlaglf_binstabEvent: margins, dydx(`primCommInstVars' L(1/10).lvaw_gar L(1/10).RRrate L(1/10).irregtd) post
*esttab laglf_binstabEvent using "${Tables}/laglogBinInstabEvent.tex", label replace compress booktabs wrap varwidth(40)

* Arellano Bond Specification

*****************************************************************************

* Summary Statistics for the entire dataset
estpost sum
esttab . using "${Tables}/sumstatsAll.tex", title(\label{sumstatsAll}) label cells(mean(label(Mean)) sd(par label(Standard Deviation)) count(label(Observations))) noobs replace longtable

use "${Intermediate_Data}/latepriorities_Ready", clear

* Recreating Appendix Early Tables (were A1 or A3 and A2 i think pre corr)
reg v2elturnhog irregtd, robust
eststo a11
xtreg v2elturnhog irregtd, fe vce(cluster country)
eststo a12
esttab a11 a12 using "${Tables}/irregtdHOGalone.tex", title(\label{irregtdHOGalone}) label replace compress booktabs wrap varwidth(40)

reg v2elturnhog tinoff, robust
eststo a21
xtreg v2elturnhog tinoff, fe vce(cluster country)
eststo a22
esttab a21 a22 using "${Tables}/timeinoffHOGalone.tex", title(\label{timeinoffHOGalone}) label replace compress booktabs wrap varwidth(40)

* Recreating more appendix tables: RRrate and WB alone, RRrate and instabevent alone
reg e_wbgi_pve RRrate, robust
eststo wbRROLS
xtreg e_wbgi_pve RRrate, fe vce(cluster country)
eststo wbRRFE
esttab wbRROLS wbRRFE using "${Tables}/WBratesalone.tex", title(\label{WBratesalone}) label replace compress booktabs wrap varwidth(40)

reg instabEvent RRrate, robust
eststo instabRROLS
xtreg instabEvent RRrate, fe vce(cluster country)
eststo instabRRFE
esttab instabRROLS instabRRFE using "${Tables}/instabRRalone.tex", title(\label{instabRRalone}) label replace compress booktabs wrap varwidth(40)

* Capture ordered logit coeffs
duplicates drop country year, force
xtset country year

*DJ
xtologit v2elturnhog `primCommInstVarsDJ', vce(cluster country)
eststo cordLogv2elturnhogDJ
xtologit v2elturnhos `primCommInstVarsDJ', vce(cluster country)
eststo cordLogv2elturnhosDJ
xtologit v2eltvrig `primCommInstVarsDJ', vce(cluster country)
eststo cordLogv2eltvrigDJ

esttab cordLogv2elturnhogDJ cordLogv2elturnhosDJ cordLogv2eltvrigDJ using "${Tables}/coeffordLogDJ.tex", title(\label{coeffordLogDJ}) label replace compress booktabs wrap varwidth(40)
eststo clear

*DF
xtologit v2elturnhog `primCommInstVarsDF', vce(cluster country)
eststo cordLogv2elturnhogDF
xtologit v2elturnhos `primCommInstVarsDF', vce(cluster country)
eststo cordLogv2elturnhosDF
xtologit v2eltvrig `primCommInstVarsDF', vce(cluster country)
eststo cordLogv2eltvrigDF

esttab cordLogv2elturnhogDF cordLogv2elturnhosDF cordLogv2eltvrigDF using "${Tables}/coeffordLogDF.tex", title(\label{coeffordLogDF}) label replace compress booktabs wrap varwidth(40)
eststo clear

*****************************************************************************

*Prepping for CR
save "${Intermediate_Data}/CR_Priorities_Ready", replace

use "${Intermediate_Data}/CR_Priorities_Ready", clear

*Keeping the locals
local ElStabVars "v2elturnhog v2elturnhos v2eltvrig"
local PolStabVars "e_wbgi_pve instabEvent"
local StabVars "`ElStabVars' `PolStabVars'"
local primCommInstVarsDJ "lvaw_gar RRrate"
local primCommInstVarsDF "irregtd RRrate"

* Lagged interaction term analysis
gen DJinteraction = lvaw_gar * RRrate
label var DJinteraction "De Jure CBI * More Fixed Rate"
gen DFinteraction = irregtd * RRrate
label var DFinteraction "De Facto CBI * More Fixed Rate"

*Linear models
*DJ
foreach stabVar in `StabVars' {
xtreg `stabVar' `primCommInstVarsDJ' DJinteraction L(1/10).lvaw_gar L(1/10).RRrate L(1/10).DJinteraction, fe vce(cluster country)
eststo intlagsDJ`stabVar'
}
esttab intlagsDJv2elturnhog intlagsDJv2elturnhos intlagsDJv2eltvrig intlagsDJe_wbgi_pve intlagsDJinstabEvent using "${Tables}/intlagsDJ.tex", title(\label{intlagsDJ}) label replace compress booktabs wrap varwidth(40)
eststo clear
*DF
foreach stabVar in `StabVars' {
xtreg `stabVar' `primCommInstVarsDF' DFinteraction L(1/10).irregtd L(1/10).RRrate L(1/10).DFinteraction, fe vce(cluster country)
eststo intlagsDF`stabVar'
}
esttab intlagsDFv2elturnhog intlagsDFv2elturnhos intlagsDFv2eltvrig intlagsDFe_wbgi_pve intlagsDFinstabEvent using "${Tables}/intlagsDF.tex", title(\label{intlagsDF}) label replace compress longtable
eststo clear

*XT Logit models
*DJ
xtologit v2elturnhog `primCommInstVarsDJ' DJinteraction L(1/10).lvaw_gar L(1/10).RRrate L(1/10).DJinteraction, vce(cluster country)
eststo intlagordLogv2elturnhogDJ
*eststo mlagordLogv2elturnhog: margins, dydx(`primCommInstVars' L(1/10).lvaw_gar L(1/10).RRrate L(1/10).irregtd) post
* Be patient as the above command takes a long time to compute...
xtologit v2elturnhos `primCommInstVarsDJ' DJinteraction L(1/10).lvaw_gar L(1/10).RRrate L(1/10).DJinteraction, vce(cluster country)
eststo intlagordLogv2elturnhosDJ
*eststo mlagordLogv2elturnhos: margins, dydx(`primCommInstVars' L(1/10).lvaw_gar L(1/10).RRrate L(1/10).irregtd) post
xtologit v2eltvrig `primCommInstVarsDJ' DJinteraction L(1/10).lvaw_gar L(1/10).RRrate L(1/10).DJinteraction, vce(cluster country)
eststo intlagordLogv2eltvrigDJ
*eststo mlagordLogv2eltvrig: margins, dydx(`primCommInstVars' L(1/10).lvaw_gar L(1/10).RRrate L(1/10).irregtd) post
xtlogit binstabEvent `primCommInstVarsDJ' DJinteraction L(1/10).lvaw_gar L(1/10).RRrate L(1/10).DJinteraction, vce(cluster country)
eststo intlaglogInstabDJ

esttab intlagordLogv2elturnhogDJ intlagordLogv2elturnhosDJ intlagordLogv2eltvrigDJ intlaglogInstabDJ using "${Tables}/intlagordLogLogDJ.tex", title(\label{intlagordLogLogDJ}) label replace compress longtable
eststo clear

*DF
xtologit v2elturnhog `primCommInstVarsDF' DFinteraction L(1/10).irregtd L(1/10).RRrate L(1/10).DFinteraction, vce(cluster country)
eststo intlagordLogv2elturnhogDF
*eststo mlagordLogv2elturnhog: margins, dydx(`primCommInstVars' L(1/10).lvaw_gar L(1/10).RRrate L(1/10).irregtd) post
* Be patient as the above command takes a long time to compute...
xtologit v2elturnhos `primCommInstVarsDF' DFinteraction L(1/10).irregtd L(1/10).RRrate L(1/10).DFinteraction, vce(cluster country)
eststo intlagordLogv2elturnhosDF
*eststo mlagordLogv2elturnhos: margins, dydx(`primCommInstVars' L(1/10).lvaw_gar L(1/10).RRrate L(1/10).irregtd) post
xtologit v2eltvrig `primCommInstVarsDF' DFinteraction L(1/10).irregtd L(1/10).RRrate L(1/10).DFinteraction, vce(cluster country)
eststo intlagordLogv2eltvrigDF
*eststo mlagordLogv2eltvrig: margins, dydx(`primCommInstVars' L(1/10).lvaw_gar L(1/10).RRrate L(1/10).irregtd) post
xtlogit binstabEvent `primCommInstVarsDF' DFinteraction L(1/10).irregtd L(1/10).RRrate L(1/10).DFinteraction, vce(cluster country)
eststo intlaglogInstabDF

esttab intlagordLogv2elturnhogDF intlagordLogv2elturnhosDF intlagordLogv2eltvrigDF intlaglogInstabDF using "${Tables}/intlagordLogLogDF.tex", title(\label{intlagordLogLogDF}) label replace compress longtable
eststo clear

* IVs split sample always

* IVs and a democracy investigation
* Democracies
* De jure independence check
ivregress 2sls v2elturnhog (lvaw_gar RRrate = itertEd iwbaggGDP) if deme_polity2 == 1, robust
eststo demIfivs_v2elturnhog
ivregress 2sls v2elturnhos (lvaw_gar RRrate = itertEd iwbaggGDP) if deme_polity2 == 1, robust
eststo demIfivs_v2elturnhos
ivregress 2sls v2eltvrig (lvaw_gar RRrate = itertEd iwbaggGDP) if deme_polity2 == 1, robust
eststo demIfivs_v2eltvrig
ivregress 2sls e_wbgi_pve (lvaw_gar RRrate = itertEd iwbaggGDP) if deme_polity2 == 1, robust
eststo demIfivs_e_wbgi_pve
ivregress 2sls instabEvent (lvaw_gar RRrate = itertEd iwbaggGDP) if deme_polity2 == 1, robust
eststo demIfivs_instabEvent

esttab demIfivs_v2elturnhog demIfivs_v2elturnhos demIfivs_v2eltvrig demIfivs_e_wbgi_pve demIfivs_instabEvent using "${Tables}/demIfivs.tex", title(\label{demIfivs}) label replace compress booktabs wrap varwidth(40)

* De facto independence check
ivregress 2sls v2elturnhog (irregtd RRrate = itertEd iwbaggGDP) if deme_polity2 == 1, robust
eststo demIfivs2_v2elturnhog
ivregress 2sls v2elturnhos (irregtd RRrate = itertEd iwbaggGDP) if deme_polity2 == 1, robust
eststo demIfivs2_v2elturnhos
ivregress 2sls v2eltvrig (irregtd RRrate = itertEd iwbaggGDP) if deme_polity2 == 1, robust
eststo demIfivs2_v2eltvrig
ivregress 2sls e_wbgi_pve (irregtd RRrate = itertEd iwbaggGDP) if deme_polity2 == 1, robust
eststo demIfivs2_e_wbgi_pve
ivregress 2sls instabEvent (irregtd RRrate = itertEd iwbaggGDP) if deme_polity2 == 1, robust
eststo demIfivs2_instabEvent

esttab demIfivs2_v2elturnhog demIfivs2_v2elturnhos demIfivs2_v2eltvrig demIfivs2_e_wbgi_pve demIfivs2_instabEvent using "${Tables}/demIfivs2.tex", title(\label{demIfivs2}) label replace compress booktabs wrap varwidth(40)

* Try the OECD instrument, with de jure cbi
ivregress 2sls v2elturnhog (lvaw_gar RRrate = ssbizagg iwbaggGDP) if deme_polity2 == 1, robust
eststo demIfivs3_v2elturnhog
ivregress 2sls v2elturnhos (lvaw_gar RRrate = ssbizagg iwbaggGDP) if deme_polity2 == 1, robust
eststo demIfivs3_v2elturnhos
ivregress 2sls v2eltvrig (lvaw_gar RRrate = ssbizagg iwbaggGDP) if deme_polity2 == 1, robust
eststo demIfivs3_v2eltvrig
ivregress 2sls e_wbgi_pve (lvaw_gar RRrate = ssbizagg iwbaggGDP) if deme_polity2 == 1, robust
eststo demIfivs3_e_wbgi_pve
ivregress 2sls instabEvent (lvaw_gar RRrate = ssbizagg iwbaggGDP) if deme_polity2 == 1, robust noconstant
eststo demIfivs3_instabEvent

esttab demIfivs3_v2elturnhog demIfivs3_v2elturnhos demIfivs3_v2eltvrig demIfivs3_e_wbgi_pve demIfivs3_instabEvent using "${Tables}/demIfivs3.tex", title(\label{demIfivs3}) label replace compress booktabs wrap varwidth(40)

* OECD instrument with de facto cbi
ivregress 2sls v2elturnhog (irregtd RRrate = ssbizagg iwbaggGDP) if deme_polity2 == 1, robust
eststo demIfivs4_v2elturnhog
ivregress 2sls v2elturnhos (irregtd RRrate = ssbizagg iwbaggGDP) if deme_polity2 == 1, robust
eststo demIfivs4_v2elturnhos
ivregress 2sls v2eltvrig (irregtd RRrate = ssbizagg iwbaggGDP) if deme_polity2 == 1, robust
eststo demIfivs4_v2eltvrig
ivregress 2sls e_wbgi_pve (irregtd RRrate = ssbizagg iwbaggGDP) if deme_polity2 == 1, robust
eststo demIfivs4_e_wbgi_pve

esttab demIfivs4_v2elturnhog demIfivs4_v2elturnhos demIfivs4_v2eltvrig demIfivs4_e_wbgi_pve using "${Tables}/demIfivs4.tex", title(\label{demIfivs4}) label replace compress booktabs wrap varwidth(40)

*Nondemocracies
* De jure independence check
ivregress 2sls v2elturnhog (lvaw_gar RRrate = itertEd iwbaggGDP) if deme_polity2 == 0, robust
eststo ndemIfivs_v2elturnhog
ivregress 2sls v2elturnhos (lvaw_gar RRrate = itertEd iwbaggGDP) if deme_polity2 == 0, robust
eststo ndemIfivs_v2elturnhos
ivregress 2sls v2eltvrig (lvaw_gar RRrate = itertEd iwbaggGDP) if deme_polity2 == 0, robust
eststo ndemIfivs_v2eltvrig
ivregress 2sls e_wbgi_pve (lvaw_gar RRrate = itertEd iwbaggGDP) if deme_polity2 == 0, robust
eststo ndemIfivs_e_wbgi_pve
ivregress 2sls instabEvent (lvaw_gar RRrate = itertEd iwbaggGDP) if deme_polity2 == 0, robust
eststo ndemIfivs_instabEvent

esttab ndemIfivs_v2elturnhog ndemIfivs_v2elturnhos ndemIfivs_v2eltvrig ndemIfivs_e_wbgi_pve ndemIfivs_instabEvent using "${Tables}/ndemIfivs.tex", title(\label{ndemIfivs}) label replace compress booktabs wrap varwidth(40)

* De facto independence check
ivregress 2sls v2elturnhog (irregtd RRrate = itertEd iwbaggGDP) if deme_polity2 == 0, robust
eststo ndemIfivs2_v2elturnhog
ivregress 2sls v2elturnhos (irregtd RRrate = itertEd iwbaggGDP) if deme_polity2 == 0, robust
eststo ndemIfivs2_v2elturnhos
ivregress 2sls v2eltvrig (irregtd RRrate = itertEd iwbaggGDP) if deme_polity2 == 0, robust
eststo ndemIfivs2_v2eltvrig
ivregress 2sls e_wbgi_pve (irregtd RRrate = itertEd iwbaggGDP) if deme_polity2 == 0, robust
eststo ndemIfivs2_e_wbgi_pve
ivregress 2sls instabEvent (irregtd RRrate = itertEd iwbaggGDP) if deme_polity2 == 0, robust
eststo ndemIfivs2_instabEvent

esttab ndemIfivs2_v2elturnhog ndemIfivs2_v2elturnhos ndemIfivs2_v2eltvrig ndemIfivs2_e_wbgi_pve ndemIfivs2_instabEvent using "${Tables}/ndemIfivs2.tex", title(\label{ndemIfivs2}) label replace compress booktabs wrap varwidth(40)

* Try the OECD instrument, with de jure cbi
* NO OBSERVATIONS!!!
*ivregress 2sls v2elturnhog (lvaw_gar RRrate = ssbizagg iwbaggGDP) if deme_polity2 == 0, robust
*eststo ndemIfivs3_v2elturnhog
*ivregress 2sls v2elturnhos (lvaw_gar RRrate = ssbizagg iwbaggGDP) if deme_polity2 == 0, robust
*eststo ndemIfivs3_v2elturnhos
*ivregress 2sls v2eltvrig (lvaw_gar RRrate = ssbizagg iwbaggGDP) if deme_polity2 == 0, robust
*eststo ndemIfivs3_v2eltvrig
*ivregress 2sls e_wbgi_pve (lvaw_gar RRrate = ssbizagg iwbaggGDP) if deme_polity2 == 0, robust
*eststo ndemIfivs3_e_wbgi_pve
*ivregress 2sls instabEvent (lvaw_gar RRrate = ssbizagg iwbaggGDP) if deme_polity2 == 0, robust noconstant
*eststo ndemIfivs3_instabEvent

*esttab ndemIfivs3_v2elturnhog ndemIfivs3_v2elturnhos ndemIfivs3_v2eltvrig ndemIfivs3_e_wbgi_pve ndemIfivs3_instabEvent using "${Tables}/ndemIfivs3.tex", label replace compress booktabs wrap varwidth(40)

* OECD instrument with de facto cbi
*ivregress 2sls v2elturnhog (irregtd RRrate = ssbizagg iwbaggGDP) if deme_polity2 == 0, robust
*eststo ndemIfivs4_v2elturnhog
*ivregress 2sls v2elturnhos (irregtd RRrate = ssbizagg iwbaggGDP) if deme_polity2 == 0, robust
*eststo ndemIfivs4_v2elturnhos
*ivregress 2sls v2eltvrig (irregtd RRrate = ssbizagg iwbaggGDP) if deme_polity2 == 0, robust
*eststo ndemIfivs4_v2eltvrig
*ivregress 2sls e_wbgi_pve (irregtd RRrate = ssbizagg iwbaggGDP) if deme_polity2 == 0, robust
*eststo ndemIfivs4_e_wbgi_pve

*esttab ndemIfivs4_v2elturnhog ndemIfivs4_v2elturnhos ndemIfivs4_v2eltvrig ndemIfivs4_e_wbgi_pve using "${Tables}/ndemIfivs4.tex", label replace compress booktabs wrap varwidth(40)


* IVs and a cap controls investigation

* High ka_open (open)
* De jure independence
ivregress 2sls v2elturnhog (lvaw_gar RRrate = itertEd iwbaggGDP) if highka_open, robust
eststo hiKfivs_v2elturnhog
ivregress 2sls v2elturnhos (lvaw_gar RRrate = itertEd iwbaggGDP) if highka_open, robust
eststo hiKfivs_v2elturnhos
ivregress 2sls v2eltvrig (lvaw_gar RRrate = itertEd iwbaggGDP) if highka_open, robust
eststo hiKfivs_v2eltvrig
ivregress 2sls e_wbgi_pve (lvaw_gar RRrate = itertEd iwbaggGDP) if highka_open, robust
eststo hiKfivs_e_wbgi_pve
ivregress 2sls instabEvent (lvaw_gar RRrate = itertEd iwbaggGDP) if highka_open, robust
eststo hiKfivs_instabEvent

esttab hiKfivs_v2elturnhog hiKfivs_v2elturnhos hiKfivs_v2eltvrig hiKfivs_e_wbgi_pve hiKfivs_instabEvent using "${Tables}/hiKfivs.tex", title(\label{hiKfivs}) label replace compress booktabs wrap varwidth(40)

* De facto independence check
ivregress 2sls v2elturnhog (irregtd RRrate = itertEd iwbaggGDP) if highka_open, robust
eststo hiKfivs2_v2elturnhog
ivregress 2sls v2elturnhos (irregtd RRrate = itertEd iwbaggGDP) if highka_open, robust
eststo hiKfivs2_v2elturnhos
ivregress 2sls v2eltvrig (irregtd RRrate = itertEd iwbaggGDP) if highka_open, robust
eststo hiKfivs2_v2eltvrig
ivregress 2sls e_wbgi_pve (irregtd RRrate = itertEd iwbaggGDP) if highka_open, robust
eststo hiKfivs2_e_wbgi_pve
ivregress 2sls instabEvent (irregtd RRrate = itertEd iwbaggGDP) if highka_open, robust
eststo hiKfivs2_instabEvent

esttab hiKfivs2_v2elturnhog hiKfivs2_v2elturnhos hiKfivs2_v2eltvrig hiKfivs2_e_wbgi_pve hiKfivs2_instabEvent using "${Tables}/hiKfivs2.tex", title(\label{hiKfivs2}) label replace compress booktabs wrap varwidth(40)

* Try the OECD instrument, with de jure cbi
ivregress 2sls v2elturnhog (lvaw_gar RRrate = ssbizagg iwbaggGDP) if highka_open, robust
eststo hiKfivs3_v2elturnhog
ivregress 2sls v2elturnhos (lvaw_gar RRrate = ssbizagg iwbaggGDP) if highka_open, robust
eststo hiKfivs3_v2elturnhos
ivregress 2sls v2eltvrig (lvaw_gar RRrate = ssbizagg iwbaggGDP) if highka_open, robust
eststo hiKfivs3_v2eltvrig
ivregress 2sls e_wbgi_pve (lvaw_gar RRrate = ssbizagg iwbaggGDP) if highka_open, robust
eststo hiKfivs3_e_wbgi_pve
ivregress 2sls instabEvent (lvaw_gar RRrate = ssbizagg iwbaggGDP) if highka_open, robust noconstant
eststo hiKfivs3_instabEvent

esttab hiKfivs3_v2elturnhog hiKfivs3_v2elturnhos hiKfivs3_v2eltvrig hiKfivs3_e_wbgi_pve hiKfivs3_instabEvent using "${Tables}/hiKfivs3.tex", title(\label{hiKfivs3}) label replace compress booktabs wrap varwidth(40)

* OECD instrument with de facto cbi
ivregress 2sls v2elturnhog (irregtd RRrate = ssbizagg iwbaggGDP) if highka_open, robust
eststo hiKfivs4_v2elturnhog
ivregress 2sls v2elturnhos (irregtd RRrate = ssbizagg iwbaggGDP) if highka_open, robust
eststo hiKfivs4_v2elturnhos
ivregress 2sls v2eltvrig (irregtd RRrate = ssbizagg iwbaggGDP) if highka_open, robust
eststo hiKfivs4_v2eltvrig
ivregress 2sls e_wbgi_pve (irregtd RRrate = ssbizagg iwbaggGDP) if highka_open, robust
eststo hiKfivs4_e_wbgi_pve

esttab hiKfivs4_v2elturnhog hiKfivs4_v2elturnhos hiKfivs4_v2eltvrig hiKfivs4_e_wbgi_pve using "${Tables}/hiKfivs4.tex", title(\label{hiKfivs4}) label replace compress booktabs wrap varwidth(40)

* Low Kaopen
* De jure independence check
ivregress 2sls v2elturnhog (lvaw_gar RRrate = itertEd iwbaggGDP) if !highka_open, robust
eststo lowKIfivs_v2elturnhog
ivregress 2sls v2elturnhos (lvaw_gar RRrate = itertEd iwbaggGDP) if !highka_open, robust
eststo lowKIfivs_v2elturnhos
ivregress 2sls v2eltvrig (lvaw_gar RRrate = itertEd iwbaggGDP) if !highka_open, robust
eststo lowKIfivs_v2eltvrig
ivregress 2sls e_wbgi_pve (lvaw_gar RRrate = itertEd iwbaggGDP) if !highka_open, robust
eststo lowKIfivs_e_wbgi_pve
ivregress 2sls instabEvent (lvaw_gar RRrate = itertEd iwbaggGDP) if !highka_open, robust
eststo lowKIfivs_instabEvent

esttab lowKIfivs_v2elturnhog lowKIfivs_v2elturnhos lowKIfivs_v2eltvrig lowKIfivs_e_wbgi_pve lowKIfivs_instabEvent using "${Tables}/lowKIfivs.tex", title(\label{lowKIfivs}) label replace compress booktabs wrap varwidth(40)

* De facto independence check
ivregress 2sls v2elturnhog (irregtd RRrate = itertEd iwbaggGDP) if !highka_open, robust
eststo lowKIfivs2_v2elturnhog
ivregress 2sls v2elturnhos (irregtd RRrate = itertEd iwbaggGDP) if !highka_open, robust
eststo lowKIfivs2_v2elturnhos
ivregress 2sls v2eltvrig (irregtd RRrate = itertEd iwbaggGDP) if !highka_open, robust
eststo lowKIfivs2_v2eltvrig
ivregress 2sls e_wbgi_pve (irregtd RRrate = itertEd iwbaggGDP) if !highka_open, robust
eststo lowKIfivs2_e_wbgi_pve
ivregress 2sls instabEvent (irregtd RRrate = itertEd iwbaggGDP) if !highka_open, robust
eststo lowKIfivs2_instabEvent

esttab lowKIfivs2_v2elturnhog lowKIfivs2_v2elturnhos lowKIfivs2_v2eltvrig lowKIfivs2_e_wbgi_pve lowKIfivs2_instabEvent using "${Tables}/lowKIfivs2.tex", title(\label{lowKIfivs2}) label replace compress booktabs wrap varwidth(40)

* Try the OECD instrument, with de jure cbi
*ivregress 2sls v2elturnhog (lvaw_gar RRrate = ssbizagg iwbaggGDP) if !highka_open, robust
*eststo lowKIfivs3_v2elturnhog
*ivregress 2sls v2elturnhos (lvaw_gar RRrate = ssbizagg iwbaggGDP) if !highka_open, robust
*eststo lowKIfivs3_v2elturnhos
*ivregress 2sls v2eltvrig (lvaw_gar RRrate = ssbizagg iwbaggGDP) if !highka_open, robust
*eststo lowKIfivs3_v2eltvrig
*ivregress 2sls e_wbgi_pve (lvaw_gar RRrate = ssbizagg iwbaggGDP) if !highka_open, robust
*eststo lowKIfivs3_e_wbgi_pve
*ivregress 2sls instabEvent (lvaw_gar RRrate = ssbizagg iwbaggGDP) if !highka_open, robust noconstant
*eststo lowKIfivs3_instabEvent

*esttab lowKIfivs3_v2elturnhog lowKIfivs3_v2elturnhos lowKIfivs3_v2eltvrig lowKIfivs3_e_wbgi_pve lowKIfivs3_instabEvent using "${Tables}/lowKIfivs3.tex", label replace compress booktabs wrap varwidth(40)

* OECD instrument with de facto cbi
ivregress 2sls v2elturnhog (irregtd RRrate = ssbizagg iwbaggGDP) if !highka_open, robust
eststo lowKIfivs4_v2elturnhog
ivregress 2sls v2elturnhos (irregtd RRrate = ssbizagg iwbaggGDP) if !highka_open, robust
eststo lowKIfivs4_v2elturnhos
ivregress 2sls v2eltvrig (irregtd RRrate = ssbizagg iwbaggGDP) if !highka_open, robust
eststo lowKIfivs4_v2eltvrig
ivregress 2sls e_wbgi_pve (irregtd RRrate = ssbizagg iwbaggGDP) if !highka_open, robust
eststo lowKIfivs4_e_wbgi_pve

esttab lowKIfivs4_v2elturnhog lowKIfivs4_v2elturnhos lowKIfivs4_v2eltvrig lowKIfivs4_e_wbgi_pve using "${Tables}/lowKIfivs4.tex", title(\label{lowKIfivs4}) label replace compress booktabs wrap varwidth(40)

* Lags and a democracy investigation

gen demDJinteraction = lvaw_gar * e_polity2
label var demDJinteraction "De Jure CBI * Polity Democracy"
gen demDFinteraction = irregtd * e_polity2
label var demDFinteraction "De Facto CBI * Polity Democracy"
gen demRRinteraction = RRrate * e_polity2
label var demRRinteraction "More Fixed Rate * Polity Democracy"

*Linear models
*DJ
foreach stabVar in `StabVars' {
xtreg `stabVar' `primCommInstVarsDJ' e_polity2 demDJinteraction demRRinteraction L(1/10).lvaw_gar L(1/10).RRrate L(1/10).e_polity2 L(1/10).demDJinteraction L(1/10).demRRinteraction, fe vce(cluster country)
eststo demintlagsDJ_`stabVar'
}
esttab demintlagsDJ_v2elturnhog demintlagsDJ_v2elturnhos demintlagsDJ_v2eltvrig demintlagsDJ_e_wbgi_pve demintlagsDJ_instabEvent using "${Tables}/demintlagsDJ.tex", title(\label{demintlagsDJ}) label replace compress longtable
eststo clear
*DF
foreach stabVar in `StabVars' {
xtreg `stabVar' `primCommInstVarsDF' demDFinteraction demRRinteraction e_polity2 L(1/10).irregtd L(1/10).RRrate L(1/10).e_polity2 L(1/10).demDFinteraction L(1/10).demRRinteraction, fe vce(cluster country)
eststo demintlagsDF_`stabVar'
}
esttab demintlagsDF_v2elturnhog demintlagsDF_v2elturnhos demintlagsDF_v2eltvrig demintlagsDF_e_wbgi_pve demintlagsDF_instabEvent using "${Tables}/demintlagsDF.tex", title(\label{demintlagsDF}) label replace compress longtable
eststo clear

*XT Logit models
*DJ
xtologit v2elturnhog `primCommInstVarsDJ' e_polity2 demDJinteraction demRRinteraction L(1/10).lvaw_gar L(1/10).RRrate L(1/10).e_polity2 L(1/10).demDJinteraction L(1/10).demRRinteraction, vce(cluster country)
eststo demIntLOLogHOGDJ
*eststo mlagordLogv2elturnhog: margins, dydx(`primCommInstVars' L(1/10).lvaw_gar L(1/10).RRrate L(1/10).irregtd) post
* Be patient as the above command takes a long time to compute...
xtologit v2elturnhos `primCommInstVarsDJ' e_polity2 demDJinteraction demRRinteraction L(1/10).lvaw_gar L(1/10).RRrate L(1/10).e_polity2 L(1/10).demDJinteraction L(1/10).demRRinteraction, vce(cluster country)
eststo demIntLOLogHOSDJ
*eststo mlagordLogv2elturnhos: margins, dydx(`primCommInstVars' L(1/10).lvaw_gar L(1/10).RRrate L(1/10).irregtd) post
xtologit v2eltvrig `primCommInstVarsDJ' e_polity2 demDJinteraction demRRinteraction L(1/10).lvaw_gar L(1/10).RRrate L(1/10).e_polity2 L(1/10).demDJinteraction L(1/10).demRRinteraction, vce(cluster country)
eststo demintlagordLogLHDJ
*eststo mlagordLogv2eltvrig: margins, dydx(`primCommInstVars' L(1/10).lvaw_gar L(1/10).RRrate L(1/10).irregtd) post
xtlogit binstabEvent `primCommInstVarsDJ' e_polity2 demDJinteraction demRRinteraction L(1/10).lvaw_gar L(1/10).RRrate L(1/10).e_polity2 L(1/10).demDJinteraction L(1/10).demRRinteraction, vce(cluster country)
eststo demintlaglogInstabDJ

esttab demIntLOLogHOGDJ demIntLOLogHOSDJ demintlagordLogLHDJ demintlaglogInstabDJ using "${Tables}/demintlagordLogLogDJ.tex", title(\label{demintlagordLogLogDJ}) label replace compress longtable
eststo clear

*DF
xtologit v2elturnhog `primCommInstVarsDF' e_polity2 demDFinteraction demRRinteraction L(1/10).irregtd L(1/10).RRrate L(1/10).e_polity2 L(1/10).demDFinteraction L(1/10).demRRinteraction, vce(cluster country)
eststo demintlagordLogHOGDF
*eststo mlagordLogv2elturnhog: margins, dydx(`primCommInstVars' L(1/10).lvaw_gar L(1/10).RRrate L(1/10).irregtd) post
* Be patient as the above command takes a long time to compute...
xtologit v2elturnhos `primCommInstVarsDF' e_polity2 demDFinteraction demRRinteraction L(1/10).irregtd L(1/10).RRrate L(1/10).e_polity2 L(1/10).demDFinteraction L(1/10).demRRinteraction, vce(cluster country)
eststo demintlagordLogHOSDF
*eststo mlagordLogv2elturnhos: margins, dydx(`primCommInstVars' L(1/10).lvaw_gar L(1/10).RRrate L(1/10).irregtd) post
xtologit v2eltvrig `primCommInstVarsDF' e_polity2 demDFinteraction demRRinteraction L(1/10).irregtd L(1/10).RRrate L(1/10).e_polity2 L(1/10).demDFinteraction L(1/10).demRRinteraction, vce(cluster country)
eststo demintlagordLogLHDF
*eststo mlagordLogv2eltvrig: margins, dydx(`primCommInstVars' L(1/10).lvaw_gar L(1/10).RRrate L(1/10).irregtd) post
xtlogit binstabEvent `primCommInstVarsDF' e_polity2 demDFinteraction demRRinteraction L(1/10).irregtd L(1/10).RRrate L(1/10).e_polity2 L(1/10).demDFinteraction L(1/10).demRRinteraction, vce(cluster country)
eststo demintlaglogInstabDF

esttab demintlagordLogHOGDF demintlagordLogHOSDF demintlagordLogLHDF demintlaglogInstabDF using "${Tables}/demintlagordLogLogDF.tex", title(\label{demintlagordLogLogDF}) label replace compress longtable
eststo clear

* Lags and a cap controls investigation

gen kapDJinteraction = lvaw_gar * ka_open
label var kapDJinteraction "De Jure CBI * Capital Account Openness"
gen kapDFinteraction = irregtd * ka_open
label var kapDFinteraction "De Facto CBI * Capital Account Openness"
gen kapRRinteraction = RRrate * ka_open
label var kapRRinteraction "More Fixed Rate * Capital Account Openness"

*****************************************************************************

* Correction 6-14-20: add in DJinteraction, DFinteraction where appropriate.

*Linear models
*DJ
foreach stabVar in `StabVars' {
    xtreg `stabVar' `primCommInstVarsDJ' ka_open kapDJinteraction kapRRinteraction DJinteraction L(1/10).lvaw_gar L(1/10).RRrate L(1/10).ka_open L(1/10).kapDJinteraction L(1/10).kapRRinteraction L(1/10).DJinteraction, fe vce(cluster country)
    eststo kapintlagsDJ_`stabVar'
}
esttab kapintlagsDJ_v2elturnhog kapintlagsDJ_v2elturnhos kapintlagsDJ_v2eltvrig kapintlagsDJ_e_wbgi_pve kapintlagsDJ_instabEvent using "${Tables}/kapintlagsDJ.tex", label replace compress longtable
eststo clear
*DF
foreach stabVar in `StabVars' {
    xtreg `stabVar' `primCommInstVarsDF' ka_open kapDFinteraction kapRRinteraction DFinteraction L(1/10).irregtd L(1/10).RRrate L(1/10).ka_open L(1/10).kapDFinteraction L(1/10).kapRRinteraction L(1/10).DFinteraction, fe vce(cluster country)
    eststo kapintlagsDF_`stabVar'
}
esttab kapintlagsDF_v2elturnhog kapintlagsDF_v2elturnhos kapintlagsDF_v2eltvrig kapintlagsDF_e_wbgi_pve kapintlagsDF_instabEvent using "${Tables}/kapintlagsDF.tex", title(\label{kapintlagsDF}) label replace compress longtable
eststo clear

*XT Logit models
*DJ
xtologit v2elturnhog `primCommInstVarsDJ' ka_open kapDJinteraction kapRRinteraction DJinteraction L(1/10).lvaw_gar L(1/10).RRrate L(1/10).ka_open L(1/10).kapDJinteraction L(1/10).kapRRinteraction L(1/10).DJinteraction, vce(cluster country)
eststo kapintlagordLogHOGDJ
*eststo mlagordLogv2elturnhog: margins, dydx(`primCommInstVars' L(1/10).lvaw_gar L(1/10).RRrate L(1/10).irregtd) post
* Be patient as the above command takes a long time to compute...
xtologit v2elturnhos `primCommInstVarsDJ' ka_open kapDJinteraction kapRRinteraction DJinteraction L(1/10).lvaw_gar L(1/10).RRrate L(1/10).ka_open L(1/10).kapDJinteraction L(1/10).kapRRinteraction L(1/10).DJinteraction, vce(cluster country)
eststo kapintlagordLogHOSDJ
*eststo mlagordLogv2elturnhos: margins, dydx(`primCommInstVars' L(1/10).lvaw_gar L(1/10).RRrate L(1/10).irregtd) post
xtologit v2eltvrig `primCommInstVarsDJ' ka_open kapDJinteraction kapRRinteraction DJinteraction L(1/10).lvaw_gar L(1/10).RRrate L(1/10).ka_open L(1/10).kapDJinteraction L(1/10).kapRRinteraction L(1/10).DJinteraction, vce(cluster country)
eststo kapintlagordLogLHDJ
*eststo mlagordLogv2eltvrig: margins, dydx(`primCommInstVars' L(1/10).lvaw_gar L(1/10).RRrate L(1/10).irregtd) post
xtlogit binstabEvent `primCommInstVarsDJ' ka_open kapDJinteraction kapRRinteraction DJinteraction L(1/10).lvaw_gar L(1/10).RRrate L(1/10).ka_open L(1/10).kapDJinteraction L(1/10).kapRRinteraction L(1/10).DJinteraction, vce(cluster country)
eststo kapintlaglogInstabDJ

esttab kapintlagordLogHOGDJ kapintlagordLogHOSDJ kapintlagordLogLHDJ kapintlaglogInstabDJ using "${Tables}/kapintlagordLogLogDJ.tex", title(\label{kapintlagordLogLogDJ}) label replace compress longtable
eststo clear

*DF
xtologit v2elturnhog `primCommInstVarsDF' ka_open kapDFinteraction kapRRinteraction DFinteraction L(1/10).irregtd L(1/10).RRrate L(1/10).ka_open L(1/10).kapDFinteraction L(1/10).kapRRinteraction L(1/10).DFinteraction, vce(cluster country)
eststo kapintlagordLogHOGDF
*eststo mlagordLogv2elturnhog: margins, dydx(`primCommInstVars' L(1/10).lvaw_gar L(1/10).RRrate L(1/10).irregtd) post
* Be patient as the above command takes a long time to compute...
xtologit v2elturnhos `primCommInstVarsDF' ka_open kapDFinteraction kapRRinteraction DFinteraction L(1/10).irregtd L(1/10).RRrate L(1/10).ka_open L(1/10).kapDFinteraction L(1/10).kapRRinteraction L(1/10).DFinteraction, vce(cluster country)
eststo kapintlagordLogHOSDF
*eststo mlagordLogv2elturnhos: margins, dydx(`primCommInstVars' L(1/10).lvaw_gar L(1/10).RRrate L(1/10).irregtd) post
xtologit v2eltvrig `primCommInstVarsDF' ka_open kapDFinteraction kapRRinteraction DFinteraction L(1/10).irregtd L(1/10).RRrate L(1/10).ka_open L(1/10).kapDFinteraction L(1/10).kapRRinteraction L(1/10).DFinteraction, vce(cluster country)
eststo kapintlagordLogLHDF
*eststo mlagordLogv2eltvrig: margins, dydx(`primCommInstVars' L(1/10).lvaw_gar L(1/10).RRrate L(1/10).irregtd) post
xtlogit binstabEvent `primCommInstVarsDF' ka_open kapDFinteraction kapRRinteraction DFinteraction L(1/10).irregtd L(1/10).RRrate L(1/10).ka_open L(1/10).kapDFinteraction L(1/10).kapRRinteraction L(1/10).DFinteraction, vce(cluster country)
eststo kapintlaglogInstabDF

esttab kapintlagordLogHOGDF kapintlagordLogHOSDF kapintlagordLogLHDF kapintlaglogInstabDF using "${Tables}/kapintlagordLogLogDF.tex", title(\label{kapintlagordLogLogDF}) label replace compress longtable
eststo clear

* IVs HOS=HOG (v2exhoshog)

* HOS = HOG
* De jure independence check
ivregress 2sls v2elturnhog (lvaw_gar RRrate = itertEd iwbaggGDP) if v2exhoshog == 1, robust
eststo hoshogfivs_v2elturnhog
ivregress 2sls v2elturnhos (lvaw_gar RRrate = itertEd iwbaggGDP) if v2exhoshog == 1, robust
eststo hoshogfivs_v2elturnhos
ivregress 2sls v2eltvrig (lvaw_gar RRrate = itertEd iwbaggGDP) if v2exhoshog == 1, robust
eststo hoshogfivs_v2eltvrig
ivregress 2sls e_wbgi_pve (lvaw_gar RRrate = itertEd iwbaggGDP) if v2exhoshog == 1, robust
eststo hoshogfivs_e_wbgi_pve
ivregress 2sls instabEvent (lvaw_gar RRrate = itertEd iwbaggGDP) if v2exhoshog == 1, robust
eststo hoshogfivs_instabEvent

esttab hoshogfivs_v2elturnhog hoshogfivs_v2elturnhos hoshogfivs_v2eltvrig hoshogfivs_e_wbgi_pve hoshogfivs_instabEvent using "${Tables}/hoshogfivs.tex", title(\label{hoshogfivs}) label replace compress booktabs wrap varwidth(40)

* De facto independence check
ivregress 2sls v2elturnhog (irregtd RRrate = itertEd iwbaggGDP) if v2exhoshog == 1, robust
eststo hoshogfivs2_v2elturnhog
ivregress 2sls v2elturnhos (irregtd RRrate = itertEd iwbaggGDP) if v2exhoshog == 1, robust
eststo hoshogfivs2_v2elturnhos
ivregress 2sls v2eltvrig (irregtd RRrate = itertEd iwbaggGDP) if v2exhoshog == 1, robust
eststo hoshogfivs2_v2eltvrig
ivregress 2sls e_wbgi_pve (irregtd RRrate = itertEd iwbaggGDP) if v2exhoshog == 1, robust
eststo hoshogfivs2_e_wbgi_pve
ivregress 2sls instabEvent (irregtd RRrate = itertEd iwbaggGDP) if v2exhoshog == 1, robust
eststo hoshogfivs2_instabEvent

esttab hoshogfivs2_v2elturnhog hoshogfivs2_v2elturnhos hoshogfivs2_v2eltvrig hoshogfivs2_e_wbgi_pve hoshogfivs2_instabEvent using "${Tables}/hoshogfivs2.tex", title(\label{hoshogfivs2}) label replace compress booktabs wrap varwidth(40)

/*
* Try the OECD instrument, with de jure cbi
ivregress 2sls v2elturnhog (lvaw_gar RRrate = ssbizagg iwbaggGDP) if v2exhoshog == 1, robust
eststo hoshogfivs3_v2elturnhog
ivregress 2sls v2elturnhos (lvaw_gar RRrate = ssbizagg iwbaggGDP) if v2exhoshog == 1, robust
eststo hoshogfivs3_v2elturnhos
ivregress 2sls v2eltvrig (lvaw_gar RRrate = ssbizagg iwbaggGDP) if v2exhoshog == 1, robust
eststo hoshogfivs3_v2eltvrig
ivregress 2sls e_wbgi_pve (lvaw_gar RRrate = ssbizagg iwbaggGDP) if v2exhoshog == 1, robust
eststo hoshogfivs3_e_wbgi_pve
ivregress 2sls instabEvent (lvaw_gar RRrate = ssbizagg iwbaggGDP) if v2exhoshog == 1, robust noconstant
eststo hoshogfivs3_instabEvent

esttab hoshogfivs3_v2elturnhog hoshogfivs3_v2elturnhos hoshogfivs3_v2eltvrig hoshogfivs3_e_wbgi_pve hoshogfivs3_instabEvent using "${Tables}/hoshogfivs3.tex", label replace compress booktabs wrap varwidth(40)
*/

* OECD instrument with de facto cbi
ivregress 2sls v2elturnhog (irregtd RRrate = ssbizagg iwbaggGDP) if v2exhoshog == 1, robust
eststo hoshogfivs4_v2elturnhog
ivregress 2sls v2elturnhos (irregtd RRrate = ssbizagg iwbaggGDP) if v2exhoshog == 1, robust
eststo hoshogfivs4_v2elturnhos
ivregress 2sls v2eltvrig (irregtd RRrate = ssbizagg iwbaggGDP) if v2exhoshog == 1, robust
eststo hoshogfivs4_v2eltvrig
ivregress 2sls e_wbgi_pve (irregtd RRrate = ssbizagg iwbaggGDP) if v2exhoshog == 1, robust
eststo hoshogfivs4_e_wbgi_pve

esttab hoshogfivs4_v2elturnhog hoshogfivs4_v2elturnhos hoshogfivs4_v2eltvrig hoshogfivs4_e_wbgi_pve using "${Tables}/hoshogfivs4.tex", title(\label{hoshogfivs4}) label replace compress booktabs wrap varwidth(40)

*HOS NOT HOG
* De jure independence check
ivregress 2sls v2elturnhog (lvaw_gar RRrate = itertEd iwbaggGDP) if v2exhoshog == 0, robust
eststo NOhoshogIfivs_v2elturnhog
ivregress 2sls v2elturnhos (lvaw_gar RRrate = itertEd iwbaggGDP) if v2exhoshog == 0, robust
eststo NOhoshogIfivs_v2elturnhos
ivregress 2sls v2eltvrig (lvaw_gar RRrate = itertEd iwbaggGDP) if v2exhoshog == 0, robust
eststo NOhoshogIfivs_v2eltvrig
ivregress 2sls e_wbgi_pve (lvaw_gar RRrate = itertEd iwbaggGDP) if v2exhoshog == 0, robust
eststo NOhoshogIfivs_e_wbgi_pve
ivregress 2sls instabEvent (lvaw_gar RRrate = itertEd iwbaggGDP) if v2exhoshog == 0, robust
eststo NOhoshogIfivs_instabEvent

esttab NOhoshogIfivs_v2elturnhog NOhoshogIfivs_v2elturnhos NOhoshogIfivs_v2eltvrig NOhoshogIfivs_e_wbgi_pve NOhoshogIfivs_instabEvent using "${Tables}/NOhoshogIfivs.tex", title(\label{NOhoshogIfivs}) label replace compress booktabs wrap varwidth(40)

* De facto independence check
ivregress 2sls v2elturnhog (irregtd RRrate = itertEd iwbaggGDP) if v2exhoshog == 0, robust
eststo NOhoshogIfivs2_v2elturnhog
ivregress 2sls v2elturnhos (irregtd RRrate = itertEd iwbaggGDP) if v2exhoshog == 0, robust
eststo NOhoshogIfivs2_v2elturnhos
ivregress 2sls v2eltvrig (irregtd RRrate = itertEd iwbaggGDP) if v2exhoshog == 0, robust
eststo NOhoshogIfivs2_v2eltvrig
ivregress 2sls e_wbgi_pve (irregtd RRrate = itertEd iwbaggGDP) if v2exhoshog == 0, robust
eststo NOhoshogIfivs2_e_wbgi_pve
ivregress 2sls instabEvent (irregtd RRrate = itertEd iwbaggGDP) if v2exhoshog == 0, robust
eststo NOhoshogIfivs2_instabEvent

esttab NOhoshogIfivs2_v2elturnhog NOhoshogIfivs2_v2elturnhos NOhoshogIfivs2_v2eltvrig NOhoshogIfivs2_e_wbgi_pve NOhoshogIfivs2_instabEvent using "${Tables}/NOhoshogIfivs2.tex", title(\label{NOhoshogIfivs2}) label replace compress booktabs wrap varwidth(40)

* Try the OECD instrument, with de jure cbi
ivregress 2sls v2elturnhog (lvaw_gar RRrate = ssbizagg iwbaggGDP) if v2exhoshog == 0, robust
eststo NOhoshogIfivs3_v2elturnhog
ivregress 2sls v2elturnhos (lvaw_gar RRrate = ssbizagg iwbaggGDP) if v2exhoshog == 0, robust
eststo NOhoshogIfivs3_v2elturnhos
ivregress 2sls v2eltvrig (lvaw_gar RRrate = ssbizagg iwbaggGDP) if v2exhoshog == 0, robust
eststo NOhoshogIfivs3_v2eltvrig
ivregress 2sls e_wbgi_pve (lvaw_gar RRrate = ssbizagg iwbaggGDP) if v2exhoshog == 0, robust
eststo NOhoshogIfivs3_e_wbgi_pve
ivregress 2sls instabEvent (lvaw_gar RRrate = ssbizagg iwbaggGDP) if v2exhoshog == 0, robust noconstant
eststo NOhoshogIfivs3_instabEvent

esttab NOhoshogIfivs3_v2elturnhog NOhoshogIfivs3_v2elturnhos NOhoshogIfivs3_v2eltvrig NOhoshogIfivs3_e_wbgi_pve NOhoshogIfivs3_instabEvent using "${Tables}/NOhoshogIfivs3.tex", title(\label{NOhoshogIfivs3}) label replace compress booktabs wrap varwidth(40)

* OECD instrument with de facto cbi
ivregress 2sls v2elturnhog (irregtd RRrate = ssbizagg iwbaggGDP) if v2exhoshog == 0, robust
eststo NOhoshogIfivs4_v2elturnhog
ivregress 2sls v2elturnhos (irregtd RRrate = ssbizagg iwbaggGDP) if v2exhoshog == 0, robust
eststo NOhoshogIfivs4_v2elturnhos
ivregress 2sls v2eltvrig (irregtd RRrate = ssbizagg iwbaggGDP) if v2exhoshog == 0, robust
eststo NOhoshogIfivs4_v2eltvrig
ivregress 2sls e_wbgi_pve (irregtd RRrate = ssbizagg iwbaggGDP) if v2exhoshog == 0, robust
eststo NOhoshogIfivs4_e_wbgi_pve

esttab NOhoshogIfivs4_v2elturnhog NOhoshogIfivs4_v2elturnhos NOhoshogIfivs4_v2eltvrig NOhoshogIfivs4_e_wbgi_pve using "${Tables}/NOhoshogIfivs4.tex", title(\label{NOhoshogIfivs4}) label replace compress booktabs wrap varwidth(40)

* IVS LHPractice
* SADLY LOWER CHAMBER LEGISLATES IN PRACTICE IS A CONTINUOUS VARIABLE- figure out interaction term and IV simultaneously? Or make it binary and split sample.

* Lags HOS=HOG

gen hoshogDJinteraction = lvaw_gar * v2exhoshog
label var hoshogDJinteraction "De Jure CBI * HOS = HOG"
gen hoshogDFinteraction = irregtd * v2exhoshog
label var hoshogDFinteraction "De Facto CBI * HOS = HOG"
gen hoshogRRinteraction = RRrate * v2exhoshog
label var hoshogRRinteraction "More Fixed Rate * HOS = HOG"

*Linear models
*DJ
foreach stabVar in `StabVars' {
    xtreg `stabVar' `primCommInstVarsDJ' v2exhoshog hoshogDJinteraction hoshogRRinteraction L(1/10).lvaw_gar L(1/10).RRrate L(1/10).v2exhoshog L(1/10).hoshogDJinteraction L(1/10).hoshogRRinteraction, fe vce(cluster country)
    eststo sglagDJ_`stabVar'
}
esttab sglagDJ_v2elturnhog sglagDJ_v2elturnhos sglagDJ_v2eltvrig sglagDJ_e_wbgi_pve sglagDJ_instabEvent using "${Tables}/hoshogintlagsDJ.tex", title(\label{hoshogintlagsDJ}) label replace compress longtable
eststo clear
*DF
foreach stabVar in `StabVars' {
    xtreg `stabVar' `primCommInstVarsDF' hoshogDFinteraction hoshogRRinteraction v2exhoshog L(1/10).irregtd L(1/10).RRrate L(1/10).v2exhoshog L(1/10).hoshogDFinteraction L(1/10).hoshogRRinteraction, fe vce(cluster country)
    eststo sglagDF_`stabVar'
}
esttab sglagDF_v2elturnhog sglagDF_v2elturnhos sglagDF_v2eltvrig sglagDF_e_wbgi_pve sglagDF_instabEvent using "${Tables}/hoshogintlagsDF.tex", title(\label{hoshogintlagsDF}) label replace compress longtable
eststo clear

*XT Logit models
*DJ
xtologit v2elturnhog `primCommInstVarsDJ' v2exhoshog hoshogDJinteraction hoshogRRinteraction L(1/10).lvaw_gar L(1/10).RRrate L(1/10).v2exhoshog L(1/10).hoshogDJinteraction L(1/10).hoshogRRinteraction, vce(cluster country)
eststo sglagordLogHOGDJ
*eststo mlagordLogv2elturnhog: margins, dydx(`primCommInstVars' L(1/10).lvaw_gar L(1/10).RRrate L(1/10).irregtd) post
* Be patient as the above command takes a long time to compute...
xtologit v2elturnhos `primCommInstVarsDJ' v2exhoshog hoshogDJinteraction hoshogRRinteraction L(1/10).lvaw_gar L(1/10).RRrate L(1/10).v2exhoshog L(1/10).hoshogDJinteraction L(1/10).hoshogRRinteraction, vce(cluster country)
eststo sglagordLogHOSDJ
*eststo mlagordLogv2elturnhos: margins, dydx(`primCommInstVars' L(1/10).lvaw_gar L(1/10).RRrate L(1/10).irregtd) post
xtologit v2eltvrig `primCommInstVarsDJ' v2exhoshog hoshogDJinteraction hoshogRRinteraction L(1/10).lvaw_gar L(1/10).RRrate L(1/10).v2exhoshog L(1/10).hoshogDJinteraction L(1/10).hoshogRRinteraction, vce(cluster country)
eststo sglagordLogLHDJ
*eststo mlagordLogv2eltvrig: margins, dydx(`primCommInstVars' L(1/10).lvaw_gar L(1/10).RRrate L(1/10).irregtd) post
xtlogit binstabEvent `primCommInstVarsDJ' v2exhoshog hoshogDJinteraction hoshogRRinteraction L(1/10).lvaw_gar L(1/10).RRrate L(1/10).v2exhoshog L(1/10).hoshogDJinteraction L(1/10).hoshogRRinteraction, vce(cluster country)
eststo sglaglogInstabDJ

esttab sglagordLogHOGDJ sglagordLogHOSDJ sglagordLogLHDJ sglaglogInstabDJ using "${Tables}/hoshogintlagordLogLogDJ.tex", title(\label{hoshogintlagordLogLogDJ}) label replace compress longtable
eststo clear

*DF
xtologit v2elturnhog `primCommInstVarsDF' v2exhoshog hoshogDFinteraction hoshogRRinteraction L(1/10).irregtd L(1/10).RRrate L(1/10).v2exhoshog L(1/10).hoshogDFinteraction L(1/10).hoshogRRinteraction, vce(cluster country)
eststo sglagordLogHOGDF
*eststo mlagordLogv2elturnhog: margins, dydx(`primCommInstVars' L(1/10).lvaw_gar L(1/10).RRrate L(1/10).irregtd) post
* Be patient as the above command takes a long time to compute...
xtologit v2elturnhos `primCommInstVarsDF' v2exhoshog hoshogDFinteraction hoshogRRinteraction L(1/10).irregtd L(1/10).RRrate L(1/10).v2exhoshog L(1/10).hoshogDFinteraction L(1/10).hoshogRRinteraction, vce(cluster country)
eststo sglagordLogHOSDF
*eststo mlagordLogv2elturnhos: margins, dydx(`primCommInstVars' L(1/10).lvaw_gar L(1/10).RRrate L(1/10).irregtd) post
xtologit v2eltvrig `primCommInstVarsDF' v2exhoshog hoshogDFinteraction hoshogRRinteraction L(1/10).irregtd L(1/10).RRrate L(1/10).v2exhoshog L(1/10).hoshogDFinteraction L(1/10).hoshogRRinteraction, vce(cluster country)
eststo sglagordLogLHDF
*eststo mlagordLogv2eltvrig: margins, dydx(`primCommInstVars' L(1/10).lvaw_gar L(1/10).RRrate L(1/10).irregtd) post
xtlogit binstabEvent `primCommInstVarsDF' v2exhoshog hoshogDFinteraction hoshogRRinteraction L(1/10).irregtd L(1/10).RRrate L(1/10).v2exhoshog L(1/10).hoshogDFinteraction L(1/10).hoshogRRinteraction, vce(cluster country)
eststo sglaglogInstabDF

esttab sglagordLogHOGDF sglagordLogHOSDF sglagordLogLHDF sglaglogInstabDF using "${Tables}/hoshogintlagordLogLogDF.tex", title(\label{hoshogintlagordLogLogDF}) label replace compress longtable
eststo clear

* Lags LHPractice (v2lglegplo)

gen llpDJinteraction = lvaw_gar * v2lglegplo
label var llpDJinteraction "De Jure CBI * Lower House Legislates in Practice"
gen llpDFinteraction = irregtd * v2lglegplo
label var llpDFinteraction "De Facto CBI * Lower House Legislates in Practice"
gen llpRRinteraction = RRrate * v2lglegplo
label var llpRRinteraction "More Fixed Rate * Lower House Legislates in Practice"

*Linear models
*DJ
foreach stabVar in `StabVars' {
    xtreg `stabVar' `primCommInstVarsDJ' v2lglegplo llpDJinteraction llpRRinteraction L(1/10).lvaw_gar L(1/10).RRrate L(1/10).v2lglegplo L(1/10).llpDJinteraction L(1/10).llpRRinteraction, fe vce(cluster country)
    eststo llpintlagsDJ_`stabVar'
}
esttab llpintlagsDJ_v2elturnhog llpintlagsDJ_v2elturnhos llpintlagsDJ_v2eltvrig llpintlagsDJ_e_wbgi_pve llpintlagsDJ_instabEvent using "${Tables}/llpintlagsDJ.tex", title(\label{llpintlagsDJ}) label replace compress longtable
eststo clear
*DF
foreach stabVar in `StabVars' {
xtreg `stabVar' `primCommInstVarsDF' llpDFinteraction llpRRinteraction v2lglegplo L(1/10).irregtd L(1/10).RRrate L(1/10).v2lglegplo L(1/10).llpDFinteraction L(1/10).llpRRinteraction, fe vce(cluster country)
eststo llpintlagsDF_`stabVar'
}
esttab llpintlagsDF_v2elturnhog llpintlagsDF_v2elturnhos llpintlagsDF_v2eltvrig llpintlagsDF_e_wbgi_pve llpintlagsDF_instabEvent using "${Tables}/llpintlagsDF.tex", title(\label{llpintlagsDF}) label replace compress longtable
eststo clear

*XT Logit models
*DJ
xtologit v2elturnhog `primCommInstVarsDJ' v2lglegplo llpDJinteraction llpRRinteraction L(1/10).lvaw_gar L(1/10).RRrate L(1/10).v2lglegplo L(1/10).llpDJinteraction L(1/10).llpRRinteraction, vce(cluster country)
eststo llpintlagordLogHOGDJ
*eststo mlagordLogv2elturnhog: margins, dydx(`primCommInstVars' L(1/10).lvaw_gar L(1/10).RRrate L(1/10).irregtd) post
* Be patient as the above command takes a long time to compute...
xtologit v2elturnhos `primCommInstVarsDJ' v2lglegplo llpDJinteraction llpRRinteraction L(1/10).lvaw_gar L(1/10).RRrate L(1/10).v2lglegplo L(1/10).llpDJinteraction L(1/10).llpRRinteraction, vce(cluster country)
eststo llpintlagordLogHOSDJ
*eststo mlagordLogv2elturnhos: margins, dydx(`primCommInstVars' L(1/10).lvaw_gar L(1/10).RRrate L(1/10).irregtd) post
xtologit v2eltvrig `primCommInstVarsDJ' v2lglegplo llpDJinteraction llpRRinteraction L(1/10).lvaw_gar L(1/10).RRrate L(1/10).v2lglegplo L(1/10).llpDJinteraction L(1/10).llpRRinteraction, vce(cluster country)
eststo llpintlagordLogLHDJ
*eststo mlagordLogv2eltvrig: margins, dydx(`primCommInstVars' L(1/10).lvaw_gar L(1/10).RRrate L(1/10).irregtd) post
xtlogit binstabEvent `primCommInstVarsDJ' v2lglegplo llpDJinteraction llpRRinteraction L(1/10).lvaw_gar L(1/10).RRrate L(1/10).v2lglegplo L(1/10).llpDJinteraction L(1/10).llpRRinteraction, vce(cluster country)
eststo llpintlaglogInstabDJ

esttab llpintlagordLogHOGDJ llpintlagordLogHOSDJ llpintlagordLogLHDJ llpintlaglogInstabDJ using "${Tables}/llpintlagordLogDJ.tex", title(\label{llpintlagordLogDJ}) label replace compress longtable
eststo clear

*DF
xtologit v2elturnhog `primCommInstVarsDF' v2lglegplo llpDFinteraction llpRRinteraction L(1/10).irregtd L(1/10).RRrate L(1/10).v2lglegplo L(1/10).llpDFinteraction L(1/10).llpRRinteraction, vce(cluster country)
eststo llpintlagordLogHOGDF
*eststo mlagordLogv2elturnhog: margins, dydx(`primCommInstVars' L(1/10).lvaw_gar L(1/10).RRrate L(1/10).irregtd) post
* Be patient as the above command takes a long time to compute...
xtologit v2elturnhos `primCommInstVarsDF' v2lglegplo llpDFinteraction llpRRinteraction L(1/10).irregtd L(1/10).RRrate L(1/10).v2lglegplo L(1/10).llpDFinteraction L(1/10).llpRRinteraction, vce(cluster country)
eststo llpintlagordLogHOSDF
*eststo mlagordLogv2elturnhos: margins, dydx(`primCommInstVars' L(1/10).lvaw_gar L(1/10).RRrate L(1/10).irregtd) post
xtologit v2eltvrig `primCommInstVarsDF' v2lglegplo llpDFinteraction llpRRinteraction L(1/10).irregtd L(1/10).RRrate L(1/10).v2lglegplo L(1/10).llpDFinteraction L(1/10).llpRRinteraction, vce(cluster country)
eststo llpintlagordLogLHDF
*eststo mlagordLogv2eltvrig: margins, dydx(`primCommInstVars' L(1/10).lvaw_gar L(1/10).RRrate L(1/10).irregtd) post
xtlogit binstabEvent `primCommInstVarsDF' v2lglegplo llpDFinteraction llpRRinteraction L(1/10).irregtd L(1/10).RRrate L(1/10).v2lglegplo L(1/10).llpDFinteraction L(1/10).llpRRinteraction, vce(cluster country)
eststo llpintlaglogInstabDF

esttab llpintlagordLogHOGDF llpintlagordLogHOSDF llpintlagordLogLHDF llpintlaglogInstabDF using "${Tables}/llpintlagordLogDF.tex", title(\label{llpintlagordLogDF}) label replace compress longtable
eststo clear

save "${Intermediate_Data}/CR_Adequate", replace
