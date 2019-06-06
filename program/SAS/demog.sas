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

%CREATE_OUTPUT_DS(ds_demog, 30, 'îwåiÇ∆êlå˚ìùåväwìIì¡ê´');

%macro MEANS_FUNC(input_ds, cat_var, var_var, output_ds);
	proc means data=&input_ds. noprint;
		class &cat_var.;
		var &var_var.;
		output out=temp_ds n=n mean=temp_mean std=temp_std median=median q1=q1 q3=q3 min=min max=max;
	run;
	data temp_ds;
		set temp_ds;
		mean=round(temp_mean, 0.1);
		std=round(temp_std, 0.1);
	run;
	data temp_means1;
		set temp_ds;
		if analysis_set=&ope_non_chemo. then output;
	run;
	data temp_means2;
		set temp_ds;
		if analysis_set=&ope_chemo. then output;
	run;
	data temp_means3;
		set temp_ds;
		if analysis_set=&non_ope_non_chemo. then output;
	run;
	data temp_means4;
		set temp_ds;
		if analysis_set=&non_ope_chemo. then output;
	run;
	data aaa;
		set temp_means1 - temp_means4;
	run;
/*	proc transpose data=temp_ds out=aaa;
		 var &cat_var. n mean std median q1 q3 min max;
	run;*/
%mend;
%means_func(ptdata, analysis_set, age, age);

%macro INSERT_DEMOG(input_ds, output_ds, cond);
	%local str_item cnt_all cnt1 cnt2 cnt3 cnt4 per_all per1 per2 per3 per4;
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
