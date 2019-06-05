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
%let ope_group='治癒切除の解析対象集団';
%let ope_chemo='治癒切除・Chemotherapy群';
%let ope_non_chemo='治癒切除・non-Chemotherapy群';
%let non_ope_group='治癒未切除の解析対象集団';
%let non_ope_chemo='治癒未切除・Chemotherapy群';
%let non_ope_non_chemo='治癒未切除・non-Chemotherapy群';

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

%macro CREATE_OUTPUT_DS(output_ds, items_char_len, items_label);
	proc sql;
		create table &output_ds. (
			items char(&items_char_len.) label="%substr(&items_label., 2, %length(&ope_group.)-2)",
			all_cnt num label='全体 度数',
			all_per num label='全体 パーセント',
			ope_non_chemo_cnt num label="%substr(&ope_non_chemo., 2, %length(&ope_non_chemo.)-2)　度数",
			ope_non_chemo_per num label="%substr(&ope_non_chemo., 2, %length(&ope_non_chemo.)-2)　パーセント",
			ope_chemo_cnt num label='治癒切除・chemo 度数',
			ope_chemo_per num label='治癒切除・chemo パーセント',
			non_ope_non_chemo_cnt num label='治癒未切除・non-chemo 度数',
			non_ope_non_chemo_per num label='治癒未切除・non-chemo パーセント',
			non_ope_chemo_cnt num label='治癒未切除・chemo 度数',
			non_ope_chemo_per num label='治癒未切除・chemo パーセント');
	quit;	
%mend CREATE_OUTPUT_DS;
%CREATE_OUTPUT_DS(aaa, 10, '症例の内訳と中止例集計');
