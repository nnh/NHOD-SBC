**************************************************************************
Program Name : cancel.sas
Study Name : NHOD-SBC
Author : Ohtsuka Mariko
Date : 2019-06-04
SAS version : 9.4
**************************************************************************;
*Define constants;
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
%inc "&projectpath.\program\sas\analysis_sets.sas";
**************************************************************************;
*症例の内訳と中止例集計;
proc sql;
	create table ds_cancel (
		ope_non_chemo_cnt num label='治癒切除・non-chemo 度数',
		ope_non_chemo_per num label='治癒切除・non-chemo パーセント',
		ope_chemo_cnt num label='治癒切除・chemo 度数',
		ope_chemo_per num label='治癒切除・chemo パーセント',
		non_ope_non_chemo_cnt num label='治癒未切除・non-chemo 度数',
		non_ope_non_chemo_per num label='治癒未切除・non-chemo パーセント',
		non_ope_chemo_cnt num label='治癒未切除・chemo 度数',
		non_ope_chemo_per num label='治癒未切除・chemo パーセント');
quit;

proc sql;
	create table ds_reasons_for_withdrawal(
		reasons num label='中止理由');
quit;

proc freq data=ptdata noprint;
 	tables dsdecod*analysis_set/ missing out=cancel;
run;

%macro TEST;
	proc sql noprint;
		select count(*) from cancel where dsdecod=1;
	quit;
	%if &sqlobs.=1 %then %do;
		
	%end;
	%else %do;
		%return;
	%end;
	proc sql;
		insert into ds_cancel
		values(111,2,3,4,5,6,7,8); 
	quit;
%mend TEST;
%test;

%INSERT_SQL(ptdata, ds_reasons_for_withdrawal, %str(dsterm), %str(dsterm^=.));
