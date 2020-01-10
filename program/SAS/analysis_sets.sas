**************************************************************************
Program Name : analysis_sets.sas
Study Name : NHOD-SBC
Author : Ohtsuka Mariko
Date : 2020-01-09
SAS version : 9.4
**************************************************************************;
* Load analysis target group from EXCEL file;
options noxwait noxsync;
%sysexec "&projectpath.\document\&saihi_input.";
data _NULL_;
  rc = sleep(5);
run;

%let temp_setfile="excel|[&saihi_input.]&saihi_input_range.";
filename EXC dde &temp_setfile.;

data saihi;
    attrib
        subjid format=best12.
        analysis_set length=$30.
        efficacy format=best12.
        safety format=best12.
        analysis_group length=$24.;
    infile EXC notab dlm="09"x dsd lrecl=5000;
    input subjid analysis_set efficacy safety;
    if substr(analysis_set, 1, 8)='é°ñ¸êÿèú' then do;
        analysis_group=&ope_group.;
    end;
    else if substr(analysis_set, 1, 10)='é°ñ¸ñ¢êÿèú' then do;
        analysis_group=&non_ope_group.;
    end;
run;
proc sort data=saihi; by subjid; run;

data _NULL_;
    put '[close(false)]';
    put '[quit()]';
run;

* Load ptdata and merge with analysis target group information;
data ptdata;
    set libads.ptdata;
    temp_subjid=input(subjid, best12.);
    drop subjid;
    rename temp_subjid=subjid;
run;
data ptdata;
    merge ptdata saihi;
    by subjid;
run;

* Get variable information of ptdata;
proc contents data=ptdata out=temp_ptdata_contents varnum noprint; run;
data ptdata_contents;
    set temp_ptdata_contents(rename=(FORMAT=temp_format));
    attrib FORMAT label="ïœêîèoóÕå`éÆ" length=$32 format=$32.;
    if type=1 & temp_format='' then do;
        FORMAT = "$";
    end;
    else do;
        FORMAT= temp_format;
    end;
run;

* 5.1. Breakdown of analysis target group (registration example);
proc sql noprint;
    create table ds_N (Item char(200), Category char(200), count num, percent num);
    select count(*) into: count_n from ptdata;
    insert into ds_N values('âêÕëŒè€èWícÇÃì‡ñÛ', 'ìoò^êî', &count_n., 100);
quit;

%EXEC_FREQ(ptdata, efficacy, efficacy);
%EXEC_FREQ(ptdata, analysis_set, analysis_set);
%EXEC_FREQ(ptdata, analysis_group, analysis_group);

data analysis; 
    set analysis_set(rename=(analysis_set=analysis))
        analysis_group(rename=(analysis_group=analysis));
run;

%INSERT_SQL(efficacy, ds_N, %str('', &efficacy_group., count, percent), %str(efficacy=1));
%INSERT_SQL(analysis, ds_N, %str('', &ope_group., count, percent), %str(analysis=)&ope_group.);
%INSERT_SQL(analysis, ds_N, %str('', &ope_chemo., count, percent), %str(analysis=)&ope_chemo.);
%INSERT_SQL(analysis, ds_N, %str('', &ope_non_chemo., count, percent), %str(analysis=)&ope_non_chemo.);
%INSERT_SQL(analysis, ds_N, %str('', &non_ope_group., count, percent), %str(analysis=)&non_ope_group.);
%INSERT_SQL(analysis, ds_N, %str('', &non_ope_chemo., count, percent), %str(analysis=)&non_ope_chemo.);
%INSERT_SQL(analysis, ds_N, %str('', &non_ope_non_chemo., count, percent), %str(analysis=)&non_ope_non_chemo.);

%ds2csv (data=ds_N, runmode=b, csvfile=&outpath.\_5_1_n.csv, labels=N);

* Delete the working dataset;
proc datasets lib=work nolist; save ptdata ds_n ptdata_contents; quit;
