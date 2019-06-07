**************************************************************************
Program Name : libname.sas
Purpose : Common processing
Author : Ohtsuka Mariko
Date : 2019-05-30
SAS version : 9.4
**************************************************************************;

proc datasets library=work kill nolist; quit;

options mprint mlogic symbolgen minoperator noautocorrect;
libname libads "&projectpath.\ptosh-format\ads" access=readonly;
options fmtsearch=(libads);
%let extpath=&projectpath.\input\ext;
%let outpath=&projectpath.\output;
%let ads=&projectpath.\ptosh-format\ads;
*Define constants;
%let all_group='�S��';
%let ope_group='�����؏��̉�͑ΏۏW�c';
%let ope_chemo='�����؏��EChemotherapy�Q';
%let ope_non_chemo='�����؏��Enon-Chemotherapy�Q';
%let non_ope_group='�������؏��̉�͑ΏۏW�c';
%let non_ope_chemo='�������؏��EChemotherapy�Q';
%let non_ope_non_chemo='�������؏��Enon-Chemotherapy�Q';

%macro INSERT_SQL(input_ds, output_ds, var_list, cond_str);
	%local sql_str;
	%let sql_str=%str(select &var_list. from &input_ds.);
	%if &cond_str.^=. %then %do;
		%let sql_str=&sql_str.%str( where &cond_str.);
	%end;
	proc sql;
		insert into &output_ds.
		&sql_str.; 
	quit;
%mend INSERT_SQL;

%macro CREATE_OUTPUT_DS(output_ds='', title_char_len=100, items_char_len=100, items_label='');
	%local cst_per;
	%let cst_per='(%)';
	proc sql;
		create table &output_ds. (
			title char(&title_char_len.) label="%substr(&items_label., 2, %length(&ope_group.)-2)", 
			items char(&items_char_len.) label='���ږ�',
			all_cnt num label=&all_group.,
			all_per num label="%sysfunc(compress(%sysfunc(cat(&all_group. , &cst_per.)), %str(%')))",
			ope_non_chemo_cnt num label="%sysfunc(compress(&ope_non_chemo., %str(%')))",
			ope_non_chemo_per num label="%sysfunc(compress(%sysfunc(cat(&ope_non_chemo. , &cst_per.)), %str(%')))",
			ope_chemo_cnt num label="%sysfunc(compress(&ope_chemo., %str(%')))",
			ope_chemo_per num label="%sysfunc(compress(%sysfunc(cat(&ope_chemo. , &cst_per.)), %str(%')))",
			non_ope_non_chemo_cnt num label="%sysfunc(compress(&non_ope_non_chemo., %str(%')))",
			non_ope_non_chemo_per num label="%sysfunc(compress(%sysfunc(cat(&non_ope_non_chemo. , &cst_per.)), %str(%')))",
			non_ope_chemo_cnt num label="%sysfunc(compress(&non_ope_chemo., %str(%')))",
			non_ope_chemo_per num label="%sysfunc(compress(%sysfunc(cat(&non_ope_chemo. , &cst_per.)), %str(%')))");
	quit;	
%mend CREATE_OUTPUT_DS;
