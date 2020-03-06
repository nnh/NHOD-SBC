**************************************************************************
Program Name : libname.sas
Purpose : Common processing
Author : Ohtsuka Mariko
Date : 2020-03-06
SAS version : 9.4
**************************************************************************;

proc datasets library=work kill nolist; quit;

options mprint mlogic symbolgen minoperator noautocorrect;
libname libads "&projectpath.\ptosh-format\ads";
options fmtsearch=(libads);
* Path;
%let extpath=&projectpath.\input\ext;
%let create_output_dir=%sysfunc(dcreate(SAS, &projectpath\output.));
%let outpath=&projectpath.\output\SAS;
%let ads=&projectpath.\ptosh-format\ads;
%let templatepath=&&projectpath.\output;
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

%macro CREATE_OUTPUT_DS(output_ds='', title_char_len=100, items_char_len=100, items_label='', output_contents_ds=ds_colnames, input_n=ds_n, insert_n_flg=0);
    /*  *** Functional argument ***  
        output_ds : Output dataset
        title_char_len : Character string length of title column
        items_char_len : Character string length of items column
        items_label : Title column label
        output_contents_ds : Output contents dataset
        input_n : Case number data set
        insert_n_flg : Set to 1 to include the number of cases in the data set
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
            all_per char(8)label="%sysfunc(compress(%sysfunc(cat(&all_group. , &cst_per.)), %str(%')))",
            ope_non_chemo_cnt num label="%sysfunc(compress(&ope_non_chemo., %str(%')))",
            ope_non_chemo_per char(8) label="%sysfunc(compress(%sysfunc(cat(&ope_non_chemo. , &cst_per.)), %str(%')))",
            ope_chemo_cnt num label="%sysfunc(compress(&ope_chemo., %str(%')))",
            ope_chemo_per char(8) label="%sysfunc(compress(%sysfunc(cat(&ope_chemo. , &cst_per.)), %str(%')))",
            non_ope_non_chemo_cnt num label="%sysfunc(compress(&non_ope_non_chemo., %str(%')))",
            non_ope_non_chemo_per char(8) label="%sysfunc(compress(%sysfunc(cat(&non_ope_non_chemo. , &cst_per.)), %str(%')))",
            non_ope_chemo_cnt num label="%sysfunc(compress(&non_ope_chemo., %str(%')))",
            non_ope_chemo_per char(8) label="%sysfunc(compress(%sysfunc(cat(&non_ope_chemo. , &cst_per.)), %str(%')))");
    quit;   
    %if &insert_n_flg.=1 %then %do;
        proc sql;
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
    %end;
    * Convert NA to 0;
    proc sql noprint;
        update &output_ds. set all_cnt=0 where all_cnt is missing;
        update &output_ds. set all_per='0' where all_per is missing;
        update &output_ds. set ope_non_chemo_cnt=0 where ope_non_chemo_cnt is missing;
        update &output_ds. set ope_non_chemo_per='0' where ope_non_chemo_per is missing;
        update &output_ds. set ope_chemo_cnt=0 where ope_chemo_cnt is missing;
        update &output_ds. set ope_chemo_per='0' where ope_chemo_per is missing;
        update &output_ds. set non_ope_non_chemo_cnt=0 where non_ope_non_chemo_cnt is missing;
        update &output_ds. set non_ope_non_chemo_per='0' where non_ope_non_chemo_per is missing;
        update &output_ds. set non_ope_chemo_cnt=0 where non_ope_chemo_cnt is missing;
        update &output_ds. set non_ope_chemo_per='0' where non_ope_chemo_per is missing;
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
    /*  *** Functional argument *** 
        input_ds : Table name of select statement
        var : Variable name to be tested
        *** Example ***
        %GET_TYPE(&input_ds., &var.);
    */
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
    /*  *** Functional argument *** 
        input_ds : Table name of select statement
        var : Variable name to be tested
        *** Example ***
        %GET_FORMAT(ds_colnames, 'items');
    */
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

