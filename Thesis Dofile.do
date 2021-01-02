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
use country_name year v2elturnhog v2elturnhos v2eltvrexo v2eltvrig v3eltvriguc e_coups e_wbgi_pve e_mipopula v2petersch e_migdppc e_civil_war e_miinterc e_pt_coup v2elreggov v2x_horacc using V-Dem-CY-Full+Others-v10, clear

// Variables are, respectively, country, year, head of government turnover event, head of state turnover event, executive turnover, lower chamber turnover, upper chamber turnover, coups (PIPE), WGI political stability, total population, tertiary school enrollment, GDP per capita, civil war, internal armed conflict, coups d'etat, existance of regional governments, horizontal accountability (checks and balances).

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

// Create aggregate GDP from per capita values and population
gen aggGDP = e_mipopula*e_migdppc

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

// Create an instability event variable for an attempted coup, civil war, or internal conflict.
gen instabEvent = (e_civil_war | e_miinterc | (e_coups != 0) | (e_pt_coup != 0)) if (e_civil_war != . | e_miinterc != .) & (e_coups != . | e_pt_coup != .)

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

* WB Indicators (not needed)
// WB gross tert enrollment
// WB agg gdp in ppp
// WB pop
* wbopendata indicator(SP.POP.TOTL NY.GDP.MKTP.PP.KD SE.TER.ENRR) year(2012:2017), clear
* save Clean_Thesis_WB, replace

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

// Merging datasets
// Preliminary analysis/essentials round
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
merge 1:1 country_name year using Clean_OECD_Thesis

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
ren timeinoffice tinoff
ren legalduration legdur
ren lvau_garriga lvau_gar
ren lvaw_garriga lvaw_gar
ren rate_regime RRrate
// Dep Variables
local ElStabVars "v2elturnhog v2elturnhos v2eltvrig"
local PolStabVars "e_wbgi_pve instabEvent"
local StabVars "`ElStabVars' `PolStabVars'"

// Create and test binary stab variables and output with xtlogit
*Code for redeployment:
*xtlogit `stabVar' `commVar', fe
*eststo logFE_`stabVar'`commVar'
*logFE_`stabVar'`commVar'

// Indep Variables
local dejureCBIVars "lvau_gar lvaw_gar"
local defactoCBIVars "regtd irregtd tinoff"
* Need to make a choice here on what de facto CBI vars are actually worth it. For now, stick with regular turnover and irregular turnover.
local CBIVars "`dejureCBIVars' `defactoCBIVars'"
local RateVars "RRrate"
local CommInstVars "`CBIVars' `RateVars'"

// Baseline tests- full sample, all variables
foreach stabVar in `StabVars' {
foreach commVar in `CommInstVars' {
reg `stabVar' `commVar', robust
eststo ols_`stabVar'`commVar'
xtreg `stabVar' `commVar', fe cluster(country)
eststo FE_`stabVar'`commVar'
esttab ols_`stabVar'`commVar' FE_`stabVar'`commVar' using "`stabVar'`commVar'.rtf", replace
}
}

eststo clear

// All independent variables in the same regressions
foreach stabVar in `StabVars' {
reg `stabVar' `CommInstVars', robust
eststo miols_`stabVar'
xtreg `stabVar' `CommInstVars', fe cluster(country)
eststo miFE_`stabVar'
}
esttab miols_

// Separate samples, in line with the theory

// High Constraints and highly Competitive- Democracy
// De jure independent CB and fixed rate, electoral instability
foreach stabVar in `ElStabVars' {
foreach commVar in `dejureCBIVars' `RateVars' {
reg `stabVar' `commVar' if hxconst4 & hcomp3, robust
eststo hhols_`stabVar'`commVar'
xtreg `stabVar' `commVar' if hxconst4 & hcomp3, fe cluster(country)
eststo hhFE_`stabVar'`commVar'
esttab hhols_`stabVar'`commVar' hhFE_`stabVar'`commVar' using "hh`stabVar'`commVar'.rtf", replace
}
}

eststo clear

// Low Constraints and high Comp
// De facto independent CB and fixed rate, electoral instability
foreach stabVar in `ElStabVars' {
foreach commVar in `defactoCBIVars' `RateVars' {
reg `stabVar' `commVar' if !hxconst4 & hcomp3, robust 
eststo lhols_`stabVar'`commVar'
xtreg `stabVar' `commVar' if !hxconst4 & hcomp3, fe cluster(country)
eststo lhFE_`stabVar'`commVar'
esttab lhols_`stabVar'`commVar' lhFE_`stabVar'`commVar' using "lh`stabVar'`commVar'.rtf", replace
}
}

eststo clear

// High Constraints and not Comp
// De jure independent CB and fixed rate, political instability
foreach stabVar in `PolStabVars' {
foreach commVar in `dejureCBIVars' `RateVars' {
reg `stabVar' `commVar' if hxconst4 & !hcomp3, robust
eststo hlols_`stabVar'`commVar'
xtreg `stabVar' `commVar' if hxconst4 & !hcomp3, fe cluster(country) 
eststo hlFE_`stabVar'`commVar'
esttab hlols_`stabVar'`commVar' hlFE_`stabVar'`commVar' using "hl`stabVar'`commVar'.rtf", replace
}
}

