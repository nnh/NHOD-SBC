**************************************************************************
Program Name : response.sas
Study Name : NHOD-SBC
Author : Ohtsuka Mariko
Date : 2020-02-12
SAS version : 9.4
**************************************************************************;
* 5.5.3. Response rate of treatment;
%macro GET_FORMAT_LENGTH(format_name);
    /*  *** Functional argument ***  
        format_name : format name
        *** Example ***
        %GET_FORMAT_LENGTH(FMT_18_F);
    */
    %global format_length;
    proc format library=libads cntlout=temp_fmt_len;
        select &format_name.;
    run;
    data _NULL_;
        set temp_fmt_len;
        if _N_=1 then do;
            call symput('format_length', cat("&format_name.", LENGTH));
        end;
    run;
%mend GET_FORMAT_LENGTH;
%macro EDIT_RESPONSE(input_ds, key_col, output_ds);
    /*  *** Functional argument ***  
        input_ds : Input dataset
        key_col : Key variables
        output_ds : Output dataset
        *** Example ***
        %EDIT_RESPONSE(ds_ope_chemo, adjuvantCAT, response_ope_chemo);
    */
    %local i delim_count temp_colname temp_regimen colname temp_sum;
    %GET_CONTENTS(ptdata_contents, "&key_col.", format);
    %GET_FORMAT_LENGTH(&temp_return_contents.);
    proc format library=libads cntlout=work.temp_format;
        select &temp_return_contents.;
    run;
    data format_num_list;
        set temp_format;
        fmt_num=input(compress(start), best.);
        keep fmt_num label;
    run;
    proc sql noprint;
        insert into format_num_list set fmt_num=., label='Ž¡—Ã‚È‚µ';
    quit;
    proc sql noprint;
        select count(*) into:row_count trimmed from format_num_list;
    quit;
    %put &row_count.;
    %do i = 1 %to &row_count.;
        data _NULL_;
            set format_num_list;
            if _N_=&i. then do;
                call symput('target', fmt_num);
            end;
        run;
        %put &target.;
        proc sql;
            create table temp&i.
            as select RECISTORRES as items, count(*) as count from &input_ds. where &key_col.= &target. group by RECISTORRES
               union
               select 0 as items, count(*) as count from &input_ds. where &key_col.= &target.;
        quit;
        %JOIN_TO_TEMPLATE(temp&i., ds_join&i., 
                            %quote(items num, count num), 
                            items, 
                            %quote(0, 1, 2, 3, 4, 5), 
                            %quote(b.count label="test"));
        %if &i.=1 %then %do;
            data &output_ds._all;
                set ds_join&i.;
            run;
        %end;
        %else %do;
            data temp_output_ds;
                set &output_ds._all;
            run;
            proc delete data=&output_ds._all;
            run;
            proc sql noprint;
                create table &output_ds._all as
                    select A.*, b.count as count&i. 
                    from temp_output_ds A inner join ds_join&i. B on A.items = B.items;
            quit;
        %end;
    %end;
    data &output_ds. &output_ds._n;
        set &output_ds._all;
        if _N_=1 then do;
            output &output_ds._n;
        end;
        else do;
            output &output_ds;
        end;
    run;
    %EDIT_N(&output_ds._n, &output_ds._n, pattern_f=2)
    %EDIT_N(&output_ds., &output_ds., pattern_f=1)
    data &output_ds.;
        set &output_ds._n &output_ds.;
        drop items;
    run;

%mend EDIT_RESPONSE;

%EDIT_TREATMENT(response_ope_non_chemo, RECISTORRES, %quote('CR', 'PR', 'SD', 'PD', 'NE'), %quote(ope_non_chemo_cnt));
data ds_ope_chemo ds_non_ope_chemo;
    set ptdata;
    if analysis_set=&ope_chemo. then output ds_ope_chemo;
    if analysis_set=&non_ope_chemo. then output ds_non_ope_chemo;
run;
%EDIT_RESPONSE(ds_ope_chemo, adjuvantCAT, response_ope_chemo);
%EDIT_RESPONSE(ds_non_ope_chemo, chemCAT, response_non_ope_chemo);

