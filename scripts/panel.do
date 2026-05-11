clear all
set more off
set type double

capture ssc install coefplot

global myfolder "C:\Users\maxim\Desktop\Projet_Panel"
cd "$myfolder"

local files "pib.csv gdp_val  revenu.csv revenu_val  fbcf.csv invest_val  emploi.csv emp_val  esperance.csv esp_vie  densite.csv dens_val  educ.csv human_cap"

forvalues i = 1(2)14 {
    gettoken file files : files
    gettoken varname files : files

    import delimited "data/raw/`file'", clear case(preserve)

    capture confirm variable OBS_VALUE

    keep geo TIME_PERIOD OBS_VALUE
    rename TIME_PERIOD year
    rename OBS_VALUE `varname'

    replace geo = strtrim(geo)

    capture destring `varname', replace force ignore(": b u p d z c e n s r")

    sort geo year
    save "data/processed/temp_`varname'.dta", replace
}

use "data/processed/temp_human_cap.dta", clear
keep if year >= 2015 & year <= 2023
collapse (mean) human_cap, by(geo year)
save "data/processed/temp_human_cap_clean.dta", replace

use "data/processed/temp_gdp_val.dta", clear
keep if year >= 2015 & year <= 2023

local vars "revenu_val invest_val emp_val esp_vie dens_val"
foreach v of local vars {
    merge 1:1 geo year using "data/processed/temp_`v'.dta", nogenerate keep(match master)
}
merge 1:1 geo year using "data/processed/temp_human_cap_clean.dta", nogenerate keep(match master)

replace geo = strtrim(geo)

drop if geo == "Union européenne - 27 pays (à partir de 2020)"
drop if geo == "Norvège"
drop if geo == "Serbie"
drop if geo == "Turquie"

gen LPtb = ln(gdp_val)
gen LCon = ln(revenu_val)
gen LIvt = invest_val
gen Emp  = emp_val
gen Den  = dens_val
gen Idh  = esp_vie
gen Dip  = human_cap

egen miss_check = rowmiss(LPtb LCon LIvt Emp Den Idh Dip)
drop if miss_check > 0
drop miss_check

label variable LPtb "Log PIB par habitant (Var Dep)"
label variable LCon "Log Revenu Disponible (Conso)"
label variable LIvt "Taux d'Investissement (% du PIB)"
label variable Emp  "Taux d'Emploi (% Population Active)"
label variable Den  "Densité de population (Hab/km2)"
label variable Idh  "Espérance de Vie (Années)"
label variable Dip  "Capital Humain (% Diplômés Supérieur)"

encode geo, gen(country_id)
xtset country_id year

save "data/processed/EDP_Group_Final_2025.dta", replace

xtdescribe

xtsum LPtb LCon LIvt Emp Den Idh Dip

pwcorr LPtb LCon LIvt Emp Den Idh Dip, star(0.05)

reg LPtb LCon LIvt Emp Den Idh Dip
estimates store POLS

xtreg LPtb LCon LIvt Emp Den Idh Dip, be
estimates store BE

xtreg LPtb LCon LIvt Emp Den Idh Dip, fe
estimates store FE

xtreg LPtb LCon LIvt Emp Den Idh Dip, re
estimates store RE

reg D.LPtb D.LCon D.LIvt D.Emp D.Den D.Idh D.Dip, noconstant
estimates store FD

estimates table POLS BE FE RE FD, star stats(N r2) b(%9.3f)

hausman FE RE

twoway (scatter LPtb LCon, mcolor(navy%40) msize(small)) ///
       (lfit LPtb LCon, lcolor(red) lwidth(thick)), ///
       title("Moteur de la Croissance (2015-2023)") ///
       subtitle("Corrélation PIB - Consommation") ///
       ytitle("Log PIB par habitant") ///
       xtitle("Log Revenu/Consommation") ///
       scheme(s1mono) name(g1, replace)
graph export "output/figures/Graph1_Scatter_Conso.png", replace

