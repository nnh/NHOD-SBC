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

%macro EDIT_DS_ALL(ds=temp_all_ds, cat_var=analysis_set, char_len=100, cat_str=&all_group.);
	data &ds.;
		set &ds.;
		format &cat_var. $&char_len..; 
		&cat_var.=&cat_str.;
	run;
%mend EDIT_DS_ALL;

%macro MEANS_FUNC(input_ds=ptdata, title='', cat_var=analysis_set, var_var='', output_ds=ds_demog);
	%local select_str columns;
	%let columns = %str(n=n mean=temp_mean std=temp_std median=median q1=q1 q3=q3 min=min max=max);
	/* Calculation of summary statistics (overall) */
	proc means data=&input_ds. noprint;
		var &var_var.;
		output out=temp_all_ds &columns.;
	run;
	%EDIT_DS_ALL;
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
		insert into &output_ds. select &title., * from tran_means where _NAME_='n';
		insert into &output_ds. select '', * from tran_means where _NAME_ NE 'n';
	quit;
	/* Delete the working dataset */
	proc datasets lib=work nolist; delete temp_all_ds temp_ds temp_means tran_means; run; quit;

%mend;
%macro FREQ_FUNC(input_ds=ptdata, title='', cat_var=analysis_set, var_var='', output_ds=ds_demog);
	proc freq data=&input_ds. noprint;
		tables &var_var./missing out=temp_all_ds;
	run;
	%EDIT_DS_ALL;
	proc freq data=&input_ds. noprint;
		tables &cat_var.*&var_var./missing out=temp_ds;
	run;
	data temp_ds;
		set temp_all_ds temp_ds;
		temp_per=round(percent, 0.1);
		drop percent;
		rename temp_per=percent;
	run;
	
	proc sql noprint;
		create table ds_all_group as select &var_var., count, percent from temp_ds where &cat_var.=&all_group;
		create table ds_ope_non_chemo as select &var_var., count, percent from temp_ds where &cat_var.=&ope_non_chemo;
		create table ds_ope_chemo as select &var_var., count, percent from temp_ds where &cat_var.=&ope_chemo;
		create table ds_non_ope_non_chemo as select &var_var., count, percent from temp_ds where &cat_var.=&non_ope_non_chemo;
		create table ds_non_ope_chemo as select &var_var., count, percent from temp_ds where &cat_var.=&non_ope_chemo;
		create table temp_output as 
			select 	'' as title, a.&var_var. as items, a.count as all_cnt, a.percent as all_per, 
						b.count as ope_non_chemo_cnt, b.percent as ope_non_chemo_per, 
						c.count as ope_chemo_cnt, c.percent as ope_chemo_per,
						d.count as non_ope_non_chemo_cnt, d.percent as non_ope_non_chemo_per, 
						e.count as non_ope_chemo_cnt, e.percent as non_ope_chemo_per 
			from ds_all_group as a 
				left join ds_ope_non_chemo as b on a.&var_var. = b.&var_var.
				left join ds_ope_chemo as c on a.&var_var. = c.&var_var.
				left join ds_non_ope_non_chemo as d on a.&var_var. = d.&var_var.
				left join ds_non_ope_chemo as e on a.&var_var. = e.&var_var.;
	quit;
	data temp_output;
		set temp_output;
		if _N_=1 then do; title=&title.; end;
		%let dsid=%sysfunc(open(temp_output, i));
		%if &dsid %then %do;
      		%let fmt=%sysfunc(varfmt(&dsid, %sysfunc(varnum(&dsid, items))));
      		%let rc=%sysfunc(close(&dsid));
   		%end;
		%put &fmt.;
		temp_items=put(items, &fmt.);
		drop items;
		rename temp_items=items;
	run;
	data &output_ds.;
		set &output_ds. temp_output;
	run;
%mend FREQ_FUNC;
**************************************************************************;
%let thisfile=%GET_THISFILE_FULLPATH;
%let projectpath=%GET_DIRECTORY_PATH(&thisfile., 3);
%inc "&projectpath.\program\sas\analysis_sets.sas";
**************************************************************************;
%CREATE_OUTPUT_DS(output_ds=ds_demog, items_label='背景と人口統計学的特性');
%MEANS_FUNC(title='年齢', var_var=age);
%FREQ_FUNC(title='クローン病', var_var=crohnyn);

