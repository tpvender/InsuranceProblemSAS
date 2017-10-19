
%let PATH 	= /home/taylorvender20180/my_courses/donald.wedding/c_8888/PRED411/UNIT02/HW;
%let NAME 	= LR;
%let LIB	= &NAME..;

libname &NAME. "&PATH.";


%let INFILE	=	&LIB.logit_insurance;
%let TEMPFILE = TEMPFILE;
%let SCRUBFILE 	= SCRUBFILE;
%let BUCKETFILE = BUCKETFILE;
%LET LASTFILE = LASTFILE;

proc print data = &LIB.logit_insurance_test (obs = 10);

proc contents data=&INFILE.;

proc print data=&INFILE.(obs=6);
run;



data &TEMPFILE.;
set &INFILE.;
drop INDEX;
drop TARGET_AMT;
run;

proc print data=&TEMPFILE.(obs=7);
run;


/*
proc means data=&TEMPFILE. n nmiss mean median;
*have to get rid of character variables;
var KIDSDRIV AGE HOMEKIDS YOJ INCOME  HOME_VAL TRAVTIME BLUEBOOK TIF OLDCLAIM CLM_FREQ  MVR_PTS CAR_AGE ;
run;
*/

*great way to visually look at the data;
proc means data=&TEMPFILE. n nmiss mean median;
*easier way to do proc means for just numeric data;
var _numeric_ ;
run;


proc freq data=&TEMPFILE.;
table _character_ /missing;
run;




data &scrubfile.;
set &tempfile.;

IMP_AGE = AGE;
if missing( IMP_AGE ) then IMP_AGE = 45.0;

IMP_YOJ = YOJ;
if missing( YOJ ) then IMP_YOJ = 11.0;

IMP_INCOME = INCOME;
if missing( INCOME ) then do;
	IMP_INCOME = 62000.00;
	if IMP_HOME_VAL < 278000.00 then IMP_INCOME = 49000.00;
	if IMP_HOME_VAL < 278000.00 AND (JOB = 'Home Maker' or JOB = 'Student')
	then IMP_INCOME = 8539.00;
	if IMP_HOME_VAL < 278000.00 AND JOB = 'Clerical' then IMP_INCOME = 34000.00;
	if IMP_HOME_VAL < 278000.00 AND JOB not in('Home Maker','Student','Clerical') AND 
	EDUCATION in('<High School','z_High School') then IMP_INCOME = 49000.00;
	if IMP_HOME_VAL < 278000.00 AND JOB not in('Home Maker','Student','Clerical')
	AND EDUCATION not in('<High School','z_High School') then IMP_INCOME = 72000.00;
	
	if 41000.00>IMP_HOME_VAL >= 278000.00 then IMP_INCOME = 114000.00;
	if 523000.00> IMP_HOME_VAL >= 411000.00 then IMP_INCOME = 179000.00;
	if IMP_HOME_VAL>=523000.00 then IMP_INCOME = 242000.00;
end;
	


IMP_HOME_VAL = HOME_VAL;
if missing ( HOME_VAL ) then IMP_HOME_VAL = 161159.53;

IMP_CAR_AGE = CAR_AGE;
if missing ( CAR_AGE ) then IMP_CAR_AGE = 8.0;


IMP_JOB = JOB;
if missing(IMP_JOB) then do;
	IMP_JOB = "z_Blue Collar";
	if EDUCATION = "PhD" then IMP_JOB = "Doctor";
	if EDUCATION = "Masters" and IMP_INCOME < 15000.00 then 
		IMP_JOB = "Home Maker";	
	if EDUCATION = "Masters" and IMP_INCOME > 15000.00 then 
		IMP_JOB = "Lawyer";
	if EDUCATION not in("Masters", "PhD") and IMP_INCOME < 15000.00 then
		IMP_JOB = "Student";
	if EDUCATION not in("Masters", "PhD") and 15000.00< IMP_INCOME < 45000.00 then
		IMP_JOB = "Clerical";	
	if EDUCATION not in("Masters", "PhD") and IMP_INCOME > 45000.00 then
		IMP_JOB = "z_Blue Collar";	
end;

CAP_IMP_INCOME = IMP_INCOME;
IF IMP_INCOME > 217269.4 then CAP_IMP_INCOME = 217269.4;

/*
*Cap at 99% table;
CAP_TRAVTIME = TRAVTIME;
IF TRAVTIME > 71.00 then CAP_TRAVTIME = 71.00;

CAP_BLUEBOOK = BLUEBOOK;
IF BLUEBOOK > 38500.00 then CAP_BLUEBOOK = 38500.00;

TIF = CAP_TIF;
if TIF > 17.00 then TIF = 17.00;
*/

*drop TIF;
*drop BLUEBOOK;
*drop TRAVTIME;
drop AGE;
drop YOJ;
drop INCOME;
drop HOME_VAL;
drop CAR_AGE;
drop JOB;
drop RED_CAR;
run;

proc contents data=&scrubfile.;

proc means data=&SCRUBFILE. mean median max min;
class IMP_JOB;
var IMP_INCOME;
run;

proc univariate data=&scrubfile.;
var _numeric_;
histogram;
run;

proc means data=&scrubfile. n nmiss mean median;
*easier way to do proc means for just numeric data;
var _numeric_ ;
run;

ods graphics on;
*produce the scatterplot matrix;
Title2 "Scatterplot Matrix";
proc corr data= &scrubfile. plot=matrix(histogram nvar=all);
run;
ods graphics off;


*can look for outliers and maybe even cap income;
proc univariate data=&SCRUBFILE. plot;
class TARGET_FLAG;
var _numeric_;
histogram;
run;

proc means data=&SCRUBFILE. nmiss min mean median;
var _numeric_;
run;

