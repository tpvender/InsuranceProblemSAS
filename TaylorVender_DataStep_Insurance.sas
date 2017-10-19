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