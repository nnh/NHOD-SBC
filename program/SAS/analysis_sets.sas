**************************************************************************
Program Name : analysis_sets.sas
Study Name : NHOD-SBC
Author : Ohtsuka Mariko
Date : 2019-05-30
SAS version : 9.4
**************************************************************************;
proc datasets library=work kill nolist; quit;

options mprint mlogic symbolgen minoperator noautocorrect;
*saihi.csv;
%let input_csv=test.csv;
%let str_t1='¡–üØœ‚Ì‰ğÍ‘ÎÛW’c';
%let str_t2='¡–üØœEChemotherapyŒQ';
%let str_t3='¡–üØœEnon-ChemotherapyŒQ';
%let str_t4='¡–ü–¢Øœ‚Ì‰ğÍ‘ÎÛW’c';
%let str_t5='¡–ü–¢ØœEChemotherapyŒQ';
%let str_t6='¡–ü–¢ØœEnon-ChemotherapyŒQ';
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

%macro INSERT_SQL(input_ds, output_ds, item, cat, cnt, per, cond_var, cond_str);
	%local sql_str;
	%let sql_str=%str(select &item., &cat., &cnt., &per. from &input_ds.);
	%if &cond_var.^=. %then %do;
		%let sql_str=&sql_str.%str( where &cond_var. = &cond_str.);
	%end;
	proc sql;
		insert into &output_ds.
		&sql_str.; 
	quit;
%mend INSERT_SQL;

**************************************************************************;
%let thisfile=%GET_THISFILE_FULLPATH;
%let projectpath=%GET_DIRECTORY_PATH(&thisfile., 3);
%let extpath=&projectpath.\input\ext;
%let outpath=&projectpath.\output;
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
	if substr(VAR2, 1, 8)='¡–üØœ' then do;
		analysis_group=&str_t1.;
	end;
	else if substr(VAR2, 1, 10)='¡–ü–¢Øœ' then do;
		analysis_group=&str_t4.;
	end;
    drop VAR1;
run;

proc sort data=saihi; by subjid; run;

proc sql;
	create table ds_N (
		Item char(200) ,
		Category char(200),
		count num,
		percent num);
quit;

proc sql noprint;
	select count(*) into: count_n from saihi;
	insert into ds_N
		values('‰ğÍ‘ÎÛW’c‚Ì“à–ó', '“o˜^”', &count_n., 100);
quit;

proc freq data=saihi noprint;
 	tables efficacy/ missing out=efficacy;
run;

proc freq data=saihi noprint;
 	tables analysis_set/ missing out=analysis_set;
run;

proc freq data=saihi noprint;
 	tables analysis_group/ missing out=analysis_group;
run;

data analysis; 
	set 	analysis_set(rename=(analysis_set=analysis))
			analysis_group(rename=(analysis_group=analysis));
run;

%INSERT_SQL(efficacy, ds_N, '', '—LŒø«‰ğÍ‘ÎÛW’c', count, percent, efficacy, 1);
%INSERT_SQL(analysis, ds_N, '', &str_t1., count, percent, analysis, &str_t1.);
%INSERT_SQL(analysis, ds_N, '', &str_t2., count, percent, analysis, &str_t2.);
%INSERT_SQL(analysis, ds_N, '', &str_t3., count, percent, analysis, &str_t3.);
%INSERT_SQL(analysis, ds_N, '', &str_t4., count, percent, analysis, &str_t4.);
%INSERT_SQL(analysis, ds_N, '', &str_t5., count, percent, analysis, &str_t5.);
%INSERT_SQL(analysis, ds_N, '', &str_t6., count, percent, analysis, &str_t6.);

%ds2csv (data=ds_N, runmode=b, csvfile=&outpath.\N.csv, labels=N);

*Delete the working dataset;
proc datasets lib=work nolist; save ds_n; quit;