proc freq data=&SCRUBFILE.;
table _character_ /missing;
run;


proc print data=&SCRUBFILE.(obs=8);
run;


*only care about the third row for our purpose;
* 0 is people who don't crash car, 1 is people who do crash car;
*total gives you the total % that do crash their car and those that don't;
*tells us %of each category that crashes care and what % doesn't =>tells you if something is predictive or not;
*for instance, if blue collar people don't crash their car less than the total (average person), we would assume that this variable is predictive;
*based on the info can see that red car probably isn't predictive;
proc freq data=&SCRUBFILE.;
table ( _character_ ) * TARGET_FLAG /missing;
run;


proc means data=&SCRUBFILE. mean median;
class TARGET_FLAG;
var _numeric_;
run;


*can look for outliers and maybe even cap income;
proc univariate data=&SCRUBFILE. plot;
class TARGET_FLAG;
var IMP_INCOME;
histogram;
run;


*use proc univariate for scrubfile to find values for buckets;
data &bucketfile.;
set &scrubfile.;
	        
	BLUEBOOK_BUCKET = BLUEBOOK;
   	if BLUEBOOK < 9280 then BLUEBOOK_BUCKET = 1; *25th;
        else if BLUEBOOK < 14440 then BLUEBOOK_BUCKET = 2; *50th;
        else if BLUEBOOK < 20850 then BLUEBOOK_BUCKET = 3; *75th;
        else BLUEBOOK_BUCKET = 4;
     
     TIF_BUCKET = TIF;
     if TIF = 1 then TIF_BUCKET = 1; *25th;
     	else if TIF <= 4 then TIF_BUCKET = 2; *50th;
     	else if TIF <= 7 then TIF_BUCKET = 3; *75th;
     	else TIF_BUCKET = 4;

	IMP_INCOME_BUCKET = IMP_INCOME;
    if IMP_INCOME < 28300.00 then IMP_INCOME_BUCKET = 1; *25th;
        else if IMP_INCOME < 53600.00 then IMP_INCOME_BUCKET = 2; *50th;
        else if IMP_INCOME < 83300.00 then IMP_INCOME_BUCKET = 3; *75th;
        else IMP_INCOME_BUCKET = 4;
	
	HAS_CLMD = CLM_FREQ;
    if CLM_FREQ = 0 then HAS_CLMD = 0;
		else HAS_CLMD = 1;

drop BLUEBOOK;
drop TIF;
drop IMP_INCOME;
drop CLM_FREQ;
run;

proc print data= &bucketfile. (obs=5);

proc means data=&bucketfile. mean n nmiss;

proc freq data=&bucketfile.;
table ( _character_ ) * TARGET_FLAG /missing;
run;


proc means data=&bucketfile. mean median;
class TARGET_FLAG;
var _numeric_;
run;

proc univariate data=&bucketfile. plot;
class TARGET_FLAG;
var _numeric_;
histogram;
run;

data &lastfile.;
set &bucketfile.;

if MVR_PTS = 0 then Has_MVR_PTS = 0;
else Has_MVR_PTS = 1;

drop IMP_HOME_VAL;
drop IMP_YOJ;
run;

proc univariate data=&lastfile. plot;
class TARGET_FLAG;
var _numeric_;
histogram;
run;

ODS graphics on;

TITLE 'stepwise selection with bucket variables and fixes';
proc logistic data=&lastfile. plot(only)=(roc(ID=prob));
class IMP_JOB CAR_TYPE CAR_USE EDUCATION IMP_JOB MSTATUS PARENT1 REVOKED SEX URBANICITY/param=ref;
model TARGET_FLAG( ref="0" ) = 
					CAR_TYPE 
					CAR_USE 
					EDUCATION 
					IMP_JOB 
					MSTATUS 
					PARENT1 
					REVOKED 
					SEX 
					URBANICITY
					KIDSDRIV 
					HOMEKIDS 
					TRAVTIME 
					BLUEBOOK_BUCKET 
					TIF_BUCKET 
					OLDCLAIM 
					HAS_CLMD 
					MVR_PTS 
					Has_MVR_PTS
					IMP_AGE 
					IMP_INCOME_BUCKET 
					IMP_CAR_AGE 
					/selection=stepwise roceps=0.1;
run;

TITLE 'stepwise selection with bucket variables categorical and fixes';
proc logistic data=&lastfile. plot(only)=(roc(ID=prob));
class BLUEBOOK_BUCKET TIF_BUCKET IMP_INCOME_BUCKET IMP_JOB CAR_TYPE CAR_USE EDUCATION IMP_JOB MSTATUS PARENT1 REVOKED SEX URBANICITY/param=ref;
model TARGET_FLAG( ref="0" ) = 
					CAR_TYPE 
					CAR_USE 
					EDUCATION 
					IMP_JOB 
					MSTATUS 
					PARENT1 
					REVOKED 
					SEX 
					URBANICITY
					KIDSDRIV 
					HOMEKIDS 
					TRAVTIME 
					BLUEBOOK_BUCKET 
					TIF_BUCKET 
					OLDCLAIM 
					HAS_CLMD 
					MVR_PTS 
					Has_MVR_PTS
					IMP_AGE 
					IMP_INCOME_BUCKET 
					IMP_CAR_AGE 
					/selection=stepwise roceps=0.1;
run;

