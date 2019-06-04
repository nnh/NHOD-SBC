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

proc freq data=ptdata noprint;
 	tables dsdecod*analysis_set/ missing out=cancel;
run;
*中止理由;
%INSERT_SQL(ptdata, ds_N, '中止理由', '', dsterm, 0, %str(dsterm^=.));