preserve
    collapse (mean) LPtb, by(year)
    twoway (line LPtb year, lcolor(black) lwidth(thick)) ///
           (scatter LPtb year, mcolor(red)), ///
           title("Le Choc Exogène de 2020") ///
           subtitle("Évolution du PIB moyen (Log)") ///
           xline(2020, lpattern(dash) lcolor(gs10)) ///
           text(10.25 2020.5 "Covid-19", place(e) color(red)) ///
           ytitle("Niveau de Richesse Moyen") xtitle("") ///
           scheme(s1mono) name(g2, replace)
    graph export "output/figures/Graph2_Trend_Covid.png", replace
restore

quietly xtreg LPtb LCon LIvt Emp Den Idh Dip, fe
capture drop PIB_Predit
predict PIB_Predit, xbu

twoway (scatter LPtb PIB_Predit, mcolor(blue%30) msize(small)) ///
       (function y = x, range(9 11.5) lcolor(black) lpattern(dash)), ///
       title("Qualité du Modèle à Effets Fixes") ///
       subtitle("Comparaison Réalité vs Modèle") ///
       ytitle("PIB Observé (Réalité)") ///
       xtitle("PIB Prédit par le Modèle") ///
       legend(order(1 "Pays-Année" 2 "Prédiction Parfaite")) ///
       scheme(s1mono) name(g3, replace)
graph export "output/figures/Graph3_Model_Fit.png", replace

graph box LPtb, over(year) ///
    title("Disparités de Richesse en Europe") ///
    subtitle("Distribution du PIB par habitant") ///
    ytitle("Log PIB par habitant") ///
    note("La hauteur des boîtes montre les inégalités entre pays") ///
    scheme(s1mono) name(g4, replace)
graph export "output/figures/Graph4_Heterogeneity.png", replace

gen covid_dummy = 0
replace covid_dummy = 1 if year == 2020 | year == 2021
label variable covid_dummy "Période Covid (2020-2021)"

xtreg LPtb LCon LIvt Emp Den Idh Dip covid_dummy, fe vce(cluster country_id)
estimates store FE_Covid

xtreg LPtb LCon LIvt Emp Den Idh Dip i.year, fe vce(cluster country_id)
estimates store FE_Time

estimates table FE FE_Covid FE_Time, star stats(N r2_w) b(%9.4f) drop(i.year)

quietly xtreg LPtb LCon LIvt Emp Den Idh Dip i.year, fe vce(cluster country_id)

coefplot, keep(*.year) vertical ///
    yline(0, lcolor(black)) ///
    rename(*.year = "") ///
    title("L'Impact des Crises (Effets Temporels)") ///
    subtitle("Chocs annuels nets sur le PIB (par rapport à 2015)") ///
    ytitle("Impact sur le Log PIB") ///
    xlabel(, angle(45)) ///
    groups(*.year = "{bf:Chocs Exogènes}", gap(1)) ///
    scheme(s1mono) name(g5_time, replace)

graph export "output/figures/Graph5_Time_Effects.png", replace

preserve
    bysort country_id: egen mean_education = mean(Dip)
    xtile educ_group = mean_education, nq(4)

    keep if educ_group == 1 | educ_group == 4
    collapse (mean) LPtb, by(year educ_group)

    twoway (line LPtb year if educ_group==4, lcolor(forest_green) lwidth(thick)) ///
           (line LPtb year if educ_group==1, lcolor(maroon) lwidth(thick)), ///
           title("La Fracture Éducative") ///
           subtitle("Richesse des pays : Haut vs Faible Capital Humain") ///
           ytitle("Niveau de Richesse (Log PIB)") ///
           xtitle("") ///
           legend(order(1 "Top 25% (Forte Éducation)" 2 "Bottom 25% (Faible Éducation)") position(6) rows(1)) ///
           scheme(s1mono) name(g6_best_worst, replace)

    graph export "output/figures/Graph6_Education_Gap.png", replace
restore