TITLE 'stepwise selection with bucket variables numerical';
proc logistic data=&bucketfile. plot(only)=(roc(ID=prob));
class IMP_JOB CAR_TYPE CAR_USE EDUCATION IMP_JOB MSTATUS PARENT1 REVOKED SEX URBANICITY/param=ref;
model TARGET_FLAG( ref="0" ) = 
					CAR_TYPE 
					CAR_USE 
					EDUCATION 
					IMP_JOB 
					MSTATUS 
					PARENT1 
					REVOKED 
					SEX 
					URBANICITY
					KIDSDRIV 
					HOMEKIDS 
					TRAVTIME 
					BLUEBOOK_BUCKET 
					TIF_BUCKET 
					OLDCLAIM 
					HAS_CLMD 
					MVR_PTS 
					IMP_AGE 
					IMP_YOJ 
					IMP_INCOME_BUCKET
					IMP_HOME_VAL 
					IMP_CAR_AGE 
					/selection=stepwise roceps=0.1;
run;

TITLE 'stepwise selection with bucket variables categorical';
proc logistic data=&bucketfile. plot(only)=(roc(ID=prob));
class BLUEBOOK_BUCKET TIF_BUCKET IMP_INCOME_BUCKET IMP_JOB CAR_TYPE CAR_USE EDUCATION IMP_JOB MSTATUS PARENT1 REVOKED SEX URBANICITY/param=ref;
model TARGET_FLAG( ref="0" ) = 
					CAR_TYPE 
					CAR_USE 
					EDUCATION 
					IMP_JOB 
					MSTATUS 
					PARENT1 
					REVOKED 
					SEX 
					URBANICITY
					KIDSDRIV 
					HOMEKIDS 
					TRAVTIME 
					BLUEBOOK_BUCKET 
					TIF_BUCKET 
					OLDCLAIM 
					HAS_CLMD 
					MVR_PTS 
					IMP_AGE 
					IMP_YOJ 
					IMP_INCOME_BUCKET
					IMP_HOME_VAL 
					IMP_CAR_AGE 
					/selection=stepwise roceps=0.1;
run;


/*
proc logistic data=&SCRUBFILE.;
*SAS assumes you don't crash yur car and will give you the probability that people will crash their car ref="0";
*This is just the numerical data;
model TARGET_FLAG( ref="0" ) = 
					KIDSDRIV 
					HOMEKIDS 
					TRAVTIME 
					BLUEBOOK 
					TIF 
					OLDCLAIM 
					CLM_FREQ 
					MVR_PTS 
					IMP_AGE 
					IMP_YOJ 
					CAP_IMP_INCOME 
					IMP_HOME_VAL 
					IMP_CAR_AGE 
					/selection=forward;
run;
/*
*interpretation of point estimate: everytime my traffic ticket goes up by one, my odds of crashing my car goesup 1.224;
*everytime my time in force goes up a year the odds of crashing my car goes down 5% (because the odds is below 1);
*most people just look at the coefficients and see if you're negative you are safer and if your're positive you're riskier;
*same results with /param=ref but coefficients are more interpretable;
*1:33 IN THE 02-04-2015;
proc logistic data=&SCRUBFILE.;
class IMP_JOB CAR_TYPE CAR_USE EDUCATION IMP_JOB MSTATUS PARENT1 REVOKED SEX URBANICITY/param=ref;
model TARGET_FLAG( ref="0" ) =  
					CAR_TYPE 
					CAR_USE 
					EDUCATION 
					IMP_JOB 
					MSTATUS 
					PARENT1 
					REVOKED 
					SEX 
					URBANICITY
					KIDSDRIV 
					HOMEKIDS 
					TRAVTIME 
					BLUEBOOK 
					TIF 
					OLDCLAIM 
					CLM_FREQ 
					MVR_PTS 
					IMP_AGE 
					IMP_YOJ 
					CAP_IMP_INCOME 
					IMP_HOME_VAL 
					IMP_CAR_AGE 
					/selection=forward;
run;
*/

TITLE 'Original model stepwise regression';
proc logistic data=&SCRUBFILE. plot(only)=(roc(ID=prob));
class IMP_JOB CAR_TYPE CAR_USE EDUCATION IMP_JOB MSTATUS PARENT1 REVOKED SEX URBANICITY/param=ref;
model TARGET_FLAG( ref="0" ) = 
					CAR_TYPE 
					CAR_USE 
					EDUCATION 
					IMP_JOB 
					MSTATUS 
					PARENT1 
					REVOKED 
					SEX 
					URBANICITY
					KIDSDRIV 
					HOMEKIDS 
					TRAVTIME 
					BLUEBOOK 
					TIF 
					OLDCLAIM 
					CLM_FREQ 
					MVR_PTS 
					IMP_AGE 
					IMP_YOJ 
					CAP_IMP_INCOME 
					IMP_HOME_VAL 
					IMP_CAR_AGE 
					/selection=stepwise roceps=0.1;
run;

/*
proc logistic data=&SCRUBFILE.;
class IMP_JOB CAR_TYPE CAR_USE EDUCATION IMP_JOB MSTATUS PARENT1 REVOKED SEX URBANICITY/param=ref;
model TARGET_FLAG( ref="0" ) = 
					CAR_TYPE 
					CAR_USE 
					EDUCATION 
					IMP_JOB 
					MSTATUS 
					PARENT1 
					REVOKED 
					SEX 
					URBANICITY
					KIDSDRIV 
					HOMEKIDS 
					TRAVTIME 
					BLUEBOOK 
					TIF 
					OLDCLAIM 
					CLM_FREQ 
					MVR_PTS 
					IMP_AGE 
					IMP_YOJ 
					CAP_IMP_INCOME 
					IMP_HOME_VAL 
					IMP_CAR_AGE 
					/selection=backward;
run;
*/

TITLE 'lastfile with stepwise selection, buckets as numeric variables';

data LASTSCORE;
set &LIB.logit_insurance_test;

if MVR_PTS = 0 then Has_MVR_PTS = 0;
else Has_MVR_PTS = 1;

