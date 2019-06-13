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
%let all_group='‘S‘Ì';
%let ope_group='¡–üØœ‚Ì‰ğÍ‘ÎÛW’c';
%let ope_chemo='¡–üØœEChemotherapyŒQ';
%let ope_non_chemo='¡–üØœEnon-ChemotherapyŒQ';
%let non_ope_group='¡–ü–¢Øœ‚Ì‰ğÍ‘ÎÛW’c';
%let non_ope_chemo='¡–ü–¢ØœEChemotherapyŒQ';
%let non_ope_non_chemo='¡–ü–¢ØœEnon-ChemotherapyŒQ';

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
            items char(&items_char_len.) label='€–Ú–¼',
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

%macro SET_COLNAMES(input_ds);  
    %global temp_name_cnt temp_name_per;
    data _NULL_;
        set &input_ds.;
        if _N_=1 then do;
            call symput('temp_analysis_set', analysis_set);
        end;
    run;
    data _NULL_;
        set ds_colnames;
        if LABEL="&temp_analysis_set." then do;
            call symput('temp_name_cnt', NAME);
        end;
    run;
    %let temp_name_per=%substr(&temp_name_cnt, 1, %sysfunc(length(&temp_name_cnt.))-3)per;
%mend SET_COLNAMES;

%macro GET_LENGTH(input_ds, var);
    %global var_len;
    data _NULL_;
        set &input_ds.;
        if NAME=&var. then do;
            call symput('var_len', LENGTH);
        end;
    run;
%mend GET_LENGTH; 

%macro GET_TYPE(input_ds, var);
    %global var_type;
    %local temp_type;
    data _NULL_;
        set &input_ds.;
        if NAME=&var. then do;
            call symput('temp_type', TYPE);
        end;
        if temp_type=1 then do;
            call symput('var_type', 'best12.');
        end;
        else do;
            call symput('var_type', '$');
        end;
    run;
%mend GET_TYPE; 

%macro GET_FORMAT(input_ds, var);
    %global str_format;
    %GET_TYPE(&input_ds., &var.);
    %let str_format=&var_type.;
    %if &str_format.=$ %then %do;
        %GET_LENGTH(&input_ds., &var.);
        %let str_format=%sysfunc(cat(&str_format., &var_len.));
    %end;

%mend GET_FORMAT;

%macro GET_VAR_FORMAT(input_ds, var, return_var);
    data _NULL_;
        set &input_ds.;
        where NAME=&var.;
        if _N_=1 then do;
            call symput("&return_var.", FORMAT);
        end;
    run;
%mend GET_VAR_FORMAT; 
