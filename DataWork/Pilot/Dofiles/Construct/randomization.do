*===============================================================================
*===============================================================================
*																			   *
*			    	NEW IBNET GLOBAL UTILITY SURVEY PILOT		 	  		   *
*			    	Interview Randomization									   *
*																			   *
*																			   *
*===============================================================================
*===============================================================================
/*
	PURPOSE: The purpose of this .do file is to randomize 100 water utilities in the New
	IBNET Global Utility Survey Pilot to the enumerator-led management interview
	in addition to the self-administered questionnaire. There will also be a 
	backup group of water utilities that will also be randomized in the event of
	non-response or inadequate response by the primary set of utilities. 
*/		
	
	
**#: RANDOMLY ASSIGN THE 142 PRIORITY UTILITIES
*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	* import list of the utilities
		import excel "$pilot_data_rand/utilities_list.xlsx", sheet("wave1") firstrow allstring case(lower) clear
	
	* set seed for replication
		set seed 457589
	
	* generate a unique_id 
		gen unique_id = _n 
	
	* sort data set 
		sort unique_id 
	
	* save out the list of utilities with the unique ids 
		export excel using "$pilot_data_rand/utilities_list_uniqueIDs_1.xlsx", replace firstrow(variables)
	
	* generate a numeric country category variable called developed (for stratification)
		gen 	developed = 1 if category == "Developed"
		replace developed = 0 if category == "Developing-Emerging"
	
	* generate a numeric country id (for stratification) 
		egen country_id = group(country)
	
	* generate a numeric wbregion id (for stratification later)
		gen 	wbregion_id = 1 if wbregion == "Africa"
		replace wbregion_id = 2 if wbregion == "ECA"
		replace wbregion_id = 3 if wbregion == "East Asia & Pacific"
		replace wbregion_id = 4 if wbregion == "LATAM"
		replace wbregion_id = 5 if wbregion == "Middle East"
		replace wbregion_id = 6 if wbregion == "South Asia"
		
		label define wbregion_id_label 	1 "Africa" 2 "ECA" 3 "East Asia & Pacific" 	///
										4 "LATAM" 5 "Middle East" 6 "South Asia"
										
		label values wbregion_id wbregion_id_label
	
	* generate a priority variable to indicate in the final set of 200 utilities
	* that these are the priority utilities with pre-existing contacts 
		gen pre_contact = 	1 
		
		label define pre_contact_label 0 "No" 1 "Yes"
		label values pre_contact pre_contact_label
	
	/* 	Generate a random number, rank that random number per type of country 
		(Emerging vs Developed), and assign enumerator-led interview if the rank
		is less than or equal to the total number of observations in that 
		category. 
	*/
		randtreat, generate(treatment) replace strata(developed country_id) misfits(global) setseed(457589)
	
	* drop extra variables 
		keep 	wbregion country utilityname other english spanish developed 	///
				unique_id treatment pre_contact
		order 	unique_id wbregion country utilityname treatment developed 		///
				pre_contact
		
	* save list 
		export excel using "$pilot_data_rand/utilities_list_randomly_assigned_1.xlsx", replace firstrow(variables)
	