drop IMP_HOME_VAL;
drop IMP_YOJ;

IMP_AGE = AGE;
if missing( IMP_AGE ) then IMP_AGE = 45.0;

IMP_YOJ = YOJ;
if missing( YOJ ) then IMP_YOJ = 11.0;

IMP_INCOME = INCOME;
if missing( INCOME ) then do;
	IMP_INCOME = 62000.00;
	if IMP_HOME_VAL < 278000.00 then IMP_INCOME = 49000.00;
	if IMP_HOME_VAL < 278000.00 AND (JOB = 'Home Maker' or JOB = 'Student')
	then IMP_INCOME = 8539.00;
	if IMP_HOME_VAL < 278000.00 AND JOB = 'Clerical' then IMP_INCOME = 34000.00;
	if IMP_HOME_VAL < 278000.00 AND JOB not in('Home Maker','Student','Clerical') AND 
	EDUCATION in('<High School','z_High School') then IMP_INCOME = 49000.00;
	if IMP_HOME_VAL < 278000.00 AND JOB not in('Home Maker','Student','Clerical')
	AND EDUCATION not in('<High School','z_High School') then IMP_INCOME = 72000.00;
	
	if 41000.00>IMP_HOME_VAL >= 278000.00 then IMP_INCOME = 114000.00;
	if 523000.00> IMP_HOME_VAL >= 411000.00 then IMP_INCOME = 179000.00;
	if IMP_HOME_VAL>=523000.00 then IMP_INCOME = 242000.00;
end;
	


IMP_HOME_VAL = HOME_VAL;
if missing ( HOME_VAL ) then IMP_HOME_VAL = 161159.53;

IMP_CAR_AGE = CAR_AGE;
if missing ( CAR_AGE ) then IMP_CAR_AGE = 8.0;


IMP_JOB = JOB;
if missing(IMP_JOB) then do;
	IMP_JOB = "z_Blue Collar";
	if EDUCATION = "PhD" then IMP_JOB = "Doctor";
	if EDUCATION = "Masters" and IMP_INCOME < 15000.00 then 
		IMP_JOB = "Home Maker";	
	if EDUCATION = "Masters" and IMP_INCOME > 15000.00 then 
		IMP_JOB = "Lawyer";
	if EDUCATION not in("Masters", "PhD") and IMP_INCOME < 15000.00 then
		IMP_JOB = "Student";
	if EDUCATION not in("Masters", "PhD") and 15000.00< IMP_INCOME < 45000.00 then
		IMP_JOB = "Clerical";	
	if EDUCATION not in("Masters", "PhD") and IMP_INCOME > 45000.00 then
		IMP_JOB = "z_Blue Collar";	
end;

	CAP_IMP_INCOME = IMP_INCOME;
	IF IMP_INCOME > 217269.4 then CAP_IMP_INCOME = 217269.4;


	        
	BLUEBOOK_BUCKET = BLUEBOOK;
   	if BLUEBOOK < 9280 then BLUEBOOK_BUCKET = 1; *25th;
        else if BLUEBOOK < 14440 then BLUEBOOK_BUCKET = 2; *50th;
        else if BLUEBOOK < 20850 then BLUEBOOK_BUCKET = 3; *75th;
        else BLUEBOOK_BUCKET = 4;
     
     TIF_BUCKET = TIF;
     if TIF = 1 then TIF_BUCKET = 1; *25th;
     	else if TIF <= 4 then TIF_BUCKET = 2; *50th;
     	else if TIF <= 7 then TIF_BUCKET = 3; *75th;
     	else TIF_BUCKET = 4;

	IMP_INCOME_BUCKET = IMP_INCOME;
    if IMP_INCOME < 28300.00 then IMP_INCOME_BUCKET = 1; *25th;
        else if IMP_INCOME < 53600.00 then IMP_INCOME_BUCKET = 2; *50th;
        else if IMP_INCOME < 83300.00 then IMP_INCOME_BUCKET = 3; *75th;
        else IMP_INCOME_BUCKET = 4;
	
	HAS_CLMD = CLM_FREQ;
    if CLM_FREQ = 0 then HAS_CLMD = 0;
		else HAS_CLMD = 1;

		drop BLUEBOOK;
		drop TIF;
		drop IMP_INCOME;
		drop CLM_FREQ;
		drop AGE;
		drop YOJ;
		drop INCOME;
		drop HOME_VAL;
		drop CAR_AGE;
		drop JOB;
		drop RED_CAR;
		
LOG_P_TARGET = -0.8994
	+ ((CAR_TYPE in ("Minivan")) * -0.6986)
    + ((CAR_TYPE in ("Panel Truck")) * -0.2342)
    + ((CAR_TYPE in ("Pickup")) * -0.1778)
    + ((CAR_TYPE in ("Sports Car")) * 0.2638)
    + ((CAR_TYPE in ("Van")) * -0.0721)
    + ((CAR_USE in ("Commercial")) * 0.7655)
    + ((EDUCATION in ("<High School")) * -0.0303)
    + ((EDUCATION in ("Bachelors")) * -0.3843)
    + ((EDUCATION in ("Masters")) * -0.3503)
    + ((EDUCATION in ("PhD")) * -0.1202)
    + ((IMP_JOB in ("Clerical")) * 0.0543)
    + ((IMP_JOB in ("Doctor")) * -0.8109)
    + ((IMP_JOB in ("Home Maker")) * -0.0960)
    + ((IMP_JOB in ("Lawyer")) * -0.1770)
    + ((IMP_JOB in ("Manager")) * -0.8798)
    + ((IMP_JOB in ("Professional")) * -0.1470)
    + ((IMP_JOB in ("Student")) * -0.00346)
    + ((MSTATUS in ("Yes")) * -0.6207)
    + ((PARENT1 in ("No")) * -0.4563)
    + ((REVOKED in ("No")) * -0.9698)
    + ((URBANICITY in ("Highly Urban/ Urban")) * 2.3585)
    + (KIDSDRIV * 0.4120)
    + (TRAVTIME * 0.0147)
    + (BLUEBOOK_BUCKET * -0.1436)
    + (TIF_BUCKET * -0.1978)
    + (OLDCLAIM * -0.00002)
    + (HAS_CLMD * 0.6419)
    + (MVR_PTS * 0.1008)
    + (IMP_INCOME_BUCKET * -0.2137)
    ;
    
