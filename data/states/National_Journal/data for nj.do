*Pulls from the 'create state data for map' file, which was updated to match new file structure. 
*Outputs both map data and excel to give National Journal.

clear
set more off
cd "\\Stata2\PopulationProjections\2014"

********Append all commuting zone level data from all of the projections
local index=1
foreach s in lo mid hi{
	foreach f in lo mid hi{
	clear
			*Start with high migration
			u 0929/cz_`s'surv`f'fert_10migr 
			gen mig = "H"
			*Low migration
			append using 0930/cz_`s'surv`f'fert_10migr
			replace mig = "L" if mig != "H"
			*Average migration
			append using 0906/cz_`s'surv`f'fert_10migr 
			replace mig = "A" if mig != "H" & mig !="L"
			if `index'==1 {
				saveold temp, replace
				}
			else if `index'>1 {
				append using temp
				saveold temp, replace
				}
			loc index=`index'+1
			}
		}


drop if year==2040

*Create Shorter Named Model Variables
*mig, fert, mort will be used for the map
drop migration

gen fert = "H" if fertility==1
replace fert="A" if fertility==0
replace fert="L" if fertility==-1

gen mort = "H" if mortality==1
replace mort="A" if mortality==0
replace mort="L" if mortality==-1

drop mortality fertility
*Create Longer Variables for Download
gen migration="High" if mig == "H"
replace migration="Average" if mig == "A"
replace migration="Low" if mig == "L"

gen fertility="High" if fert == "H"
replace fertility="Average" if fert == "A"
replace fertility="Low" if fert == "L"

gen mortality="High" if mort == "H"
replace mortality="Average" if mort == "A"
replace mortality="Low" if mort == "L"

*Drop economic growth
drop ecgrowth

saveold temp_nj, replace


*Collapse state level 
collapse (sum) pop*, by(migration fertility mortality mig fert mort year age stfips) fast
sort stfips
merge m:1 stfips using stlabel


*Create totals
gen popttm = popwnm + popbnm + popthm + poponm
gen popttf = popwnf + popbnf + popthf + poponf


gen popT = (popttm + popttf)
gen popW = (popwnm + popwnf)
gen popB = (popbnm + popbnf)
gen popH = (popthm + popthf)
gen popO = (poponm + poponf)

drop _m popttf popwnf popbnf popthf poponf popttm popwnm popbnm popthm poponm


sort fertility mortality migration year age stfips st

*Turn Race into a column
reshape long pop, i(fertility mortality migration year age stfips st) j(r) string

generate race_eth = "White, NH" if r == "W"
replace race_eth = "Black, NH" if r== "B"
replace race_eth = "Hispanic" if r== "H"
replace race_eth = "Some Other Race, NH" if r== "O"
replace race_eth = "All" if r== "T"

generate r_order = 1 if r == "W"
replace r_order = 2 if r== "B"
replace r_order  = 3 if r== "H"
replace r_order  = 4 if r== "O"
replace r_order  = 5 if r== "T"

*Drop PR
drop if stfips==72

*Created in CZ file
append using all_US
replace stfips =0 if cz==0
replace st ="US" if cz==0
drop cz*


*Create All Ages
preserve
collapse (sum) pop*, by(mig fert mort migration fertility mortality year r race_eth r_order stfips st) fast
gen age = 99
save all_ages_st, replace
restore

append using all_ages_st

*Create Age groups
gen agegrp =1 if age>=0 & age <5
replace agegrp=2 if age>=5 & age <99
replace agegrp=0 if age==99

*Create Short Year
gen yr="00" if year==2000
replace yr ="10" if year==2010
replace yr ="20" if year==2020
replace yr="30" if year==2030

egen group=group(stfips)


save njstatedata_05082015, replace


*********Create data for download
*All US
sort fertility mortality migration year age r_order stfips st
order fertility mortality migration year age race_eth stfips st pop
preserve
	gen rpop=round(pop)
	drop pop 
	rename rpop pop
	format pop %12.0f
outsheet fertility mortality migration year age race_eth stfips st pop using forWebTool/states/National_Journal/Download/AllST_AllFert_AllMort_AllMig.csv, comma replace
restore


*For each commuting zone
foreach i of num 1/52 {
	preserve
	keep if group==`i'
	local state = stfips 
	gen rpop=round(pop)
	drop pop 
	rename rpop pop
	format pop %12.0f
	outsheet fertility mortality migration year age race_eth stfips st pop if group==`i' using forWebTool/states/National_Journal/Download/`state'_AllFert_AllMort_AllMig.csv, comma replace
	restore
	}
	
********

*******Create data for charts
*One file for each CZ for each set of scenarios
set more off
foreach i of num 1/52{
	preserve
	foreach fert in H A L {
		foreach mort in H A L {
			foreach mig in H A L{	
				keep if group==`i'
				local state = stfips 
				gen rpop=round(pop)
				drop pop 
				rename rpop pop
				format pop %12.0f
				outsheet yr age r stfips pop if fert=="`fert'" & mort=="`mort'" & mig =="`mig'" using forWebTool/states/National_Journal/Charts/`state'_`fert'Fert_`mort'Mort_`mig'Mig.csv, comma replace
			}
		}
	}
	restore
}
*******
	
*******Create data for map and download data for map
*One file for each set of scenarios

*drop all US
drop if stfips==0

*collapse for age groups
collapse (sum) pop*, by(yr year agegrp r race_eth stfips st fert mort mig) 

foreach f in H A L {
	foreach m in H A L {
		foreach g in H A L{	
			gen rpop=round(pop)
			drop pop 
			rename rpop pop
			format pop %12.0f
			outsheet yr agegrp r stfips pop if fert=="`f'" & mort=="`m'" & mig =="`g'" using forWebTool/states/National_Journal/Map/`f'Fert_`m'Mort_`g'Mig.csv, comma replace
			outsheet year agegrp race_eth stfips st pop if fert=="`f'" & mort=="`m'" & mig =="`g'" using forWebTool/states/National_Journal/Download/AllCZ_`f'Fert_`m'Mort_`g'Mig.csv, comma replace
		}
	}
}




