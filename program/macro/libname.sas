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
%let ope_group='¡–üØœ‚Ì‰ğÍ‘ÎÛW’c';
%let ope_chemo='¡–üØœEChemotherapyŒQ';
%let ope_non_chemo='¡–üØœEnon-ChemotherapyŒQ';
%let non_ope_group='¡–ü–¢Øœ‚Ì‰ğÍ‘ÎÛW’c';
%let non_ope_chemo='¡–ü–¢ØœEChemotherapyŒQ';
%let non_ope_non_chemo='¡–ü–¢ØœEnon-ChemotherapyŒQ';

%macro INSERT_SQL(input_ds, output_ds, item, cat, cnt, per, cond_str);
	%local sql_str;
	%let sql_str=%str(select &item., &cat., &cnt., &per. from &input_ds.);
	%if &cond_str.^=. %then %do;
		%let sql_str=&sql_str.%str( where &cond_str.);
	%end;
	proc sql;
		insert into &output_ds.
		&sql_str.; 
	quit;
%mend INSERT_SQL;