if LOG_P_TARGET > 20  then LOG_P_TARGET = 20;
if LOG_P_TARGET < -20 then LOG_P_TARGET = -20;

exp_transform = exp(LOG_P_TARGET);
P_TARGET_FLAG = (exp_transform / ( 1+exp_transform));


KEEP INDEX;
KEEP P_TARGET_FLAG;

run;

proc print data=LASTSCORE(obs=5);
run;

proc means data=LASTSCORE n nmiss;
run; quit;

libname scrlib "/home/taylorvender20180/my_courses/PRED411/UNIT02";

data scrlib.VENDERinsurance_LASTSCORE2;
set LASTSCORE;
run;

proc export data=scrlib.VENDERinsurance_LASTSCORE2 DBMS=csv outfile='/home/taylorvender20180/my_courses/PRED411/UNIT02/VENDERinsurance_LASTSCORE2.csv' replace;
run;



TITLE 'bucketfile with stepwise selection, buckets as numeric variables';

data BUCKETSCORE;
set &LIB.logit_insurance_test;

IMP_AGE = AGE;
if missing( IMP_AGE ) then IMP_AGE = 45.0;

IMP_YOJ = YOJ;
if missing( YOJ ) then IMP_YOJ = 11.0;

IMP_INCOME = INCOME;
if missing( INCOME ) then do;
	IMP_INCOME = 62000.00;
	if IMP_HOME_VAL < 278000.00 then IMP_INCOME = 49000.00;
	if IMP_HOME_VAL < 278000.00 AND (JOB = 'Home Maker' or JOB = 'Student')
	then IMP_INCOME = 8539.00;
	if IMP_HOME_VAL < 278000.00 AND JOB = 'Clerical' then IMP_INCOME = 34000.00;
	if IMP_HOME_VAL < 278000.00 AND JOB not in('Home Maker','Student','Clerical') AND 
	EDUCATION in('<High School','z_High School') then IMP_INCOME = 49000.00;
	if IMP_HOME_VAL < 278000.00 AND JOB not in('Home Maker','Student','Clerical')
	AND EDUCATION not in('<High School','z_High School') then IMP_INCOME = 72000.00;
	
	if 41000.00>IMP_HOME_VAL >= 278000.00 then IMP_INCOME = 114000.00;
	if 523000.00> IMP_HOME_VAL >= 411000.00 then IMP_INCOME = 179000.00;
	if IMP_HOME_VAL>=523000.00 then IMP_INCOME = 242000.00;
end;
	


IMP_HOME_VAL = HOME_VAL;
if missing ( HOME_VAL ) then IMP_HOME_VAL = 161159.53;

IMP_CAR_AGE = CAR_AGE;
if missing ( CAR_AGE ) then IMP_CAR_AGE = 8.0;


IMP_JOB = JOB;
if missing(IMP_JOB) then do;
	IMP_JOB = "z_Blue Collar";
	if EDUCATION = "PhD" then IMP_JOB = "Doctor";
	if EDUCATION = "Masters" and IMP_INCOME < 15000.00 then 
		IMP_JOB = "Home Maker";	
	if EDUCATION = "Masters" and IMP_INCOME > 15000.00 then 
		IMP_JOB = "Lawyer";
	if EDUCATION not in("Masters", "PhD") and IMP_INCOME < 15000.00 then
		IMP_JOB = "Student";
	if EDUCATION not in("Masters", "PhD") and 15000.00< IMP_INCOME < 45000.00 then
		IMP_JOB = "Clerical";	
	if EDUCATION not in("Masters", "PhD") and IMP_INCOME > 45000.00 then
		IMP_JOB = "z_Blue Collar";	
end;

	CAP_IMP_INCOME = IMP_INCOME;
	IF IMP_INCOME > 217269.4 then CAP_IMP_INCOME = 217269.4;


	        
	BLUEBOOK_BUCKET = BLUEBOOK;
   	if BLUEBOOK < 9280 then BLUEBOOK_BUCKET = 1; *25th;
        else if BLUEBOOK < 14440 then BLUEBOOK_BUCKET = 2; *50th;
        else if BLUEBOOK < 20850 then BLUEBOOK_BUCKET = 3; *75th;
        else BLUEBOOK_BUCKET = 4;
     
     TIF_BUCKET = TIF;
     if TIF = 1 then TIF_BUCKET = 1; *25th;
     	else if TIF <= 4 then TIF_BUCKET = 2; *50th;
     	else if TIF <= 7 then TIF_BUCKET = 3; *75th;
     	else TIF_BUCKET = 4;

	IMP_INCOME_BUCKET = IMP_INCOME;
    if IMP_INCOME < 28300.00 then IMP_INCOME_BUCKET = 1; *25th;
        else if IMP_INCOME < 53600.00 then IMP_INCOME_BUCKET = 2; *50th;
        else if IMP_INCOME < 83300.00 then IMP_INCOME_BUCKET = 3; *75th;
        else IMP_INCOME_BUCKET = 4;
	
	HAS_CLMD = CLM_FREQ;
    if CLM_FREQ = 0 then HAS_CLMD = 0;
		else HAS_CLMD = 1;

		drop BLUEBOOK;
		drop TIF;
		drop IMP_INCOME;
		drop CLM_FREQ;
		drop AGE;
		drop YOJ;
		drop INCOME;
		drop HOME_VAL;
		drop CAR_AGE;
		drop JOB;
		drop RED_CAR;
		