%macro FREQ_FUNC(input_ds=ptdata, title='', cat_var=analysis_set, var_var='', output_ds=ds_demog, contents=ptdata_contents);
    /*  *** Functional argument ***
        input_ds : Dataset to be aggregated
        title : *** Unused ***
        cat_var : Categorical variable
        var_var : Variable to analyze
        output_ds : Output dataset 
        contents : contents dataset
        *** Example ***
        %FREQ_FUNC(title='クローン病', var_var=CrohnYN);
    */
    %local format_f temp_len i cat_list delim_count temp cat;
    %let format_f=.;
    /* Execute FREQ procedure */
    %EXEC_FREQ(&input_ds., &var_var., temp_all_ds);
    %EDIT_DS_ALL;
    %EXEC_FREQ(&input_ds., %str(&cat_var.*&var_var.), temp_freq);
    /* Calculate the percentage of each group */
    data temp_freq_all;
        set temp_all_ds temp_freq;
    run;

    proc sql noprint;
        create table temp_sum as
            select &cat_var., sum(COUNT) as group_sum from temp_freq_all group by &cat_var.;  
    quit;
    proc sql noprint;
        create table temp_sum_var as
            select A.*, B.group_sum from temp_freq_all A inner join temp_sum B on A.&cat_var. = B.&cat_var.;
    quit;
    data temp_ds;
        set temp_sum_var (rename=(PERCENT=temp_per));
        PERCENT=setDecimalFormat(COUNT / group_sum * 100);
        drop temp_per group_sum;
    run;

    /* Get variable format */
    %GET_CONTENTS(&contents., "&var_var.", format);
    %if &temp_return_contents.^='' %then %do;
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
        set temp_ds;
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
        drop &var_var.;
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
        *format title items &str_format..;
        format items &str_format..;
        merge temp1-temp&demog_group_count.;
        by temp_items;
        items=temp_items;
        drop temp_items;
    run;

    data &output_ds.;
        set &output_ds. temp_output;
    run;

%mend FREQ_FUNC;
%macro INSERT_MEANS(cat_var, target_group, input_ds=temp_ds, output_ds=temp_means);
    /*  *** Functional argument ***
        cat_var : Variable name
        target_group : Output target group
        input_ds : Input dataset
        output_ds : Output dataset
        *** Example ***
        %INSERT_MEANS(cat_var=&cat_var., target_group=&all_group.);
    */
    %local row_count;
    proc sql noprint;
        select count(*) into:row_count trimmed from &input_ds. where &cat_var.=&target_group.;
        %if %eval(&row_count.) > 0 %then %do;
            insert into &output_ds. select * from temp_ds where &cat_var.=&target_group.;
        %end;
        %else %do;
            insert into &output_ds. set &cat_var.='dummy';
        %end;
        insert into &output_ds. set &cat_var.='dummy';
    quit;
%mend INSERT_MEANS;
%macro MEANS_FUNC(input_ds=ptdata, title='', cat_var=analysis_set, var_var='', output_ds=ds_demog, output_flg=0);
    /*  *** Functional argument ***
        input_ds : Dataset to be aggregated
        title : Text to output in title column
        cat_var : Categorical variable
        var_var : Variable to analyze
        output_ds : Output dataset 
        output_flg : 0:demog, 1:tumor reduction
        *** Example ***
        %MEANS_FUNC(title='年齢', var_var=AGE);
    */
    data temp_input_ds;
        set &input_ds.;
        where &var_var. is not missing;
    run;
    %local select_str columns;
    %let columns = %str(n=n mean=temp_mean std=temp_std median=median q1=q1 q3=q3 min=min max=max);
    /* Calculation of summary statistics (overall) */
    proc means data=temp_input_ds noprint;
        var &var_var.;
        output out=temp_all_ds &columns.;
    run;
    %EDIT_DS_ALL;
    /* Calculation of summary statistics */
    proc means data=temp_input_ds noprint;
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
    proc sql noprint;
        create table temp_means like temp_ds;
    quit;
    %INSERT_MEANS(cat_var=&cat_var., target_group=&all_group.);
    %INSERT_MEANS(cat_var=&cat_var., target_group=&ope_non_chemo.);
    %INSERT_MEANS(cat_var=&cat_var., target_group=&ope_chemo.);
    %INSERT_MEANS(cat_var=&cat_var., target_group=&non_ope_non_chemo.);
    %INSERT_MEANS(cat_var=&cat_var., target_group=&non_ope_chemo.);
    proc transpose data=temp_means out=tran_means;
        %if &output_flg.=0 %then %do;
            var n mean std median min max;
        %end;
        %else %do;
            var n mean std max min median;
        %end;
    run;
    /* Change the type of "percent" from numeric to string */
    data tran_means_2;
        set tran_means;
        length item_name $100. temp_col1 8. temp_col2 $8. temp_col3 8. temp_col4 $8. temp_col5 8. temp_col6 $8. 
               temp_col7 8. temp_col8 $8. temp_col9 8. temp_col10 $8.;
        item_name=_NAME_;
        temp_col1=col1;
        temp_col2=put(col2, best12.);
        temp_col3=col3;
        temp_col4=put(col4, best12.);
        temp_col5=col5;
        temp_col6=put(col6, best12.);
        temp_col7=col7;
        temp_col8=put(col8, best12.);
        temp_col9=col9;
        temp_col10=put(col10, best12.);
        drop _NAME_ col1 col2 col3 col4 col5 col6 col7 col8 col9 col10;
    run;
    /* Set title only on the first line */
    proc sql;
        insert into &output_ds. select &title., * from tran_means_2 where item_name = 'n';
        insert into &output_ds. select '', * from tran_means_2 where item_name ne 'n';
    quit;

