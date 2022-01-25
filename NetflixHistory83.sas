/* ----------------------------------------
Code exported from SAS Enterprise Guide
DATE: Friday, January 21, 2022     TIME: 8:19:48 AM
PROJECT: NetflixHistory83
PROJECT PATH: C:\Users\sas\Desktop\egdemo_fromgit\NetflixHistory83.egp
---------------------------------------- */

/* Conditionally delete set of tables or views, if they exists          */
/* If the member does not exist, then no action is performed   */
%macro _eg_conditional_dropds /parmbuff;
	
   	%local num;
   	%local stepneeded;
   	%local stepstarted;
   	%local dsname;
	%local name;

   	%let num=1;
	/* flags to determine whether a PROC SQL step is needed */
	/* or even started yet                                  */
	%let stepneeded=0;
	%let stepstarted=0;
   	%let dsname= %qscan(&syspbuff,&num,',()');
	%do %while(&dsname ne);	
		%let name = %sysfunc(left(&dsname));
		%if %qsysfunc(exist(&name)) %then %do;
			%let stepneeded=1;
			%if (&stepstarted eq 0) %then %do;
				proc sql;
				%let stepstarted=1;

			%end;
				drop table &name;
		%end;

		%if %sysfunc(exist(&name,view)) %then %do;
			%let stepneeded=1;
			%if (&stepstarted eq 0) %then %do;
				proc sql;
				%let stepstarted=1;
			%end;
				drop view &name;
		%end;
		%let num=%eval(&num+1);
      	%let dsname=%qscan(&syspbuff,&num,',()');
	%end;
	%if &stepstarted %then %do;
		quit;
	%end;
%mend _eg_conditional_dropds;


