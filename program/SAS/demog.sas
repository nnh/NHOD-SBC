**************************************************************************
Program Name : demog.sas
Study Name : NHOD-SBC
Author : Ohtsuka Mariko
Date : 2019-06-05
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
proc means data=ptdata noprint;
	class analysis_set;
    var age;
    output out=age n=n mean=mean std=std median=median q1=q1 q3=q3 min=min max=max;
run;

proc freq data=ptdata noprint;
 	tables analysis_set*crohnyn/ missing out=crohnyn;
run;

%CREATE_OUTPUT_DS(ds_demog, 30, 30, '背景と人口統計学的特性');

%macro MEANS_FUNC(input_ds, title, cat_var, var_var, output_ds);
	%local select_str columns;
	%let columns = %str(n=n mean=temp_mean std=temp_std median=median q1=q1 q3=q3 min=min max=max);
	/* Calculation of summary statistics (overall) */
	proc means data=&input_ds. noprint;
		var &var_var.;
		output out=temp_all_ds &columns.;
	run;
	data temp_all_ds;
		set temp_all_ds;
		format analysis_set $100.; 
		analysis_set=&all_group.;
	run;
	/* Calculation of summary statistics */
	proc means data=&input_ds. noprint;
		class &cat_var.;
		var &var_var.;
		output out=temp_ds  &columns.;
	run;
	/* Round mean and std, remove variable labels */
	data temp_ds;
		set temp_all_ds temp_ds;
		mean=round(temp_mean, 0.1);
		std=round(temp_std, 0.1);
		attrib _ALL_ label=" ";
	run;
	/* Sort observations */
	proc sql;
		create table temp_means like temp_ds;
		insert into temp_means select * from temp_ds where &cat_var.=&all_group.;
		insert into temp_means set &cat_var.='dummy';
		insert into temp_means select * from temp_ds where &cat_var.=&ope_non_chemo. ;
		insert into temp_means set &cat_var.='dummy'; 
		insert into temp_means select * from temp_ds where &cat_var.=&ope_chemo. ;
		insert into temp_means set &cat_var.='dummy';  
		insert into temp_means select * from temp_ds where &cat_var.=&non_ope_non_chemo. ;
		insert into temp_means set &cat_var.='dummy';  
		insert into temp_means select * from temp_ds where &cat_var.=&non_ope_chemo. ; 
		insert into temp_means set &cat_var.='dummy'; 
	quit;
	proc transpose data=temp_means out=tran_means;
		var n mean std median q1 q3 min max;
	run;
	/* Set title only on the first line */
	proc sql;
		insert into ds_demog select &title., * from tran_means where _NAME_='n';
		insert into ds_demog select '', * from tran_means where _NAME_ NE 'n';
	quit;
%mend;
%means_func(ptdata, '年齢', analysis_set, age, age);
