ods graphics / height=500 width=1000;
title "Days out vs. When shipped";
proc sgscatter data=work.TITLESDAYSRATINGS;
	plot DaysOut*Shipped;
run;

title "Actual cost per DVD rental";
proc sgplot data=TITLESDAYSRATINGS;
	series x=shipped y=costpermovie;
	yaxis label="Cost per DVD";
	xaxis label="Date DVD shipped"  minor;
run;

title "Actual cost per DVD rental (Smoother applied)";
proc sgplot data=TITLESDAYSRATINGS;
	loess x=shipped y=costpermovie / smooth=.16;
	yaxis label="Cost per DVD" max=10;
	xaxis label="Date DVD shipped"  minor;
run;

title "Average cost per DVD rental";
proc sgplot data=work.tsmovies;
	series x=shipped y=costpermovie;
	yaxis label="Cost per DVD";
	xaxis label="Date DVD shipped"  minor;
run;