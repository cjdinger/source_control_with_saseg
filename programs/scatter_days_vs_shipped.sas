ods graphics / width=1200 height=400 imagemap=on;
title "Antall dager ute uft. n�r de ble sendt ut";
proc sgscatter data=work.TITLESDAYSRATINGS;
  plot DaysOut*Shipped;
run;
ods graphics off;