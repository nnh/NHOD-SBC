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
* Path;
%let extpath=&projectpath.\input\ext;
%let create_output_dir=%sysfunc(dcreate(SAS, &projectpath\output.));
%let outpath=&projectpath.\output\SAS;
%let ads=&projectpath.\ptosh-format\ads;
* Define constants;
%let efficacy_group='有効性解析対象集団';
%let all_group='全体';
%let ope_group='治癒切除の解析対象集団';
%let ope_chemo='治癒切除・Chemotherapy群';
%let ope_non_chemo='治癒切除・non-Chemotherapy群';
%let non_ope_group='治癒未切除の解析対象集団';
%let non_ope_chemo='治癒未切除・Chemotherapy群';
%let non_ope_non_chemo='治癒未切除・non-Chemotherapy群';
%let demog_group_count=5;
%let regimens_adjuvant=%quote(%quote('UFT+LV/S-1', 'FOLFOX', 'CapeOX', %quote("5%'DFUR/capecitabine"), 'Other regimens'));
%let regimens_first_line=%quote(%quote("FOLFOX/CapeOX/SOX"), %quote("FOLFOX+セツキシマブ"), %quote("FOLFOX+ベバシズマブ"), %quote("FOLFOX+パニツムマブ"), 
                           'FOLFIRI', %quote("FOLFIRI+セツキシマブ"), %quote("FOLFIRI+ベバシズマブ"), %quote("FOLFIRI+パニツムマブ"), %quote("5FU+LV"), 'Other regimens');

%macro INSERT_SQL(input_ds, output_ds, var_list, cond_str);
    /*  *** Functional argument *** 
        input_ds : Table name of select statement 
        output_ds : Output dataset
        var_list : Column name of select statement 
        cond_str : Extraction condition of select statement
        *** Example ***
        %INSERT_SQL(analysis, ds_N, %str('', &ope_group., count, percent), %str(analysis=)&ope_group.);
    */
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