%mend MEANS_FUNC;
%macro FORMAT_FREQ(var, item_list, title, output_ds=ds_demog, input_ds=ptdata, output_n_flg=1, contents=ptdata_contents, cat_var=analysis_set);
    /*  *** Functional argument *** 
        var : Target variable
        item_list : Output these to items
        title : Output it to title
        output_ds : Output dataset
        input_ds : Input dataset
        output_n_flg : If 1, output the number of cases
        contents : contents dataset
        *** Example ***
        %FORMAT_FREQ(CrohnYN, %quote('あり', 'なし', '不明'), 'クローン病');
    */
    data temp_input_ds;
        set &input_ds.;
        where &var. is not missing;
    run;
    %CREATE_DS_N(temp_input_ds, temp_ds_N);
    %CREATE_OUTPUT_DS(output_ds=temp_n, insert_n_flg=1, input_n=temp_ds_N);
    %DELETE_PER(temp_n);
    data temp_n;
        set temp_n;
        drop title;
    run;
    %CREATE_OUTPUT_DS(output_ds=temp_freq);
    %FREQ_FUNC(input_ds=temp_input_ds, title=&title., cat_var=&cat_var., var_var=&var., output_ds=temp_freq, contents=&contents.);
    option DKROCOND=nowarn;
    data temp_freq_items;
        set temp_freq;
        where items is not missing;
        drop title;
    run;
    option DKROCOND=error;
    %JOIN_TO_TEMPLATE(temp_freq_items, ds_join, items, %quote(&item_list.), output_zero_flg=1);
    data &output_ds.;
        if &output_n_flg.=1 then do;
            set &output_ds. temp_n ds_join;
        end;
        else do;
            set &output_ds. ds_join;
        end;
        title=.;
        keep title items all_cnt all_per ope_non_chemo_cnt ope_non_chemo_per ope_chemo_cnt ope_chemo_per 
             non_ope_non_chemo_cnt non_ope_non_chemo_per non_ope_chemo_cnt non_ope_chemo_per;
    run;

%mend FORMAT_FREQ;
%macro JOIN_TO_TEMPLATE(input_ds, output_ds, join_key_colname, template_rows, output_zero_flg=0);
    /*  *** Functional argument ***  
        input_ds : Input dataset
        output_ds : Output dataset
        join_key_colname : Left join key
        template_rows : Output dataset rows
        output_zero_flg : 1 : Convert NA to 0
        *** Example ***
        %JOIN_TO_TEMPLATE(ds_res_1, response_ope_non_chemo, items, %quote('n', 'CR', 'PR', 'SD', 'PD', 'NE'));
    */
    %local delim_count i temp_col col_count temp_colname temp_colname_length temp_fmt temp_type temp_zero;
    %let delim_count = %sysfunc(count(&template_rows., %quote(,)));
    proc sql noprint;
        create table template_ds (temp_key char(100), seq num);
        %do i = 1 %to %eval(&delim_count.+1);
            %let temp_col=%sysfunc(scan(&template_rows, &i., %quote(,)));
            insert into template_ds values(&temp_col., &i.);
        %end;
    quit;
    proc sql noprint;
        create table temp_ds as 
            select * from template_ds A left join &input_ds. B on A.temp_key = B.&join_key_colname. order by seq;
    quit;
    %if &output_zero_flg=1 %then %do;
        proc contents data=temp_ds out=join_template_contents varnum noprint;
        run;
        proc sql noprint;
            select count(*) into:col_count trimmed from join_template_contents;
        quit;
        %do i = 1 %to &col_count.;
            data _NULL_;
                set join_template_contents;
                if _N_=&i. then do;
                    call symput('temp_colname', NAME);
                    call symput('temp_colname_length', length(trim(NAME)));
                    call symput('temp_fmt', substr(FORMAT, 1, 3));
                    call symput('temp_type', TYPE);
                end;
            run;
            %if &temp_fmt.^=FMT %then %do;
                %if &temp_type.=1 %then %do;
                    %let temp_zero=0;
                %end;
                %else %if &temp_type.=2 %then %do;
                    %let temp_per_str=%sysfunc(substr(&temp_colname.,%eval(&temp_colname_length. - 3 + 1), 3));
                    %if &temp_per_str.=per %then %do;
                        %let temp_zero='0.0';
                    %end;
                    %else %do;
                        %let temp_zero='0';
                    %end;
                %end;
                proc sql noprint;
                    update temp_ds set &temp_colname.=&temp_zero. where &temp_colname. is missing;
                quit;
            %end; 
        %end;
    %end;
    data &output_ds.;
        set temp_ds;
        drop &join_key_colname.;
        rename temp_key= &join_key_colname.;
    run;
