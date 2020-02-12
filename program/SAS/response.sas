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

%macro EDIT_RESPONSE(input_ds, key_col, output_ds, regimens);
    /*  *** Functional argument ***  
        input_ds : Input dataset
        key_col : Key variables
        output_ds : Output dataset
        regimens : List of regimens
        *** Example ***
        %EDIT_RESPONSE(ds_ope_chemo, adjuvantCAT, response_ope_chemo);
    */
    %local i delim_count temp_colname temp_regimen colname temp_sum;
    %GET_CONTENTS(ptdata_contents, "&key_col.", format);
    %GET_FORMAT_LENGTH(&temp_return_contents.);
    /* Convert format to string */
    data temp_input_ds_str;
        set &input_ds(rename=(&key_col.=temp_col));
        &key_col.=put(temp_col, &format_length..);
    run;
    %let delim_count = %sysfunc(count("&regimens", %quote(,)));
    %put &delim_count.;
    %GET_CONTENTS(ptdata_contents, "RECISTORRES", format);
    %GET_FORMAT_LENGTH(&temp_return_contents.);
    %do i = 1 %to %eval(&delim_count.+1);
        %let temp_regimen=%sysfunc(scan(%quote(&regimens), &i., %quote(,)));
        %put &temp_regimen.;
        data temp;
            set temp_input_ds_str(rename=(RECISTORRES=temp_col2));;
            where &key_col.=&temp_regimen.;
            RECISTORRES=put(temp_col2, &format_length..);
            keep &key_col. RECISTORRES;
        run;
        proc sql;
            create table temp&i.
            as select RECISTORRES as items, count(*) as count from temp group by RECISTORRES
               union
               select 'n' as items, count(*) as count from temp;
        quit;
        %JOIN_TO_TEMPLATE(temp&i., ds_join&i., 
                            %quote(items char(2), count num), 
                            items, 
                            %quote('n', 'CR', 'PR', 'SD', 'PD', 'NE'), 
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
%EDIT_RESPONSE(ds_ope_chemo, adjuvantCAT, response_ope_chemo, &regimens_adjuvant.);
%EDIT_RESPONSE(ds_non_ope_chemo, chemCAT, response_non_ope_chemo, &regimens_first_line.);