%macro CREATE_OUTPUT_DS(output_ds='', title_char_len=100, items_char_len=100, items_label='', output_contents_ds=ds_colnames, input_n=ds_n);
    /*  *** Functional argument ***  
        output_ds : Output dataset
        title_char_len : Character string length of title column
        items_char_len : Character string length of items column
        items_label : Title column label
        output_contents_ds : Output contents dataset
        input_n : Case number data set
        *** Example ***
        %CREATE_OUTPUT_DS(output_ds=ds_demog, items_label='背景と人口統計学的特性');
    */
    %local cst_per;
    %let cst_per='(%)';
    proc sql;
        create table &output_ds. (
            title char(&title_char_len.) label="%sysfunc(ktruncate(&items_label., 2, %sysfunc(lengthn(&items_label.)) - 2))", 
            items char(&items_char_len.) label='項目名',
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
        insert into &output_ds.(title, items, all_cnt, ope_chemo_cnt, ope_non_chemo_cnt, non_ope_chemo_cnt, non_ope_non_chemo_cnt)
            select distinct 
                    '症例数', 
                    'n', 
                    (select count from &input_n. where Category=&efficacy_group.),
                    (select count from &input_n. where Category=&ope_chemo.),
                    (select count from &input_n. where Category=&ope_non_chemo.),
                    (select count from &input_n. where Category=&non_ope_chemo.),
                    (select count from &input_n. where Category=&non_ope_non_chemo.) from &input_n.;
    quit;   
    proc contents data=&output_ds. out=&output_contents_ds. varnum noprint; run;
%mend CREATE_OUTPUT_DS;

%macro SET_COLNAMES(input_ds);  
    /*  *** Functional argument ***  
        Input_ds : Input dataset
        *** Output global variable
        temp_name_cnt 
        temp_name_per
        *** Example ***
        %SET_COLNAMES(temp1);
    */
    %global temp_name_cnt temp_name_per;
    %local temp_analysis_set;
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

%macro GET_CONTENTS(input_ds, var, target_var);
    /*  *** Functional argument *** 
        input_ds : dataset to be tested
        var : Variable name to be tested
        target_var : Information to return
        *** Example ***
        proc contents data=ptdata out=ptdata_contents varnum noprint; run;
        %GET_CONTENTS(ptdata_contents, MHCOM, length);
    */
    %global temp_return_contents;
    %let temp_return_contents='';
    data _NULL_;
        set &input_ds.;
        where NAME=&var.;
        if _N_=1 then do;
            call symput('temp_return_contents', &target_var.);
        end;
    run;
%mend GET_CONTENTS;

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
        %GET_CONTENTS(&input_ds., &var., length);
        %let str_format=%sysfunc(cat(&str_format., &temp_return_contents.));
        %symdel temp_return_contents;
    %end;
%mend GET_FORMAT;
 
%macro TO_NUM_TEST_RESULTS(input_ds=ptdata, var='', output_ds=ptdata);
    /*  *** Functional argument *** 
        input_ds : Input dataset
        str_tables : Target variable
        output_ds : Output dataset
        *** Example ***
        %TO_NUM_TEST_RESULTS(var=LDH);
    */
    data &output_ds.;
        /* Convert a string to a number. If the value is -1, it is missing. */
        format &var._num best12.;
        set &input_ds.;
        if &var.=-1 then do;
            &var._num=.;
        end;
        else do;
            &var._num=input(&var., best12.);
        end;
    run;
%mend TO_NUM_TEST_RESULTS;

%macro EDIT_DS_ALL(ds=temp_all_ds, cat_var=analysis_set, char_len=100, cat_str=&all_group.);
    /*  *** Functional argument *** 
        ds : Input / Output dataset
        cat_var : Target variable
        char_len : Character string length of title column 
        cat_str : Title column string
        *** Example ***
        %EDIT_DS_ALL;
    */
    data &ds.;
        set &ds.;
        format &cat_var. $&char_len..; 
        &cat_var.=&cat_str.;
    run;
%mend EDIT_DS_ALL;

%macro EXEC_FREQ(input_ds, str_tables, output_ds);
    /*  *** Functional argument *** 
        input_ds : Input dataset
        str_tables : Variables for creating a table
        output_ds : Output dataset
        *** Example ***
        %EXEC_FREQ(ptdata, efficacy, efficaty);
    */
    proc freq data=&input_ds. noprint;
        tables &str_tables. /missing out=&output_ds.;
    run;
%mend EXEC_FREQ;

%macro FREQ_FUNC(input_ds=ptdata, title='', cat_var=analysis_set, var_var='', output_ds=ds_demog);
    /*  *** Functional argument ***
        input_ds : Dataset to be aggregated
        title : Text to output in title column
        cat_var : Categorical variable
        var_var : Variable to analyze
        output_ds : Output dataset 
        *** Example ***
        %FREQ_FUNC(title='クローン病', var_var=CrohnYN);
    */
    %local format_f temp_len i;
    %let format_f=.;
    /* Execute FREQ procedure */
    %EXEC_FREQ(&input_ds., &var_var., temp_all_ds);
    %EDIT_DS_ALL;
    %EXEC_FREQ(&input_ds., %str(&cat_var.*&var_var.), temp_ds);
    /* Get variable format */
    %GET_CONTENTS(ptdata_contents, "&var_var.", format);
    %if &temp_return_contents ne '' %then %do;
        %let temp_len=%sysfunc(length(&temp_return_contents.));
    %end;
    %else %do;
        %let temp_len=0;
    %end;
    %symdel temp_return_contents;
    %if &temp_len.>=3 %then %do;
        %let format_f=1;
    %end;

    data temp_ds;
        set temp_all_ds temp_ds;
        temp_per=round(percent, 0.1);
        %if &format_f.=1 %then %do;
            /* Convert format to string */
            %let dsid=%sysfunc(open(temp_ds, i));
            %if &dsid %then %do;
                %let fmt=%sysfunc(varfmt(&dsid, %sysfunc(varnum(&dsid, &var_var.))));
                %let rc=%sysfunc(close(&dsid));
            %end;
            %put &fmt.;
            items=put(&var_var., &fmt.);
        %end;
        %else %do;
            retain items;
            items=&var_var.;
        %end;
        drop percent &var_var.;
        rename temp_per=percent;
    run;

    /* Split the dataset */
    data temp1 temp2 temp3 temp4 temp5;
        set temp_ds;
        if analysis_set=&all_group. then output temp1;
        else if analysis_set=&ope_non_chemo. then output temp2;
        else if analysis_set=&ope_chemo. then output temp3;
        else if analysis_set=&non_ope_non_chemo. then output temp4;
        else if analysis_set=&non_ope_chemo. then output temp5;
    run;

    %do i = 1 %to %eval(&demog_group_count.);
        %SET_COLNAMES(temp&i.);
        data temp&i.;
            set temp&i.;
            drop analysis_set;
            rename count=&temp_name_cnt. percent=&temp_name_per. items=temp_items;
        run;
        %symdel temp_name_cnt temp_name_per;
        proc sort data=temp&i. out=temp&i.; by temp_items; run; 
    %end;
 
    %GET_FORMAT(ds_colnames, 'items');
    data temp_output;
        format title items &str_format..;
        merge temp1-temp&demog_group_count.;
        by temp_items;
        if _N_=1 then do; title=&title.; end;
        items=temp_items;
        drop temp_items;
    run;

    data &output_ds.;
        set &output_ds. temp_output;
    run;

    /* Delete the working dataset */
    proc datasets lib=work nolist; delete temp1-temp&demog_group_count. temp_ds temp_all_ds temp_output; run; quit;

%mend FREQ_FUNC;

%macro MEANS_FUNC(input_ds=ptdata, title='', cat_var=analysis_set, var_var='', output_ds=ds_demog);
    /*  *** Functional argument ***
        input_ds : Dataset to be aggregated
        title : Text to output in title column
        cat_var : Categorical variable
        var_var : Variable to analyze
        output_ds : Output dataset 
        *** Example ***
        %MEANS_FUNC(title='年齢', var_var=AGE);
    */
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

%mend MEANS_FUNC;
%macro SET_FREQ(output_ds_name, str_label, var, str_keep, csv_name);
    /*  *** Functional argument *** 
        output_ds_name : Name of the data set to output
        str_label : Title
        var : Target variable name of input data set
        str_keep : Variables to leave in the output data set
        csv_name : csv name, if this value is NA, do not output csv
        csv_output_f : 1:output csv, otherwise:do not output csv
        *** Example ***
        %SET_FREQ(ds_surgical_curability, '手術の根治度', resectionCAT, %str(ope_non_chemo_cnt ope_non_chemo_per ope_chemo_cnt ope_chemo_per), surgical_curability.csv);
    */
    %CREATE_OUTPUT_DS(output_ds=&output_ds_name.)
    proc contents data=&output_ds_name. out=ds_colnames varnum noprint; run;
    %FREQ_FUNC(var_var=&var., output_ds=&output_ds_name.);
    data &output_ds_name.;
        set &output_ds_name.;
        if _N_=1 then title=&str_label;
        keep title items &str_keep.;
    run;
    %if &csv_name. ^= . %then %do;
        %ds2csv (data=&output_ds_name., runmode=b, csvfile=&outpath.\&csv_name., labels=Y);
    %end;
%mend SET_FREQ;
%macro JOIN_TO_TEMPLATE(input_ds, output_ds, output_cols, join_key_colname, template_rows, select_str);
    /*  *** Functional argument ***  
        input_ds : Input dataset
        output_ds : Output dataset
        output_cols : Output dataset columns
        join_key_colname : Left join key
        template_rows : Output dataset rows
        select_str : Select statement text
        *** Example ***
        %JOIN_TO_TEMPLATE(ds_res_1, response_ope_non_chemo, %quote(items char(2), count num), items, %quote('n', 'CR', 'PR', 'SD', 'PD', 'NE'), %quote(B.ope_non_chemo_cnt label="治療なし"));
    */
    %local i delim_count temp_col temp_insert_str insert_str_delim_count;
    /* Count delimiters and get number of observations */
    %let delim_count = %sysfunc(count(&template_rows., %quote(,)));
    %let insert_str_delim_count = %sysfunc(count(&select_str., %quote(,)));
    data _NULL_;
        call symput('temp_insert_str', repeat(".,", &insert_str_delim_count.));
    run;
    /* Create an observation for the argument output_cols in the template dataset and add the variable seq for sorting */
    proc sql noprint;
        create table template_ds
            (&output_cols., seq num);
        %do i = 1 %to %eval(&delim_count.+1);
            %let temp_col=%sysfunc(scan(&template_rows, &i., %quote(,)));
            *insert into template_ds values(&temp_col., ., &i.);
            insert into template_ds values(&temp_col., &temp_insert_str. &i.);
        %end;
    quit;
    /* Merge template dataset and input dataset and sort in seq order */
    proc sql noprint;
        create table &output_ds. as
            select A.seq, A.&join_key_colname., &select_str. from template_ds A left join &input_ds. B on A.&join_key_colname. = B.&join_key_colname. order by seq;
    quit;
    /* Delete variable seq */
    proc sql noprint;
        alter table &output_ds. drop seq;
    quit;
%mend JOIN_TO_TEMPLATE;

%inc "&projectpath.\program\macro\libfunction.sas";

