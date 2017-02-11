*Creates excel data and map of change in youth 0-5 for National Journal

cd "\\Stata2\PopulationProjections\2014\forWebTool\states\National_Journal\Map"
insheet using AFert_AMort_AMig.csv, clear

/* we want just children 0-4, so we only keep if agegrp=1, because of below coding:

gen agegrp =1 if age>=0 & age <5
replace agegrp=2 if age>=5 & age <99
replace agegrp=0 if age==99

*/

keep if agegrp==1 & yr!=0

gen year="2010" if yr==10
replace year="2020" if yr==20
replace year="2030" if yr==30

drop agegrp yr

/*create a new population race variable, so we can have a long */

reshape wide pop, i(r stfips) j(year) string

order stfips r 

g perchange_10_20=(( pop2020- pop2010)/ pop2010)*100
g perchange_20_30=(( pop2030- pop2020)/ pop2020)*100
	replace perchange_20_30=0 if pop2020==0 & pop2030==0
g perchange_10_30=(( pop2030- pop2010)/ pop2010)*100

sort stfips
merge m:1 stfips using "\\Stata2\PopulationProjections\2014\geographic files\stlabel.dta"
	drop if stfips==72
			** this is PR
	drop _merge

order st stfips r pop2010 pop2020 pop2030 perchange_10_20 perchange_20_30 perchange_10_30
	
		
save "\\Stata2\PopulationProjections\2014\forWebTool\states\National_Journal\youth_change.dta", replace

export excel "\\Stata2\PopulationProjections\2014\forWebTool\states\National_Journal\youth_change", cell(A1) sheet(Sheet1) sheetreplace firstrow(varlabels) nolabel

keep if r=="T"

export excel "\\Stata2\PopulationProjections\2014\forWebTool\states\National_Journal\youth_change_formap", cell(A1) sheet(Sheet1) sheetreplace firstrow(varlabels) nolabel
