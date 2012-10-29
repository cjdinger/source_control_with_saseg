data months (keep=date daysInMonth minutesInMonth);
	length date 8;
	format date monyy7.;
	do yr = 2007 to 2012;
		do mon = 1 to 12;
			date = mdy(mon, 1, yr);
			eom=intnx('month',date,0,'end');
			daysInMonth=day(eom);
			minutesInMonth = 24*60*daysInMonth;
			output;
		end;
	end;
run;

data monthlyminutes;
	set monthlyminutes;
	date = mdy(month(date),1,year(date));
run;

data utilization;
	length utilization 8;
	format utilization percent10.6;
	merge months monthlyminutes(rename=(count=minutesStreamed) drop=percent);
	by date;
	if minutesStreamed = . then
		minutesStreamed=0;
	utilization = minutesStreamed / minutesInMonth;
run;