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
%CREATE_OUTPUT_DS(output_ds=cancel, items_label='è«ó·ÇÃì‡ñÛÇ∆íÜé~ó·èWåv');
data ds_cancel;
	set cancel;
	drop all_cnt all_per title;
run;

proc sql;
	create table ds_reasons_for_withdrawal(
		reasons num label='íÜé~óùóR');
quit;

proc freq data=ptdata noprint;
 	tables dsdecod*analysis_set/ missing out=cancel;
run;

%macro INSERT_CANCEL(input_ds, output_ds, cond);
	%local str_item cnt1 cnt2 cnt3 cnt4 per1 per2 per3 per4;
	proc sql noprint;
		select * from &input_ds. where dsdecod=&cond.;
	quit;
	%put &sqlobs.; 
	%if &sqlobs.=1 %then %do;
		data temp_ds;
			set &input_ds.;
			format str_dsdecod $6.;
			where dsdecod=&cond.;
			str_dsdecod=cat(put(dsdecod, FMT_9_F.), 'ó·');
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
			insert into &output_ds.
			values("&str_item.", &cnt1., &per1., &cnt2., &per2. ,&cnt3., &per3. ,&cnt4., &per4.); 
		quit;
	%end;
%mend INSERT_CANCEL;

%INSERT_CANCEL(cancel, ds_cancel, 1);
%INSERT_CANCEL(cancel, ds_cancel, 2);
%INSERT_SQL(ptdata, ds_reasons_for_withdrawal, %str(dsterm), %str(dsterm^=.));

*Delete the working dataset;
proc datasets lib=work nolist; delete cancel temp_ds; run; quit;
