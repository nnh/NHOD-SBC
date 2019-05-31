**************************************************************************
Program Name : analysis_sets.sas
Study Name : NHOD-SBC
Author : Ohtsuka Mariko
Date : 2019-05-30
SAS version : 9.4
**************************************************************************;
proc datasets library=work kill nolist; quit;

options mprint mlogic symbolgen minoperator noautocorrect;
*Define constants;
%let template_ds_name=%str(Output_ds_template);
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

%macro INSERT_COUNT_N(input_ds, input_var, condition_string, item_name, percent_n, output_ds);
	%local temp_ds output_ds;
	%let temp_ds=&input_ds._&input_var.;
	%let output_freq=&input_var.;
	*Create a dataset if it does not exist;
	%if %sysfunc(exist(&output_ds.))=0 %then %do;
		data &output_ds.;
			set  &template_ds_name.;
		run;
	%end;
	data &temp_ds.;
		set &input_ds.;
		if &input_var.=&condition_string.;
	run;
	*Count;
	proc freq data=&temp_ds. noprint;
    tables &input_var. / out=&output_freq.;
	run;
	proc sql;
	insert into &output_ds. (Item, Category, count, percent)
		select &item_name., '', count, ((count / &count_n.) * 100) from &output_freq.;
	quit;
%mend INSERT_COUNT_N;

**************************************************************************;
%let thisfile=%GET_THISFILE_FULLPATH;
%let projectpath=%GET_DIRECTORY_PATH(&thisfile., 3);
%let extpath=&projectpath.\input\ext;
%let outpath=&projectpath.\output;
*saihi.csv;
%let input_csv=test.csv;
**************************************************************************;
proc import datafile="&extpath.\&input_csv."
                    out=saihi
                    dbms=csv replace;
run;

data saihi;
    set saihi;
    SUBJID=input(VAR1, best12.);
	rename VAR2=ANALYSIS_SET VAR3=EFFICACY VAR4=SAFETY;
    drop VAR1;
run;

proc sort data=saihi; by SUBJID; run;

proc sql;
	create table &template_ds_name. (
		Item char(200) ,
		Category char(10),
		count num,
		percent num
	);
quit;

data ds_N;
	set &template_ds_name.;
run;

proc sql;
	select count(*) into: count_n from saihi;
	insert into ds_N
		values('�o�^��', 'N', &count_n., 0);
quit;

%INSERT_COUNT_N(saihi,  EFFICACY, 1,  '�L������͑ΏۏW�c', &count_n., ds_N)
%INSERT_COUNT_N(saihi,  ANALYSIS_SET, '�����؏��Enon-Chemotherapy�Q',  '�����؏��Enon-Chemotherapy�Q', & count_n., saihi_ope)
%INSERT_COUNT_N(saihi,  ANALYSIS_SET, '�����؏��EChemotherapy�Q',  '�����؏��EChemotherapy�Q', & count_n., saihi_ope)
proc sql;
	insert into ds_N
	select '�����؏��̉�͑ΏۏW�c', '', sum(count), (sum(count) / &count_n.) * 100 from saihi_ope;
quit;
data ds_N;
	set ds_N saihi_ope;
run;
%INSERT_COUNT_N(saihi,  ANALYSIS_SET, '�������؏��Enon-Chemotherapy�Q',  '�������؏��Enon-Chemotherapy�Q', & count_n., saihi_non_ope)
%INSERT_COUNT_N(saihi,  ANALYSIS_SET, '�������؏��EChemotherapy�Q',  '�������؏��EChemotherapy�Q', & count_n., saihi_non_ope)
proc sql;
	insert into ds_N
	select '�������؏��̉�͑ΏۏW�c', '', sum(count), (sum(count) / &count_n.) * 100 from saihi_non_ope;
quit;
data ds_N;
	set ds_N saihi_non_ope;
run;

%ds2csv (data=ds_N, runmode=b, csvfile=&outpath.\N.csv, labels=N);

*Delete the working dataset;
proc datasets lib=work nolist; save ds_n; quit;