LOG_P_TARGET = -0.9139
	+ ((CAR_TYPE in ("Minivan")) * -0.7063)
    + ((CAR_TYPE in ("Panel Truck")) * -0.2145)
    + ((CAR_TYPE in ("Pickup")) * -0.1788)
    + ((CAR_TYPE in ("Sports Car")) * 0.2595)
    + ((CAR_TYPE in ("Van")) * -0.0685)
    + ((CAR_USE in ("Commercial")) * 0.7676)
    + ((EDUCATION in ("<High School")) * -0.0294)
    + ((EDUCATION in ("Bachelors")) * -0.3775)
    + ((EDUCATION in ("Masters")) * -0.3491)
    + ((EDUCATION in ("PhD")) * -0.0677)
    + ((IMP_JOB in ("Clerical")) * 0.0508)
    + ((IMP_JOB in ("Doctor")) * -0.8304)
    + ((IMP_JOB in ("Home Maker")) * -0.1116)
    + ((IMP_JOB in ("Lawyer")) * -0.1680)
    + ((IMP_JOB in ("Manager")) * -0.8845)
    + ((IMP_JOB in ("Professional")) * -0.1408)
    + ((IMP_JOB in ("Student")) * -0.0957)
    + ((MSTATUS in ("Yes")) * -0.4676)
    + ((PARENT1 in ("No")) * -0.4604)
    + ((REVOKED in ("No")) * -0.9596)
    + ((URBANICITY in ("Highly Urban/ Urban")) * 2.3535)
    + (KIDSDRIV * 0.4108)
    + (TRAVTIME * 0.0146)
    + (BLUEBOOK_BUCKET * -0.1432)
    + (TIF_BUCKET * -0.1980)
    + (OLDCLAIM * -0.00002)
    + (HAS_CLMD * 0.6282)
    + (MVR_PTS * 0.0999)
    + (IMP_INCOME_BUCKET * -0.1603)
    + (IMP_HOME_VAL * -0.00000134)
    ;
    
if LOG_P_TARGET > 20  then LOG_P_TARGET = 20;
if LOG_P_TARGET < -20 then LOG_P_TARGET = -20;

exp_transform = exp(LOG_P_TARGET);
P_TARGET_FLAG = (exp_transform / ( 1+exp_transform));


KEEP INDEX;
KEEP P_TARGET_FLAG;

run;


proc print data=BUCKETSCORE(obs=5);
run;

proc means data=BUCKETSCORE n nmiss;
run; quit;

libname scrlib "/home/taylorvender20180/my_courses/PRED411/UNIT02";

data scrlib.VENDERinsurance_BUCKETSCORE2;
set BUCKETSCORE;
run;

proc export data=scrlib.VENDERinsurance_BUCKETSCORE2 DBMS=csv outfile='/home/taylorvender20180/my_courses/PRED411/UNIT02/VENDERinsurance_BUCKETSCORE2.csv' replace;
run;

TITLE 'bucketfile with stepwise selection, buckets as categorical variables';

data CATBUCKETSCORE;
set &LIB.logit_insurance_test;

IMP_AGE = AGE;
if missing( IMP_AGE ) then IMP_AGE = 45.0;

IMP_YOJ = YOJ;
if missing( YOJ ) then IMP_YOJ = 11.0;

IMP_INCOME = INCOME;
if missing( INCOME ) then do;
	IMP_INCOME = 62000.00;
	if IMP_HOME_VAL < 278000.00 then IMP_INCOME = 49000.00;
	if IMP_HOME_VAL < 278000.00 AND (JOB = 'Home Maker' or JOB = 'Student')
	then IMP_INCOME = 8539.00;
	if IMP_HOME_VAL < 278000.00 AND JOB = 'Clerical' then IMP_INCOME = 34000.00;
	if IMP_HOME_VAL < 278000.00 AND JOB not in('Home Maker','Student','Clerical') AND 
	EDUCATION in('<High School','z_High School') then IMP_INCOME = 49000.00;
	if IMP_HOME_VAL < 278000.00 AND JOB not in('Home Maker','Student','Clerical')
	AND EDUCATION not in('<High School','z_High School') then IMP_INCOME = 72000.00;
	
	if 41000.00>IMP_HOME_VAL >= 278000.00 then IMP_INCOME = 114000.00;
	if 523000.00> IMP_HOME_VAL >= 411000.00 then IMP_INCOME = 179000.00;
	if IMP_HOME_VAL>=523000.00 then IMP_INCOME = 242000.00;
end;
	


IMP_HOME_VAL = HOME_VAL;
if missing ( HOME_VAL ) then IMP_HOME_VAL = 161159.53;

IMP_CAR_AGE = CAR_AGE;
if missing ( CAR_AGE ) then IMP_CAR_AGE = 8.0;


IMP_JOB = JOB;
if missing(IMP_JOB) then do;
	IMP_JOB = "z_Blue Collar";
	if EDUCATION = "PhD" then IMP_JOB = "Doctor";
	if EDUCATION = "Masters" and IMP_INCOME < 15000.00 then 
		IMP_JOB = "Home Maker";	
	if EDUCATION = "Masters" and IMP_INCOME > 15000.00 then 
		IMP_JOB = "Lawyer";
	if EDUCATION not in("Masters", "PhD") and IMP_INCOME < 15000.00 then
		IMP_JOB = "Student";
	if EDUCATION not in("Masters", "PhD") and 15000.00< IMP_INCOME < 45000.00 then
		IMP_JOB = "Clerical";	
	if EDUCATION not in("Masters", "PhD") and IMP_INCOME > 45000.00 then
		IMP_JOB = "z_Blue Collar";	
