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
