	clear all
	
	* Necessary Package Installations (One time only)
	* net install grc1leg, from("http://www.stata.com/users/vwiggins") replace
	* ssc install schemepack, replace
	* ssc install palettes, replace
	* ssc install colrspace, replace
	
	* Loading the example dataset from GitHub
	import delimited "https://raw.githubusercontent.com/tidyverse/ggplot2/master/data-raw/mpg.csv", clear
	drop if inlist(class, "2seater", "minivan", "pickup")
	
	set seed 12345
	generate foreign = runiformint(0,1)
	
	local scheme tableau
	local group foreign
	local variable hwy
	local plotno = 1
	
	capture separate `variable', by(`group')
	
	levelsof class, local(category)
	foreach ct of local category {
	
	local lines 
	levelsof `group', local(lvl)
	local count : word count `lvl'
	
		foreach level of local lvl {
				sort `variable'
			
				summ `variable' if `group' == `level' & class == "`ct'", detail
				local level = `level' + 1
				local xlab "`xlab' `level' `" "`:lab (`group') `=`level'-1''" "'"
				
				local mean_`level' = `r(mean)'
				local med_p_`level' = `r(p50)'
				local p75_`level' = `r(p75)'
				local p25_`level' = `r(p25)'
				local iqr_`level' = `p75_`level'' - `p25_`level''
				
				generate `variable'`=`level'-1'uq = `variable'`=`level'-1' if `variable'`=`level'-1' <= `=`p75_`level''+(1.5*`iqr_`level'')'
				generate `variable'`=`level'-1'lq = `variable'`=`level'-1' if `variable'`=`level'-1' >= `=`p25_`level''-(1.5*`iqr_`level'')'
				
				quietly summ `variable'`=`level'-1'uq
				local max_`level' = `r(max)'
				quietly summ `variable'`=`level'-1'lq
				local min_`level' = `r(min)'		
						
				colorpalette `scheme', nograph n(`count')	
				local 	lines `lines' ///
						(scatteri `level' `p75_`level'' `level' `max_`level'' , recast(line) lpattern(solid) lcolor("`r(p`level')'") lwidth(1)) || ///
						(scatteri `level' `p25_`level'' `level' `min_`level'' , recast(line) lpattern(solid) lcolor("`r(p`level')'") lwidth(1)) || ///
						(scatteri `level' `med_p_`level'', ms(square) mcolor(background) msize(2)) || ///
						(scatteri `level' `med_p_`level'', ms(square) mcolor("`r(p`level')'")) || ///

		}
	
		twoway `lines', ///
				ytitle("Sample title", color(%0)) ///
				ylabel(0.5 "00" 1 "11" 2 "22" 2.5 "00", labcolor(%0) nogrid tlcolor(%0)) ///
				yscale(range(0.5 2.5) lcolor(%0) fill) ///
				xtitle("") ///
				xlabel(0(15)45, labcolor(%0)) ///
				xscale(range(`=`min' + 0.5' `=`max' + 1.5') off) ///
				scheme(white_tableau) ///
				legend(order(5 "Foreign" 1 "Domestic") size(2.25)) name("lowessplot`plotno'", replace) fysize(15) 
	
		
	* Using loop to write and store the plotting commands and syntax by class
		local sctr
		levelsof `group', local(classes)
		local counter : word count `classes'
		colorpalette `scheme', nograph n(`counter')	
		local i = 1
		foreach cl of local classes {
			
			local sctr `sctr' scatter cty hwy if `group' == `cl' & class == "`ct'", mcolor("`r(p`i')'%60") mlwidth(0) ||
			local ++i

		}
		
		* Plotting each of the above saved commands and storing them for combining later using name()
		quietly twoway `sctr', legend(off) name("scatterplot`plotno'", replace) ytitle("City MPG") xtitle("Highway MPG") ysc(r(10 35)) xsc(r(10 50)) xlabel(0(15)45) ylabel(10(5)35) fysize(80)	
		
		* Combining all the plots saved above
		
		grc1leg2 lowessplot`plotno' scatterplot`plotno', legendfrom("lowessplot`plotno'") position(3) col(1) imargin(t=1.5 b=0 l=0 r=0) commonscheme xcommon scheme(gg_tableau) name("plotted`plotno'")
		local ++plotno
		
		drop hwy???
	}
	
	
	grc1leg plotted1 plotted2 plotted3 plotted4, row(1) commonscheme fysize(80) fxsize(250) imargin(t=0 b=0 l=0 r=0) position(12) scheme(gg_tableau)
	
	* Exporting the visual 
	graph export "~/Desktop/Marginal_dist_boxplot_Stata.png", as(png) name("Graph") width(1920) replace