/* Build where clauses from stored process parameters */
%macro _eg_WhereParam( COLUMN, PARM, OPERATOR, TYPE=S, MATCHALL=_ALL_VALUES_, MATCHALL_CLAUSE=1, MAX= , IS_EXPLICIT=0, MATCH_CASE=1);

  %local q1 q2 sq1 sq2;
  %local isEmpty;
  %local isEqual isNotEqual;
  %local isIn isNotIn;
  %local isString;
  %local isBetween;

  %let isEqual = ("%QUPCASE(&OPERATOR)" = "EQ" OR "&OPERATOR" = "=");
  %let isNotEqual = ("%QUPCASE(&OPERATOR)" = "NE" OR "&OPERATOR" = "<>");
  %let isIn = ("%QUPCASE(&OPERATOR)" = "IN");
  %let isNotIn = ("%QUPCASE(&OPERATOR)" = "NOT IN");
  %let isString = (%QUPCASE(&TYPE) eq S or %QUPCASE(&TYPE) eq STRING );
  %if &isString %then
  %do;
	%if "&MATCH_CASE" eq "0" %then %do;
		%let COLUMN = %str(UPPER%(&COLUMN%));
	%end;
	%let q1=%str(%");
	%let q2=%str(%");
	%let sq1=%str(%'); 
	%let sq2=%str(%'); 
  %end;
  %else %if %QUPCASE(&TYPE) eq D or %QUPCASE(&TYPE) eq DATE %then 
  %do;
    %let q1=%str(%");
    %let q2=%str(%"d);
	%let sq1=%str(%'); 
    %let sq2=%str(%'); 
  %end;
  %else %if %QUPCASE(&TYPE) eq T or %QUPCASE(&TYPE) eq TIME %then
  %do;
    %let q1=%str(%");
    %let q2=%str(%"t);
	%let sq1=%str(%'); 
    %let sq2=%str(%'); 
  %end;
  %else %if %QUPCASE(&TYPE) eq DT or %QUPCASE(&TYPE) eq DATETIME %then
  %do;
    %let q1=%str(%");
    %let q2=%str(%"dt);
	%let sq1=%str(%'); 
    %let sq2=%str(%'); 
  %end;
  %else
  %do;
    %let q1=;
    %let q2=;
	%let sq1=;
    %let sq2=;
  %end;
  
  %if "&PARM" = "" %then %let PARM=&COLUMN;

  %let isBetween = ("%QUPCASE(&OPERATOR)"="BETWEEN" or "%QUPCASE(&OPERATOR)"="NOT BETWEEN");

  %if "&MAX" = "" %then %do;
    %let MAX = &parm._MAX;
    %if &isBetween %then %let PARM = &parm._MIN;
  %end;

  %if not %symexist(&PARM) or (&isBetween and not %symexist(&MAX)) %then %do;
    %if &IS_EXPLICIT=0 %then %do;
		not &MATCHALL_CLAUSE
	%end;
	%else %do;
	    not 1=1
	%end;
  %end;
  %else %if "%qupcase(&&&PARM)" = "%qupcase(&MATCHALL)" %then %do;
    %if &IS_EXPLICIT=0 %then %do;
	    &MATCHALL_CLAUSE
	%end;
	%else %do;
	    1=1
	%end;	
  %end;
  %else %if (not %symexist(&PARM._count)) or &isBetween %then %do;
    %let isEmpty = ("&&&PARM" = "");
    %if (&isEqual AND &isEmpty AND &isString) %then
       &COLUMN is null;
    %else %if (&isNotEqual AND &isEmpty AND &isString) %then
       &COLUMN is not null;
    %else %do;
	   %if &IS_EXPLICIT=0 %then %do;
           &COLUMN &OPERATOR 
			%if "&MATCH_CASE" eq "0" %then %do;
				%unquote(&q1)%QUPCASE(&&&PARM)%unquote(&q2)
			%end;
			%else %do;
				%unquote(&q1)&&&PARM%unquote(&q2)
			%end;
	   %end;
	   %else %do;
	       &COLUMN &OPERATOR 
			%if "&MATCH_CASE" eq "0" %then %do;
				%unquote(%nrstr(&sq1))%QUPCASE(&&&PARM)%unquote(%nrstr(&sq2))
			%end;
			%else %do;
				%unquote(%nrstr(&sq1))&&&PARM%unquote(%nrstr(&sq2))
			%end;
	   %end;
       %if &isBetween %then 
          AND %unquote(&q1)&&&MAX%unquote(&q2);
    %end;
  %end;
  %else 
  %do;
	%local emptyList;
  	%let emptyList = %symexist(&PARM._count);
  	%if &emptyList %then %let emptyList = &&&PARM._count = 0;
	%if (&emptyList) %then
	%do;
		%if (&isNotin) %then
		   1;
		%else
			0;
	%end;
	%else %if (&&&PARM._count = 1) %then 
    %do;
      %let isEmpty = ("&&&PARM" = "");
      %if (&isIn AND &isEmpty AND &isString) %then
        &COLUMN is null;
      %else %if (&isNotin AND &isEmpty AND &isString) %then
        &COLUMN is not null;
      %else %do;
	    %if &IS_EXPLICIT=0 %then %do;
			%if "&MATCH_CASE" eq "0" %then %do;
				&COLUMN &OPERATOR (%unquote(&q1)%QUPCASE(&&&PARM)%unquote(&q2))
			%end;
			%else %do;
				&COLUMN &OPERATOR (%unquote(&q1)&&&PARM%unquote(&q2))
			%end;
	    %end;
		%else %do;
		    &COLUMN &OPERATOR (
			%if "&MATCH_CASE" eq "0" %then %do;
				%unquote(%nrstr(&sq1))%QUPCASE(&&&PARM)%unquote(%nrstr(&sq2)))
			%end;
			%else %do;
				%unquote(%nrstr(&sq1))&&&PARM%unquote(%nrstr(&sq2)))
			%end;
		%end;
	  %end;
    %end;
    %else 
    %do;
       %local addIsNull addIsNotNull addComma;
       %let addIsNull = %eval(0);
       %let addIsNotNull = %eval(0);
       %let addComma = %eval(0);
       (&COLUMN &OPERATOR ( 
       %do i=1 %to &&&PARM._count; 
          %let isEmpty = ("&&&PARM&i" = "");
          %if (&isString AND &isEmpty AND (&isIn OR &isNotIn)) %then
          %do;
             %if (&isIn) %then %let addIsNull = 1;
             %else %let addIsNotNull = 1;
          %end;
          %else
          %do;		     
            %if &addComma %then %do;,%end;
			%if &IS_EXPLICIT=0 %then %do;
				%if "&MATCH_CASE" eq "0" %then %do;
					%unquote(&q1)%QUPCASE(&&&PARM&i)%unquote(&q2)
				%end;
				%else %do;
					%unquote(&q1)&&&PARM&i%unquote(&q2)
				%end;
			%end;
			%else %do;
				%if "&MATCH_CASE" eq "0" %then %do;
					%unquote(%nrstr(&sq1))%QUPCASE(&&&PARM&i)%unquote(%nrstr(&sq2))
				%end;
				%else %do;
					%unquote(%nrstr(&sq1))&&&PARM&i%unquote(%nrstr(&sq2))
				%end; 
			%end;
            %let addComma = %eval(1);
          %end;
       %end;) 
       %if &addIsNull %then OR &COLUMN is null;
       %else %if &addIsNotNull %then AND &COLUMN is not null;
       %do;)
       %end;
    %end;
  %end;
%mend _eg_WhereParam;


/* save the current settings of XPIXELS and YPIXELS */
/* so that they can be restored later               */
%macro _sas_pushchartsize(new_xsize, new_ysize);
	%global _savedxpixels _savedypixels;
	options nonotes;
	proc sql noprint;
	select setting into :_savedxpixels
	from sashelp.vgopt
	where optname eq "XPIXELS";
	select setting into :_savedypixels
	from sashelp.vgopt
	where optname eq "YPIXELS";
	quit;
	options notes;
	GOPTIONS XPIXELS=&new_xsize YPIXELS=&new_ysize;
%mend _sas_pushchartsize;

/* restore the previous values for XPIXELS and YPIXELS */
%macro _sas_popchartsize;
	%if %symexist(_savedxpixels) %then %do;
		GOPTIONS XPIXELS=&_savedxpixels YPIXELS=&_savedypixels;
		%symdel _savedxpixels / nowarn;
		%symdel _savedypixels / nowarn;
	%end;
%mend _sas_popchartsize;


/* ---------------------------------- */
/* MACRO: enterpriseguide             */
/* PURPOSE: define a macro variable   */
/*   that contains the file system    */
/*   path of the WORK library on the  */
/*   server.  Note that different     */
/*   logic is needed depending on the */
/*   server type.                     */
/* ---------------------------------- */
%macro enterpriseguide;
%global sasworklocation;
%local tempdsn unique_dsn path;

%if &sysscp=OS %then %do; /* MVS Server */
	%if %sysfunc(getoption(filesystem))=MVS %then %do;
        /* By default, physical file name will be considered a classic MVS data set. */
	    /* Construct dsn that will be unique for each concurrent session under a particular account: */
		filename egtemp '&egtemp' disp=(new,delete); /* create a temporary data set */
 		%let tempdsn=%sysfunc(pathname(egtemp)); /* get dsn */
		filename egtemp clear; /* get rid of data set - we only wanted its name */
		%let unique_dsn=".EGTEMP.%substr(&tempdsn, 1, 16).PDSE"; 
		filename egtmpdir &unique_dsn
			disp=(new,delete,delete) space=(cyl,(5,5,50))
			dsorg=po dsntype=library recfm=vb
			lrecl=8000 blksize=8004 ;
		options fileext=ignore ;
	%end; 
 	%else %do; 
        /* 
		By default, physical file name will be considered an HFS 
		(hierarchical file system) file. 
		*/
		%if "%sysfunc(getoption(filetempdir))"="" %then %do;
			filename egtmpdir '/tmp';
		%end;
		%else %do;
			filename egtmpdir "%sysfunc(getoption(filetempdir))";
		%end;
	%end; 
	%let path=%sysfunc(pathname(egtmpdir));
    %let sasworklocation=%sysfunc(quote(&path));  
%end; /* MVS Server */
%else %do;
	%let sasworklocation = "%sysfunc(getoption(work))/";
%end;
%if &sysscp=VMS_AXP %then %do; /* Alpha VMS server */
	%let sasworklocation = "%sysfunc(getoption(work))";                         
%end;
%if &sysscp=CMS %then %do; 
	%let path = %sysfunc(getoption(work));                         
	%let sasworklocation = "%substr(&path, %index(&path,%str( )))";
%end;
%mend enterpriseguide;

%enterpriseguide


ODS PROCTITLE;
OPTIONS DEV=SVG;
GOPTIONS XPIXELS=0 YPIXELS=0;
%macro HTML5AccessibleGraphSupported;
    %if %_SAS_VERCOMP_FV(9,4,4, 0,0,0) >= 0 %then ACCESSIBLE_GRAPH;
%mend;
FILENAME EGHTMLX TEMP;
ODS HTML5(ID=EGHTMLX) FILE=EGHTMLX
    OPTIONS(BITMAP_MODE='INLINE')
    %HTML5AccessibleGraphSupported
    ENCODING='utf-8'
    STYLE=HtmlBlue
    NOGTITLE
    NOGFOOTNOTE
    GPATH=&sasworklocation
;

/*   START OF NODE: Import NF History   */
%LET _CLIENTTASKLABEL='Import NF History';
%LET _CLIENTPROCESSFLOWNAME='Analyze Netflix Data';
%LET _CLIENTPROJECTPATH='C:\Users\sas\Desktop\egdemo_fromgit\NetflixHistory83.egp';
%LET _CLIENTPROJECTPATHHOST='SASBAP';
%LET _CLIENTPROJECTNAME='NetflixHistory83.egp';

/* --------------------------------------------------------------------
   Code generated by a SAS task
   
   Generated on Friday, January 21, 2022 at 8:16:02 AM
   By task:     Import Data Wizard
   
   Source file:
   C:\Users\sas\Desktop\egdemo_fromgit\data\NetflixHistory.xlsx
   Server:      Local File System
   
   Output data: WORK.NetflixHistory
   Server:      Local
   -------------------------------------------------------------------- */

/* --------------------------------------------------------------------
   This DATA step reads the data values from a temporary text file
   created by the Import Data wizard. The values within the temporary
   text file were extracted from the Excel source file.
   -------------------------------------------------------------------- */

DATA WORK.NetflixHistory;
    LENGTH
        dvd_title        $ 48
        rating           $ 25
        shipped            8
        returned           8
        details          $ 1 ;
    LABEL
        dvd_title        = "DVD Title"
        rating           = "Rating"
        shipped          = "Shipped"
        returned         = "Returned"
        details          = "Details" ;
    FORMAT
        dvd_title        $CHAR48.
        rating           $CHAR25.
        shipped          DATE9.
        returned         DATE9.
        details          $CHAR1. ;
    INFORMAT
        dvd_title        $CHAR48.
        rating           $CHAR25.
        shipped          DATE9.
        returned         DATE9.
        details          $CHAR1. ;
    INFILE 'C:\Users\sas\AppData\Roaming\SAS\EnterpriseGuide\EGTEMP\SEG-23332-6e7b5ec2\contents\NetflixHistory-3e5d9a16a02b46cfad944e881f0f9ecf.txt'
        LRECL=82
        ENCODING="WLATIN1"
        TERMSTR=CRLF
        DLM='7F'x
        MISSOVER
        DSD ;
    INPUT
        dvd_title        : $CHAR48.
        rating           : $CHAR25.
        shipped          : BEST32.
        returned         : BEST32.
        details          : $CHAR1. ;
RUN;


%LET _CLIENTTASKLABEL=;
%LET _CLIENTPROCESSFLOWNAME=;
%LET _CLIENTPROJECTPATH=;
%LET _CLIENTPROJECTPATHHOST=;
%LET _CLIENTPROJECTNAME=;


/*   START OF NODE: create_ratings_data.sas   */
%LET _CLIENTTASKLABEL='create_ratings_data.sas';
%LET _CLIENTPROCESSFLOWNAME='Analyze Netflix Data';
%LET _CLIENTPROJECTPATH='C:\Users\sas\Desktop\egdemo_fromgit\NetflixHistory83.egp';
%LET _CLIENTPROJECTPATHHOST='SASBAP';
%LET _CLIENTPROJECTNAME='NetflixHistory83.egp';
%LET _SASPROGRAMFILE='C:\Users\sas\Desktop\egdemo_fromgit\programs\create_ratings_data.sas';
%LET _SASPROGRAMFILEHOST='SASBAP';

data ratings;
length stars 8 rating $ 15;
infile datalines dsd;
input stars rating;
datalines;
1, Hatet den
2, Likte den ikke
3, Likte den
4, Likte den godt
5, Elsket den
;

%LET _CLIENTTASKLABEL=;
%LET _CLIENTPROCESSFLOWNAME=;
%LET _CLIENTPROJECTPATH=;
%LET _CLIENTPROJECTPATHHOST=;
%LET _CLIENTPROJECTNAME=;
%LET _SASPROGRAMFILE=;
%LET _SASPROGRAMFILEHOST=;


/*   START OF NODE: Ratings Fomat   */
%LET _CLIENTTASKLABEL='Ratings Fomat';
%LET _CLIENTPROCESSFLOWNAME='Analyze Netflix Data';
%LET _CLIENTPROJECTPATH='C:\Users\sas\Desktop\egdemo_fromgit\NetflixHistory83.egp';
%LET _CLIENTPROJECTPATHHOST='SASBAP';
%LET _CLIENTPROJECTNAME='NetflixHistory83.egp';

/* --------------------------------------------------------------------
   Manipulates the incoming data into the correct format for PROC
   FORMAT to use as a CNTLIN data set.
   -------------------------------------------------------------------- */
TITLE; FOOTNOTE;
DATA WORK._EG_CFMT;
    LENGTH label $ 15;
    SET WORK.RATINGS (KEEP=stars rating RENAME=(stars=start rating=label)) END=__last;
    RETAIN fmtname "rating" type "N";

    end=start;

    OUTPUT;

    IF __last = 1 THEN
      DO;
        hlo = "O";
        label = "Unknown";
        OUTPUT;
      END;
RUN;

/* --------------------------------------------------------------------
   Creates a new format based on the data values contained within the
   source data set.
   -------------------------------------------------------------------- */
PROC FORMAT LIBRARY=WORK CNTLIN=WORK._EG_CFMT;
RUN;

/* --------------------------------------------------------------------
   Now that the new SAS format has been created, we want to tidy up by
   deleting the WORK data set
   -------------------------------------------------------------------- */
PROC SQL;
    DROP TABLE WORK._EG_CFMT;
QUIT;


%LET _CLIENTTASKLABEL=;
%LET _CLIENTPROCESSFLOWNAME=;
%LET _CLIENTPROJECTPATH=;
%LET _CLIENTPROJECTPATHHOST=;
%LET _CLIENTPROJECTNAME=;


/*   START OF NODE: Calc Days and Ratings   */
%LET _CLIENTTASKLABEL='Calc Days and Ratings';
%LET _CLIENTPROCESSFLOWNAME='Analyze Netflix Data';
%LET _CLIENTPROJECTPATH='C:\Users\sas\Desktop\egdemo_fromgit\NetflixHistory83.egp';
%LET _CLIENTPROJECTPATHHOST='SASBAP';
%LET _CLIENTPROJECTNAME='NetflixHistory83.egp';

%_eg_conditional_dropds(WORK.TitlesDaysRatings);

PROC SQL;
   CREATE TABLE WORK.TitlesDaysRatings AS 
   SELECT t1.dvd_title AS 'DVD Title'n, 
          t1.Shipped LABEL='', 
          t1.Returned LABEL='', 
          /* DaysOut */
            (DATDIF(t1.Shipped,t1.Returned,'act/act')) AS DaysOut, 
          /* CostPerMovie */
            ((DATDIF(t1.Shipped,t1.Returned,'act/act')) * (10/30)) FORMAT=dollar10.2 AS CostPerMovie, 
          /* ActualRating */
            (input(substr(t1.Rating, PRXMATCH("([0-5]\.0)", t1.Rating),1),best6.)) AS ActualRating, 
          /* RatingPhrase */
            (input(substr(t1.Rating, PRXMATCH("([0-5]\.0)", t1.Rating),1),best6.)) FORMAT=RATING. AS RatingPhrase
      FROM WORK.NETFLIXHISTORY t1
      WHERE t1.Shipped NOT IS MISSING AND t1.Returned NOT IS MISSING AND t1.dvd_title NOT IS MISSING AND t1.dvd_title 
           NOT LIKE 'Disc %' AND t1.dvd_title NOT CONTAINS 'Shipment';
QUIT;



%LET _CLIENTTASKLABEL=;
%LET _CLIENTPROCESSFLOWNAME=;
%LET _CLIENTPROJECTPATH=;
%LET _CLIENTPROJECTPATHHOST=;
%LET _CLIENTPROJECTNAME=;


/*   START OF NODE: scatter_days_vs_shipped.sas   */
%LET SYSLAST=WORK.TITLESDAYSRATINGS;
%LET _CLIENTTASKLABEL='scatter_days_vs_shipped.sas';
%LET _CLIENTPROCESSFLOWNAME='Analyze Netflix Data';
%LET _CLIENTPROJECTPATH='C:\Users\sas\Desktop\egdemo_fromgit\NetflixHistory83.egp';
%LET _CLIENTPROJECTPATHHOST='SASBAP';
%LET _CLIENTPROJECTNAME='NetflixHistory83.egp';
%LET _SASPROGRAMFILE='C:\Users\sas\Desktop\egdemo_fromgit\programs\scatter_days_vs_shipped.sas';
%LET _SASPROGRAMFILEHOST='SASBAP';

ods graphics / width=1200 height=400 imagemap=on;
title "Days out vs. When shipped";
proc sgscatter data=work.TITLESDAYSRATINGS;
  plot DaysOut*Shipped;
run;
ods graphics off;

%LET _CLIENTTASKLABEL=;
%LET _CLIENTPROCESSFLOWNAME=;
%LET _CLIENTPROJECTPATH=;
%LET _CLIENTPROJECTPATHHOST=;
%LET _CLIENTPROJECTNAME=;
%LET _SASPROGRAMFILE=;
%LET _SASPROGRAMFILEHOST=;


/*   START OF NODE: Chart of ratings   */
%LET _CLIENTTASKLABEL='Chart of ratings';
%LET _CLIENTPROCESSFLOWNAME='Analyze Netflix Data';
%LET _CLIENTPROJECTPATH='C:\Users\sas\Desktop\egdemo_fromgit\NetflixHistory83.egp';
%LET _CLIENTPROJECTPATHHOST='SASBAP';
%LET _CLIENTPROJECTNAME='NetflixHistory83.egp';

/* -------------------------------------------------------------------
   Code generated by SAS Task

   Generated on: Friday, January 21, 2022 at 8:19:14 AM
   By task: Chart of ratings

   Input Data: Local:WORK.TITLESDAYSRATINGS
   Server:  Local
   ------------------------------------------------------------------- */

%_eg_conditional_dropds(WORK.SORTTempTableSorted);
/* -------------------------------------------------------------------
   Sort data set Local:WORK.TITLESDAYSRATINGS
   ------------------------------------------------------------------- */

PROC SQL;
	CREATE VIEW WORK.SORTTempTableSorted AS
		SELECT T.RatingPhrase
	FROM WORK.TITLESDAYSRATINGS as T
;
QUIT;
	PATTERN1 COLOR=RED;
	PATTERN2 COLOR=CXFF9900;
	PATTERN3 COLOR=YELLOW;
	PATTERN4 COLOR=CX33CCCC;
	PATTERN5 COLOR=CX339966;
	PATTERN6 COLOR = _STYLE_;
	PATTERN7 COLOR = _STYLE_;
	PATTERN8 COLOR = _STYLE_;
	PATTERN9 COLOR = _STYLE_;
	PATTERN10 COLOR = _STYLE_;
	PATTERN11 COLOR = _STYLE_;
	PATTERN12 COLOR = _STYLE_;
Axis1
	STYLE=1
	WIDTH=1
	MINOR=NONE
	LABEL=(   "How many?")


;
Axis2
	STYLE=1
	WIDTH=1
	LABEL=(   "Rating")


;
TITLE;
TITLE1 "Did we like these movies?";
FOOTNOTE;
PROC GCHART DATA=WORK.SORTTempTableSorted
;
	VBAR 
	 RatingPhrase
 /
	CLIPREF
FRAME	DISCRETE
	TYPE=FREQ
	MISSING
	OUTSIDE=PCT
	NOLEGEND
	COUTLINE=BLACK
	RAXIS=AXIS1
	MAXIS=AXIS2
PATTERNID=MIDPOINT
;
/* -------------------------------------------------------------------
   End of task code
   ------------------------------------------------------------------- */
RUN; QUIT;
%_eg_conditional_dropds(WORK.SORTTempTableSorted);
TITLE; FOOTNOTE;
PATTERN1;
PATTERN2;
PATTERN3;
PATTERN4;
PATTERN5;


%LET _CLIENTTASKLABEL=;
%LET _CLIENTPROCESSFLOWNAME=;
%LET _CLIENTPROJECTPATH=;
%LET _CLIENTPROJECTPATHHOST=;
%LET _CLIENTPROJECTNAME=;


/*   START OF NODE: Summary Statistics   */
%LET _CLIENTTASKLABEL='Summary Statistics';
%LET _CLIENTPROCESSFLOWNAME='Analyze Netflix Data';
%LET _CLIENTPROJECTPATH='C:\Users\sas\Desktop\egdemo_fromgit\NetflixHistory83.egp';
%LET _CLIENTPROJECTPATHHOST='SASBAP';
%LET _CLIENTPROJECTNAME='NetflixHistory83.egp';

/* -------------------------------------------------------------------
   Code generated by SAS Task

   Generated on: Friday, January 21, 2022 at 8:19:14 AM
   By task: Summary Statistics

   Input Data: Local:WORK.TITLESDAYSRATINGS
   Server:  Local
   ------------------------------------------------------------------- */

%_eg_conditional_dropds(WORK.SORTTempTableSorted);
/* -------------------------------------------------------------------
   Sort data set Local:WORK.TITLESDAYSRATINGS
   ------------------------------------------------------------------- */

PROC SQL;
	CREATE VIEW WORK.SORTTempTableSorted AS
		SELECT T.DaysOut, T.RatingPhrase
	FROM WORK.TITLESDAYSRATINGS as T
;
QUIT;
/* -------------------------------------------------------------------
   Run the Means Procedure
   ------------------------------------------------------------------- */
TITLE;
TITLE1 "Stats for ""Days Out""";
FOOTNOTE;
PROC MEANS DATA=WORK.SORTTempTableSorted
	FW=12
	PRINTALLTYPES
	CHARTYPE
	QMETHOD=OS
	NWAY
	VARDEF=DF 	
		MEAN 
		STD 
		MIN 
		MAX 
		MODE 
		N	
		MEDIAN	;
	VAR DaysOut;
	CLASS RatingPhrase /	ORDER=UNFORMATTED ASCENDING;

RUN;
ODS GRAPHICS ON;
TITLE;
TITLE1 "Summary Statistics";
TITLE2 "Box and Whisker Plots";
PROC SGPLOT DATA=WORK.SORTTempTableSorted	;
	VBOX DaysOut / category=RatingPhrase;
RUN;QUIT;
ODS GRAPHICS OFF;
/* -------------------------------------------------------------------
   End of task code
   ------------------------------------------------------------------- */
RUN; QUIT;
%_eg_conditional_dropds(WORK.SORTTempTableSorted);
TITLE; FOOTNOTE;


%LET _CLIENTTASKLABEL=;
%LET _CLIENTPROCESSFLOWNAME=;
%LET _CLIENTPROJECTPATH=;
%LET _CLIENTPROJECTPATHHOST=;
%LET _CLIENTPROJECTNAME=;


/*   START OF NODE: Movies we like   */
%LET _CLIENTTASKLABEL='Movies we like';
%LET _CLIENTPROCESSFLOWNAME='Analyze Netflix Data';
%LET _CLIENTPROJECTPATH='C:\Users\sas\Desktop\egdemo_fromgit\NetflixHistory83.egp';
%LET _CLIENTPROJECTPATHHOST='SASBAP';
%LET _CLIENTPROJECTNAME='NetflixHistory83.egp';

%LET _CLIENTTASKFILTER = RatingPhrase = 5;
TITLE1 "Movies we loved";
FOOTNOTE;

proc report data=WORK.TITLESDAYSRATINGS(FIRSTOBS=1) nowd;
	column 'DVD Title'n;
	WHERE RatingPhrase = 5;
	define 'DVD Title'n / group 'Movie title' format=$CHAR43. missing order=formatted;
	compute 'DVD Title'n;
		if 'DVD Title'n ne ' ' then hold1='DVD Title'n;
		if 'DVD Title'n eq ' ' then 'DVD Title'n=hold1;
	endcomp;
	run;
quit;
TITLE; FOOTNOTE;
%SYMDEL _CLIENTTASKFILTER;


%LET _CLIENTTASKLABEL=;
%LET _CLIENTPROCESSFLOWNAME=;
%LET _CLIENTPROJECTPATH=;
%LET _CLIENTPROJECTPATHHOST=;
%LET _CLIENTPROJECTNAME=;


/*   START OF NODE: Didn't like   */
%LET _CLIENTTASKLABEL='Didn''t like';
%LET _CLIENTPROCESSFLOWNAME='Analyze Netflix Data';
%LET _CLIENTPROJECTPATH='C:\Users\sas\Desktop\egdemo_fromgit\NetflixHistory83.egp';
%LET _CLIENTPROJECTPATHHOST='SASBAP';
%LET _CLIENTPROJECTNAME='NetflixHistory83.egp';

%LET _CLIENTTASKFILTER = RatingPhrase = 2;
TITLE1 "Movies we didn't like";
FOOTNOTE;

proc report data=WORK.TITLESDAYSRATINGS(FIRSTOBS=1) nowd;
	column 'DVD Title'n;
	WHERE RatingPhrase = 2;
	define 'DVD Title'n / group 'Movie title' format=$CHAR43. missing order=formatted;
	compute 'DVD Title'n;
		if 'DVD Title'n ne ' ' then hold1='DVD Title'n;
		if 'DVD Title'n eq ' ' then 'DVD Title'n=hold1;
	endcomp;
	run;
quit;
TITLE; FOOTNOTE;
%SYMDEL _CLIENTTASKFILTER;


%LET _CLIENTTASKLABEL=;
%LET _CLIENTPROCESSFLOWNAME=;
%LET _CLIENTPROJECTPATH=;
%LET _CLIENTPROJECTPATHHOST=;
%LET _CLIENTPROJECTNAME=;


/*   START OF NODE: Prepare Time Series Data   */
%LET _CLIENTTASKLABEL='Prepare Time Series Data';
%LET _CLIENTPROCESSFLOWNAME='Analyze Netflix Data';
%LET _CLIENTPROJECTPATH='C:\Users\sas\Desktop\egdemo_fromgit\NetflixHistory83.egp';
%LET _CLIENTPROJECTPATHHOST='SASBAP';
%LET _CLIENTPROJECTNAME='NetflixHistory83.egp';

/* -------------------------------------------------------------------
   Code generated by SAS Task

   Generated on: Friday, January 21, 2022 at 8:19:15 AM
   By task: Prepare Time Series Data

   Input Data: Local:WORK.TITLESDAYSRATINGS
   Server:  Local
   ------------------------------------------------------------------- */
ODS GRAPHICS ON;

%_eg_conditional_dropds(WORK.TMP0TempTableInput,
		WORK.TSMOVIES);

/* -------------------------------------------------------------------
   Sort data set WORK.TITLESDAYSRATINGS
   ------------------------------------------------------------------- */
PROC SORT
	DATA=WORK.TITLESDAYSRATINGS(KEEP=shipped CostPerMovie)
	OUT=WORK.TMP0TempTableInput
	;
	BY shipped;
RUN;

PROC EXPAND DATA=WORK.TMP0TempTableInput
	OUT=WORK.TSMOVIES(LABEL="Modified Time Series data for WORK.TITLESDAYSRATINGS")
	TO = DAY
	ALIGN = BEGINNING
	METHOD = SPLINE(NOTAKNOT, NOTAKNOT) 
	PLOT=(ALL SERIES)
	OBSERVED = (BEGINNING, BEGINNING) 
;

	ID shipped;
	CONVERT CostPerMovie / 

		TRANSFORMOUT	=(			CUAVE  10 
	)
			
	; 
 
 
TITLE;
 
FOOTNOTE;
FOOTNOTE1 "Generated by SAS (&_SASSERVERNAME, &SYSSCPL) on %TRIM(%QSYSFUNC(DATE(), NLDATE20.)) at %TRIM(%QSYSFUNC(TIME(), NLTIMAP25.))";
 
/* -------------------------------------------------------------------
   End of task code
   ------------------------------------------------------------------- */
RUN; QUIT;
%_eg_conditional_dropds(WORK.TMP0TempTableInput);
TITLE; FOOTNOTE;
ODS GRAPHICS OFF;


%LET _CLIENTTASKLABEL=;
%LET _CLIENTPROCESSFLOWNAME=;
%LET _CLIENTPROJECTPATH=;
%LET _CLIENTPROJECTPATHHOST=;
%LET _CLIENTPROJECTNAME=;


/*   START OF NODE: create_series_plots.sas   */
%LET SYSLAST=WORK.TSMOVIES;
%LET _CLIENTTASKLABEL='create_series_plots.sas';
%LET _CLIENTPROCESSFLOWNAME='Analyze Netflix Data';
%LET _CLIENTPROJECTPATH='C:\Users\sas\Desktop\egdemo_fromgit\NetflixHistory83.egp';
%LET _CLIENTPROJECTPATHHOST='SASBAP';
%LET _CLIENTPROJECTNAME='NetflixHistory83.egp';
%LET _SASPROGRAMFILE='C:\Users\sas\Desktop\egdemo_fromgit\programs\create_series_plots.sas';
%LET _SASPROGRAMFILEHOST='SASBAP';

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

%LET _CLIENTTASKLABEL=;
%LET _CLIENTPROCESSFLOWNAME=;
%LET _CLIENTPROJECTPATH=;
%LET _CLIENTPROJECTPATHHOST=;
%LET _CLIENTPROJECTNAME=;
%LET _SASPROGRAMFILE=;
%LET _SASPROGRAMFILEHOST=;

;*';*";*/;quit;run;
ODS _ALL_ CLOSE;
