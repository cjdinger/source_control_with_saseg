ods graphics / width=1200 height=400 imagemap=on;
title "Days out vs. When shipped";
proc sgscatter data="..\data\titlesdaysratings.sas7bdat";
  plot DaysOut*Shipped;
run;
ods graphics off;