end;

	CAP_IMP_INCOME = IMP_INCOME;
	IF IMP_INCOME > 217269.4 then CAP_IMP_INCOME = 217269.4;


	        
	BLUEBOOK_BUCKET = BLUEBOOK;
   	if BLUEBOOK < 9280 then BLUEBOOK_BUCKET = 1; *25th;
        else if BLUEBOOK < 14440 then BLUEBOOK_BUCKET = 2; *50th;
        else if BLUEBOOK < 20850 then BLUEBOOK_BUCKET = 3; *75th;
        else BLUEBOOK_BUCKET = 4;
     
     TIF_BUCKET = TIF;
     if TIF = 1 then TIF_BUCKET = 1; *25th;
     	else if TIF <= 4 then TIF_BUCKET = 2; *50th;
     	else if TIF <= 7 then TIF_BUCKET = 3; *75th;
     	else TIF_BUCKET = 4;

	IMP_INCOME_BUCKET = IMP_INCOME;
    if IMP_INCOME < 28300.00 then IMP_INCOME_BUCKET = 1; *25th;
        else if IMP_INCOME < 53600.00 then IMP_INCOME_BUCKET = 2; *50th;
        else if IMP_INCOME < 83300.00 then IMP_INCOME_BUCKET = 3; *75th;
        else IMP_INCOME_BUCKET = 4;
	
	HAS_CLMD = CLM_FREQ;
    if CLM_FREQ = 0 then HAS_CLMD = 0;
		else HAS_CLMD = 1;

		drop BLUEBOOK;
		drop TIF;
		drop IMP_INCOME;
		drop CLM_FREQ;
		drop AGE;
		drop YOJ;
		drop INCOME;
		drop HOME_VAL;
		drop CAR_AGE;
		drop JOB;
		drop RED_CAR;
		
LOG_P_TARGET = -2.9907
	+ ((CAR_TYPE in ("Minivan")) * -0.7087)
    + ((CAR_TYPE in ("Panel Truck")) * -0.2132)
    + ((CAR_TYPE in ("Pickup")) * -0.1762)
    + ((CAR_TYPE in ("Sports Car")) * 0.2552)
    + ((CAR_TYPE in ("Van")) * -0.0936)
    + ((CAR_USE in ("Commercial")) * 0.7688)
    + ((EDUCATION in ("<High School")) * -0.00780)
    + ((EDUCATION in ("Bachelors")) * -0.3896)
    + ((EDUCATION in ("Masters")) * -0.3361)
    + ((EDUCATION in ("PhD")) * -0.0373)
    + ((IMP_JOB in ("Clerical")) * 0.0796)
    + ((IMP_JOB in ("Doctor")) * -0.8154)
    + ((IMP_JOB in ("Home Maker")) * -0.0539)
    + ((IMP_JOB in ("Lawyer")) * -0.1687)
    + ((IMP_JOB in ("Manager")) * -0.88423)
    + ((IMP_JOB in ("Professional")) * -0.1425)
    + ((IMP_JOB in ("Student")) * -0.0318)
    + ((MSTATUS in ("Yes")) * -0.4742)
    + ((PARENT1 in ("No")) * -0.4643)
    + ((REVOKED in ("No")) * -0.9574)
    + ((URBANICITY in ("Highly Urban/ Urban")) * 2.3544)
    + (KIDSDRIV * 0.4127)
    + (TRAVTIME * 0.0146)
    + ((BLUEBOOK_BUCKET in ("1")) * 0.4464)
    + ((BLUEBOOK_BUCKET in ("2")) * 0.2227)
    + ((BLUEBOOK_BUCKET in ("3")) * 0.1728)
    + ((TIF_BUCKET in ("1")) * 0.5777)
    + ((TIF_BUCKET in ("2")) * 0.3772)
    + ((TIF_BUCKET in ("3")) * 0.1403)
    + (OLDCLAIM * -0.00002)
    + (HAS_CLMD * 0.6267)
    + (MVR_PTS * 0.0998)
    + ((IMP_INCOME_BUCKET in ("1"))* 0.5067)
    + ((IMP_INCOME_BUCKET in ("1"))* 0.3969)
    + ((IMP_INCOME_BUCKET in ("1"))* 0.3512)
    + (IMP_HOME_VAL * -0.00000128)
    ;
    
if LOG_P_TARGET > 20  then LOG_P_TARGET = 20;
if LOG_P_TARGET < -20 then LOG_P_TARGET = -20;

exp_transform = exp(LOG_P_TARGET);
P_TARGET_FLAG = (exp_transform / ( 1+exp_transform));


KEEP INDEX;
KEEP P_TARGET_FLAG;

run;


proc print data=CATBUCKETSCORE(obs=5);
run;

proc means data=CATBUCKETSCORE n nmiss;
run; quit;

libname scrlib "/home/taylorvender20180/my_courses/PRED411/UNIT02";

data scrlib.VENDERinsurance_CATBUCKETSCORE;
set CATBUCKETSCORE;
run;

proc export data=scrlib.VENDERinsurance_CATBUCKETSCORE DBMS=csv outfile='/home/taylorvender20180/my_courses/PRED411/UNIT02/VENDERinsurance_CATBUCKETSCORE.csv' replace;
run;


TITLE 'MODEL using original scrubfile and stepwise selction';
data SCOREFILE;
set &LIB.logit_insurance_test;