%mend;
%macro DELETE_PER(target_ds);
    /*  *** Functional argument *** 
        target_ds : dataset
        *** Example ***
        %DELETE_PER(temp_meta);
    */
    proc sql noprint;
        update &target_ds.
            set all_per='', ope_non_chemo_per='', ope_chemo_per='', non_ope_non_chemo_per='', non_ope_chemo_per='';
    quit;
%mend DELETE_PER;
%macro EDIT_TREATMENT(output_ds, var, items_list, input_ds=ptdata);
    /*  *** Functional argument *** 
        output_ds : Output dataset
        var : Variable name
        items_list : Output items
        input_ds : Input dataset
        *** Example ***
        %EDIT_TREATMENT(ds_surgical_curability, resectionCAT, %quote('RX', 'R0', 'R1', 'R2'));
    */
    %CREATE_OUTPUT_DS(output_ds=temp_&output_ds., items_label='');
    %FORMAT_FREQ(&var., &items_list., output_ds=temp_&output_ds., input_ds=&input_ds.);
    data &output_ds. temp_n;
        set temp_&output_ds.;
        if _N_=1 then do;
            output temp_n;
        end;
        else do;
            output &output_ds.;    
        end;
    run;
    %EDIT_N(temp_n, &output_ds._n);
%mend EDIT_TREATMENT;
%macro EDIT_N(input_ds, output_ds, pattern_f=0);
    /*  *** Functional argument *** 
        input_ds : Input dataset
        output_ds : Output dataset
        pattern_f : Output string conditions
                    0 : "(n=1)", 1 : "1", 2 : "n=1" 
        *** Example ***
        %EDIT_N(temp_t010_n, t010_n);
    */
    %local var_cnt dsid rc i;
    proc contents data=&input_ds. out=temp_contents varnum noprint;
    run;
    proc sql noprint;
        select count(*) into:var_cnt from temp_contents;
    quit;
    data temp_ds;
        set &input_ds.;
    run;
    %let dsid=%sysfunc(open(&input_ds., i));
    %do i = 1 %to &var_cnt.; 
        %let var_name=%sysfunc(varname(&dsid., &i.));
        data temp_ds;
            set temp_ds;
            if &pattern_f.=0 then do;
                temp=catt('(n=', &var_name., ')');
            end;
            else if &pattern_f.=1 then do;
                temp=catt(&var_name., '');
            end;
            else if &pattern_f.=2 then do;
                temp=catt('n=', &var_name.);
            end;
            drop &var_name.;
            rename temp=&var_name.;
        run;
    %end;
    %let rc=%sysfunc(close(&dsid));
    data &output_ds.;
        set temp_ds;
    run;
%mend;
%macro CREATE_DS_N(input_ds, output_ds); 
    /*  *** Functional argument *** 
        input_ds : Input dataset
        output_ds : Output dataset
        *** Example ***
        %CREATE_DS_N(ptdata_all, ds_N);
    */
    %local count_n;
    proc sql noprint;
        create table &output_ds. (Item char(200), Category char(200), count num, percent num);
        select count(*) into: count_n from &input_ds.;
        insert into &output_ds. values('解析対象集団の内訳', '登録数', &count_n., 100);
    quit;
    %EXEC_FREQ(&input_ds., efficacy, efficacy);
    %EXEC_FREQ(&input_ds., safety, safety);
    %EXEC_FREQ(&input_ds., analysis_set, analysis_set);
    %EXEC_FREQ(&input_ds., analysis_group, analysis_group);
    data analysis; 
        set analysis_set(rename=(analysis_set=analysis))
        analysis_group(rename=(analysis_group=analysis));
    run;
    %INSERT_SQL(safety, &output_ds., %str('', '安全性解析対象集団', count, percent), %str(safety=1));
    %INSERT_SQL(efficacy, &output_ds., %str('', &efficacy_group., count, percent), %str(efficacy=1));
    %INSERT_SQL(analysis, &output_ds., %str('', &ope_group., count, percent), %str(analysis=)&ope_group.);
    %INSERT_SQL(analysis, &output_ds., %str('', &ope_non_chemo., count, percent), %str(analysis=)&ope_non_chemo.);
    %INSERT_SQL(analysis, &output_ds., %str('', &ope_chemo., count, percent), %str(analysis=)&ope_chemo.);
    %INSERT_SQL(analysis, &output_ds., %str('', &non_ope_group., count, percent), %str(analysis=)&non_ope_group.);
    %INSERT_SQL(analysis, &output_ds., %str('', &non_ope_non_chemo., count, percent), %str(analysis=)&non_ope_non_chemo.);
    %INSERT_SQL(analysis, &output_ds., %str('', &non_ope_chemo., count, percent), %str(analysis=)&non_ope_chemo.);
%mend CREATE_DS_N;
*Function call;
%inc "&projectpath.\program\SAS\macro\libfunction.sas";