**#: RANDOMLY ASSIGN THE REMAINING UTILITIES IN THE RESAMPLING LIST
*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	* import list of the utilities
	import excel "$pilot_data_rand/utilities_list.xlsx", sheet("wave2") firstrow allstring case(lower) clear
	
	* drop developed countries 
	drop if devstatuscountry == "Developed"
	
	* generate a unique_id 
	gen unique_id = 142 + _n 
	
	* sort data set 
	sort unique_id 
	
	* save out the list of utilities with the unique ids 
	export excel using "$pilot_data_rand/utilities_list_uniqueIDs_2.xlsx", replace firstrow(variables)
	

	* generate a numeric country category variable called developed (for stratification)
	gen 	developed = 1 if devstatuscountry == "Developed"
	replace developed = 0 if devstatuscountry == "Developing/Emerging"
	
	* generate a numeric wbregion id (for stratification later)
	gen 	wbregion_id = 1 if wbregion == "Africa"
	replace wbregion_id = 2 if wbregion == "ECA"
	replace wbregion_id = 3 if wbregion == "East Asia & Pacific"
	replace wbregion_id = 4 if wbregion == "LATAM"
	replace wbregion_id = 5 if wbregion == "Middle East"
	replace wbregion_id = 6 if wbregion == "South Asia"
	
	label define wbregion_id_label 	1 "Africa" 2 "ECA" 3 "East Asia & Pacific" 	///
									4 "LATAM" 5 "Middle East" 6 "South Asia"
									
	label values wbregion_id wbregion_id_label
	
	* set seed for replication of the 58 randomly select utilities
	set seed 457589
	 
	* randomly select 58 utilities ~ equally from each region
		foreach i of numlist 1 4 {
			preserve 
				keep if wbregion_id == `i'
				sample 14, count
				tempfile region_`i'_1 
				save `region_`i'_1'
			restore
		}
		
		foreach i of numlist 3 6 {
			preserve 
				keep if wbregion_id == `i'
				sample 15, count
				tempfile region_`i'_1 
				save `region_`i'_1'
			restore
		}
		
	* combine the temporary files 
		use `region_1_1', clear 
		append using `region_3_1'
		append using `region_4_1'
		append using `region_6_1'
	
	* generate a numeric country and wb region id (for stratification) 
		egen country_id = group(country)

	/* 	Generate a random number, rank that random number per country, and 
		assign enumerator-led interview if the rank	is less than or equal to 
		the total number of observations in that category. 
	*/
		randtreat, generate(treatment) replace strata(country_id) misfits(global) setseed(457589)
	
	* rename variable other language
		rename otherlang other
	
	* generate and label the pre_contact variable 
		gen 	pre_contact = 0 
		label	define pre_contact_label 0 "No" 1 "Yes"
		label 	values pre_contact pre_contact_label
	
	* drop extra variables 
		keep 	wbregion country utilityname other english spanish developed 	///
				unique_id treatment pre_contact
			
		order 	unique_id wbregion country utilityname treatment developed 		///
				pre_contact
	
	
	* save list 
		export excel using "$pilot_data_rand/utilities_list_randomly_assigned_2.xlsx", replace firstrow(variables)
	
**#: COMBINE excel files, but keep in different worksheets and format in excel to send to Isle
*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	* import randomized list 1
		import excel using "$pilot_data_rand/utilities_list_randomly_assigned_1.xlsx", clear firstrow 
		tempfile data1
		save `data1'
		
	* import randomized list 2
		import excel using "$pilot_data_rand/utilities_list_randomly_assigned_2.xlsx", clear firstrow 
		tempfile data2
		save `data2'
		
	* append temp files 
		use `data1', clear
		append using `data2', force
		
	*label variables 
		label var other "Speak other language"
		label var english "English speaking"
		label var spanish "Spanish speaking"
		label var unique_id "Utility unique ID"
		label var developed "Developed or Emerging country?"
		label var treatment "Questionnaire assignment"
		label var pre_contact "Did Isle have pre-existing contact with the utility?"
	
	* label treatment values
		label define treatment_label 0 "Self" 1 "Interview"
		label values treatment treatment_label
	
	* label developed values
		label define developed_label 0 "Emerging" 1 "Developed"
		label values developed developed_label
	
	* save into combined file
		export excel using "$pilot_results/Randomization/Sampling_Frame.xlsx", replace firstrow(variables) sheet("First Wave")
		
	* create overall table of treatment balance by country 
		cd "$pilot_results/Randomization"
		asdoc tab developed treatment, 	save(Randomization_tables_overall.doc) replace 
		asdoc tab country treatment, 	save(Randomization_tables_overall.doc) append 
		asdoc tab wbregion treatment,	save(Randomization_tables_overall.doc) append 
