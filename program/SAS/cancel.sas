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
		items char(6) label='',
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

%macro INSERT_CANCEL(input_ds, output_ds);
	%local str_item cnt1 cnt2 cnt3 cnt4 per1 per2 per3 per4;
	proc sql noprint;
		select count(*) from &input_ds. where dsdecod=1;
	quit;
	%if &sqlobs.=1 %then %do;
		data temp_ds;
			set &input_ds.;
			format str_dsdecod $6.;
			where dsdecod=1;
			str_dsdecod=cat(put(dsdecod, FMT_9_F.), '例');
		run;	
		proc sql noprint;
			select distinct str_dsdecod into:str_item from temp_ds;
			select count into:cnt1 from temp_ds where analysis_set=&ope_non_chemo.;
			select count into:cnt2 from temp_ds where analysis_set=&ope_chemo.;
			select count into:cnt3 from temp_ds where analysis_set=&non_ope_non_chemo.;
			select count into:cnt4 from temp_ds where analysis_set=&non_ope_chemo.;
			select percent into:per1 from temp_ds where analysis_set=&ope_non_chemo.;
			select percent into:per2 from temp_ds where analysis_set=&ope_chemo.;
			select percent into:per3 from temp_ds where analysis_set=&non_ope_non_chemo.;
			select percent into:per4 from temp_ds where analysis_set=&non_ope_chemo.;
		quit;
	%end;
	%else %do;
		%return;
	%end;
	proc sql;
		insert into &output_ds.
		values("&str_item.", &cnt1., &per1., &cnt2., &per2. ,&cnt3., &per3. ,&cnt4., &per4.); 
	quit;
%mend INSERT_CANCEL;
%INSERT_CANCEL(cancel, ds_cancel);

proc contents data=ds_cancel out=VARS1 varnum noprint;
run;
%INSERT_SQL(ptdata, ds_reasons_for_withdrawal, %str(dsterm), %str(dsterm^=.));