eststo clear

// Low Constraints and not Comp
// De facto independent CB and fixed rate, political instability
foreach stabVar in `PolStabVars' {
foreach commVar in `defactoCBIVars' `RateVars' {
reg `stabVar' `commVar' if hxconst4 & !hcomp3, robust
eststo llols_`stabVar'`commVar'
xtreg `stabVar' `commVar' if hxconst4 & !hcomp3, fe cluster(country)
eststo llFE_`stabVar'`commVar'
esttab llols_`stabVar'`commVar' llFE_`stabVar'`commVar' using "ll`stabVar'`commVar'.rtf", replace
}
}

eststo clear

// Full sample with interaction terms?

// Check interrelation of CBI and Fixed Rates- complement/subsitutute?
reg lvau_gar RRrate
reg lvaw_gar RRrate
reg irregtd RRrate
* try de facto cbi too

* Extra code for below once binary dep vars are in order
*xtlogit `stabVar' `commVar', fe
*eststo blF_`stabVar'`commVar'
*blF_`stabVar'`commVar' 

// Binary independence (de jure) and fixed rates
local binDeJureCBI "uHighCBI wHighCBI"
gen committedU = (!float_rate & uHighCBI) if float_rate != . & uHighCBI != .
gen committedW = (!float_rate & wHighCBI) if float_rate != . & wHighCBI != .
foreach stabVar in `StabVars' {
foreach commVar in `binDeJureCBI' float_rate {
reg `stabVar' `commVar', robust
eststo bols_`stabVar'`commVar'
xtreg `stabVar' `commVar', fe cluster(country)
eststo bFE_`stabVar'`commVar'
esttab bols_`stabVar'`commVar' bFE_`stabVar'`commVar' using "b`stabVar'`commVar'.rtf", replace
}
}

eststo clear

// Throw in controls
merge 1:1 country_name year using Clean_DPI, gen(merge5)
merge 1:1 country_name year using Clean_Visser, gen(merge6)

local noCorpControls "v2elreggov v2x_horacc checks auton author"
local fullcontrols "`noCorpControls' Coord Type"

local StabVarsnoWBPV "`ElStabVars' instabEvent"
* Exclude world bank violence indicator due to insufficient observations.

*Once binaries are in order
*xtlogit `stabVar' `commVar' `fullcontrols', fe
*eststo clogFE_`stabVar'`commVar'
*clogFE_`stabVar'`commVar' 

foreach stabVar in `StabVarsnoWBPV' {
foreach commVar in `CommInstVars' {
reg `stabVar' `commVar' `fullcontrols', robust
eststo cols_`stabVar'`commVar'
xtreg `stabVar' `commVar' `fullcontrols', fe cluster(country)
eststo cFE_`stabVar'`commVar'
esttab cols_`stabVar'`commVar' cFE_`stabVar'`commVar' using "c`stabVar'`commVar'.rtf", replace
}
}

*For below once binary deps in order
*xtlogit `stabVar' `commVar' `noCorpControls', fe
*eststo nclogFE_`stabVar'`commVar'
*nclogFE_`stabVar'`commVar'

*exclude corporatism since it's missing for a ton of observations
foreach stabVar in `StabVarsnoWBPV' {
foreach commVar in `CommInstVars' {
reg `stabVar' `commVar' `noCorpControls', robust
eststo ncols_`stabVar'`commVar'
xtreg `stabVar' `commVar' `noCorpControls', fe cluster(country)
eststo nccFE_`stabVar'`commVar'
esttab ncols_`stabVar'`commVar' nccFE_`stabVar'`commVar' using "ncc`stabVar'`commVar'.rtf", replace
}
}

eststo clear

// Arellano Bond etc.

// Hazard Model?- requires a bit of coding...

// Instrument for CBI of Tert Ed- 
foreach stabVar in `StabVars' {
foreach commVar in `CBIVars' {
ivregress 2sls `stabVar' (`commVar' = v2petersch), robust first
eststo ivter_`stabVar'`commVar'
esttab ivter_`stabVar'`commVar' using "ivter`stabVar'`commVar'.rtf", replace
}
}

// Instrument for CBI of Social Science and Biz Grads
// Create appropriate variable described in text of ssbiz share times tertiary completion rate
*replace v2petersch = v2petersch/100
*gen ssbizagg = v2petersch*ssbizsh

* Not really enough observations for ssbizagg?
*foreach stabVar in `StabVars' {
*foreach cbiVar in `CBIVars' {
*ivregress 2sls `stabVar' (`cbiVar' = ssbizagg), robust first
*eststo ivssb_`stabVar'`cbiVar'
*}
*}
* Breaks when reaching regtd for some reason??????

// Instrument for Fixed Rates of Econ Size (GDP)
foreach stabVar in `StabVars' {
foreach rateVar in `RateVars' {
ivregress 2sls `stabVar' (`rateVar' = aggGDP), robust first
eststo ivgdp_`stabVar'`rateVar'
esttab ivgdp_`stabVar'`rateVar' using "ivgdp`stabVar'`commVar'.rtf", replace
}
}

eststo clear