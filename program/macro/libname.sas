**************************************************************************
Program Name : libname.sas
Purpose : Common processing
Author : Ohtsuka Mariko
Date : 2019-05-30
SAS version : 9.4
**************************************************************************;

proc datasets library=work kill nolist; quit;

options mprint mlogic symbolgen minoperator noautocorrect;

%let extpath=&projectpath.\input\ext;
%let outpath=&projectpath.\output;

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
