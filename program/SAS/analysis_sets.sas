**************************************************************************
Program Name : analysis_sets.sas
Study Name : NHOD-SBC
Author : Ohtsuka Mariko
Date : 2019-05-30
SAS version : 9.4
**************************************************************************;
*Define constants;
*saihi.csv;
%let input_csv=test.csv;
**************************************************************************;
*Define macros;
%macro GET_THISFILE_FULLPATH;
    %local _fullpath _path;
    %let _fullpath=;
    %let _path=;

    %if %length(%sysfunc(getoption(sysin)))=0 %then
      %let _fullpath=%sysget(sas_execfilepath);
    %else
      %let _fullpath=%sysfunc(getoption(sysin));
    &_fullpath.
%mend GET_THISFILE_FULLPATH;

%macro GET_DIRECTORY_PATH(input_path, directory_level);
	%let input_path_len=%length(&input_path.);
	%let temp_path=&input_path.;
	%do i = 1 %to &directory_level.;
		%let temp_len=%scan(&temp_path., -1, '\');
		%let temp_path=%substr(&temp_path., 1, %length(&temp_path.)-%length(&temp_len.)-1);
		%put &temp_path.;
	%end;
	%let _path=&temp_path.;
    &_path.
%mend GET_DIRECTORY_PATH;

**************************************************************************;
%let thisfile=%GET_THISFILE_FULLPATH;
%let projectpath=%GET_DIRECTORY_PATH(&thisfile., 3);
%inc "&projectpath.\program\macro\libname.sas";
**************************************************************************;
proc import datafile="&extpath.\&input_csv."
                    out=saihi
                    dbms=csv replace;
run;

data saihi;
    set saihi;
    subjid=input(VAR1, best12.);
	rename VAR2=analysis_set VAR3=efficacy VAR4=safety;
	format analysis_group  $24.;
	if substr(VAR2, 1, 8)='é°ñ¸êÿèú' then do;
		analysis_group=&ope_group.;
	end;
	else if substr(VAR2, 1, 10)='é°ñ¸ñ¢êÿèú' then do;
		analysis_group=&non_ope_group.;
	end;
    drop VAR1;
run;

proc sort data=saihi; by subjid; run;

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

proc sql;
	create table ds_N (
		Item char(200) ,
		Category char(200),
		count num,
		percent num);
quit;

proc sql noprint;
	select count(*) into: count_n from ptdata;
	insert into ds_N
		values('âêÕëŒè€èWícÇÃì‡ñÛ', 'ìoò^êî', &count_n., 100);
quit;

proc freq data=ptdata noprint;
 	tables efficacy/ missing out=efficacy;
run;

proc freq data=ptdata noprint;
 	tables analysis_set/ missing out=analysis_set;
run;

proc freq data=ptdata noprint;
 	tables analysis_group/ missing out=analysis_group;
run;

data analysis; 
	set 	analysis_set(rename=(analysis_set=analysis))
			analysis_group(rename=(analysis_group=analysis));
run;

%INSERT_SQL(efficacy, ds_N, %str('', 'óLå¯ê´âêÕëŒè€èWíc', count, percent), %str(efficacy=1));
%INSERT_SQL(analysis, ds_N, %str('', &ope_group., count, percent), %str(analysis=)&ope_group.);
%INSERT_SQL(analysis, ds_N, %str('', &ope_chemo., count, percent), %str(analysis=)&ope_chemo.);
%INSERT_SQL(analysis, ds_N, %str('', &ope_non_chemo., count, percent), %str(analysis=)&ope_non_chemo.);
%INSERT_SQL(analysis, ds_N, %str('', &non_ope_group., count, percent), %str(analysis=)&non_ope_group.);
%INSERT_SQL(analysis, ds_N, %str('', &non_ope_chemo., count, percent), %str(analysis=)&non_ope_chemo.);
%INSERT_SQL(analysis, ds_N, %str('', &non_ope_non_chemo., count, percent), %str(analysis=)&non_ope_non_chemo.);

%ds2csv (data=ds_N, runmode=b, csvfile=&outpath.\N.csv, labels=N);

*Delete the working dataset;
proc datasets lib=work nolist; save ptdata ds_n; quit;