IMP_AGE = AGE;
if missing( IMP_AGE ) then IMP_AGE = 45.0;

IMP_YOJ = YOJ;
if missing( YOJ ) then IMP_YOJ = 11.0;

IMP_INCOME = INCOME;
if missing( INCOME ) then do;
	IMP_INCOME = 62000.00;
	if IMP_HOME_VAL < 278000.00 then IMP_INCOME = 49000.00;
	if IMP_HOME_VAL < 278000.00 AND (JOB = 'Home Maker' or JOB = 'Student')
	then IMP_INCOME = 8539.00;
	if IMP_HOME_VAL < 278000.00 AND JOB = 'Clerical' then IMP_INCOME = 34000.00;
	if IMP_HOME_VAL < 278000.00 AND JOB not in('Home Maker','Student','Clerical') AND 
	EDUCATION in('<High School','z_High School') then IMP_INCOME = 49000.00;
	if IMP_HOME_VAL < 278000.00 AND JOB not in('Home Maker','Student','Clerical')
	AND EDUCATION not in('<High School','z_High School') then IMP_INCOME = 72000.00;
	
	if 41000.00>IMP_HOME_VAL >= 278000.00 then IMP_INCOME = 114000.00;
	if 523000.00> IMP_HOME_VAL >= 411000.00 then IMP_INCOME = 179000.00;
	if IMP_HOME_VAL>=523000.00 then IMP_INCOME = 242000.00;
end;
	


IMP_HOME_VAL = HOME_VAL;
if missing ( HOME_VAL ) then IMP_HOME_VAL = 161159.53;

IMP_CAR_AGE = CAR_AGE;
if missing ( CAR_AGE ) then IMP_CAR_AGE = 8.0;


IMP_JOB = JOB;
if missing(IMP_JOB) then do;
	IMP_JOB = "z_Blue Collar";
	if EDUCATION = "PhD" then IMP_JOB = "Doctor";
	if EDUCATION = "Masters" and IMP_INCOME < 15000.00 then 
		IMP_JOB = "Home Maker";	
	if EDUCATION = "Masters" and IMP_INCOME > 15000.00 then 
		IMP_JOB = "Lawyer";
	if EDUCATION not in("Masters", "PhD") and IMP_INCOME < 15000.00 then
		IMP_JOB = "Student";
	if EDUCATION not in("Masters", "PhD") and 15000.00< IMP_INCOME < 45000.00 then
		IMP_JOB = "Clerical";	
	if EDUCATION not in("Masters", "PhD") and IMP_INCOME > 45000.00 then
		IMP_JOB = "z_Blue Collar";	
end;

CAP_IMP_INCOME = IMP_INCOME;
IF IMP_INCOME > 217269.4 then CAP_IMP_INCOME = 217269.4;


drop AGE;
drop YOJ;
drop INCOME;
drop HOME_VAL;
drop CAR_AGE;
drop JOB;
drop RED_CAR;

LOG_P_TARGET = -1.3399   
    + (BLUEBOOK * -0.00002)
    + ((CAR_TYPE in ("Minivan")) * -0.7165)
    + ((CAR_TYPE in ("Panel Truck")) * -0.1055)
    + ((CAR_TYPE in ("Pickup")) * -0.1641)
    + ((CAR_TYPE in ("Sports Car")) * 0.2583)
    + ((CAR_TYPE in ("Van")) * -0.0646)
    + ((CAR_USE in ("Commercial")) * 0.7753)
    + ((EDUCATION in ("<High School")) * -0.0125)
    + ((EDUCATION in ("Bachelors")) * -0.3962)
    + ((EDUCATION in ("Masters")) * -0.3675)
    + ((EDUCATION in ("PhD")) * -0.0129)
    + ((MSTATUS in ("Yes")) * -0.4787)
    + ((PARENT1 in ("No")) * -0.4585)
    + ((REVOKED in ("No")) * -0.8920)
    + ((URBANICITY in ("Highly Urban/ Urban")) * 2.3924)
    + ((IMP_JOB in ("Clerical")) * 0.1014)
    + ((IMP_JOB in ("Doctor")) * -0.7744)
    + ((IMP_JOB in ("Home Maker")) * -0.0586)
    + ((IMP_JOB in ("Lawyer")) * -0.1508)
    + ((IMP_JOB in ("Manager")) * -0.8679)
    + ((IMP_JOB in ("Professional")) * -0.1353)
    + ((IMP_JOB in ("Student")) * -0.0580)
    + (KIDSDRIV * 0.4196)
    + (TRAVTIME * 0.0144)
    + (TIF * -0.05533)
    + (OLDCLAIM * -0.00001)
    + (CLM_FREQ * 0.1961)
    + (MVR_PTS * 0.1148)
    + (CAP_IMP_INCOME * -0.00000399)
    + (IMP_HOME_VAL * -0.0000013)
    ;
  
if LOG_P_TARGET > 20 then LOG_P_TARGET = 20;
if LOG_P_TARGET < -20 then LOG_P_TARGET = -20;

exp_transform = exp(LOG_P_TARGET);
P_TARGET_FLAG = (exp_transform / ( 1+exp_transform));


KEEP INDEX;
KEEP P_TARGET_FLAG;

run;


proc print data=SCOREFILE(obs=5);
run;

proc means data=SCOREFILE n nmiss;
run; quit;

libname scrlib "/home/taylorvender20180/my_courses/PRED411/UNIT02";

data scrlib.VENDERinsuranceHW_scoreFile2;
set SCOREFILE;
run;

proc export data=scrlib.VENDERinsuranceHW_scoreFile2 DBMS=csv outfile='/home/taylorvender20180/my_courses/PRED411/UNIT02/VENDERinsuranceHW_scoreFile2.csv' replace;
run;


   