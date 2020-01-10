**************************************************************************
Program Name : response.sas
Study Name : NHOD-SBC
Author : Ohtsuka Mariko
Date : 2020-01-10
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
    %local i delim_count regimens temp_colname temp_regimen colname temp_sum;
    %GET_CONTENTS(ptdata_contents, "&key_col.", format);
    %GET_FORMAT_LENGTH(&temp_return_contents.);
    /* Convert format to string */
    data temp_input_ds_str;
        set &input_ds(rename=(&key_col.=temp_col));
        &key_col.=put(temp_col, &format_length..);
    run;
    /* Delete observation if treatment name is missing */
    data temp_input_ds_str;
        set temp_input_ds_str;
        if not missing(temp_col) then output; 
    run;
    /* Count the number of treatments */
    proc sql noprint;
        create table temp_ds
            as select &key_col., RECISTORRES, count(*) as temp_count 
               from temp_input_ds_str 
               group by &key_col., RECISTORRES; 
    quit;
    /* List of treatments */
    proc sql noprint;
        select distinct &key_col. into:regimens separated by ',' from temp_ds;
    quit;
    %let delim_count = %sysfunc(count("&regimens", %quote(,)));
    %GET_CONTENTS(ptdata_contents, "RECISTORRES", format);
    %GET_FORMAT_LENGTH(&temp_return_contents.);
    %do i = 1 %to %eval(&delim_count.+1);
        %let temp_regimen=%sysfunc(scan(%quote(&regimens), &i., %quote(,)));
        /* Prohibition character check */
        %let temp_colname=%sysfunc(compress(&temp_regimen.));
        %let temp_colname=%sysfunc(compress(&temp_colname., "/"));
        proc sql noprint;
            select sum(temp_count) into: temp_sum from temp_ds where &key_col. = "&temp_regimen.";
            create table temp_regimen_ds
                as select RECISTORRES as temp_items, 
                          temp_count as &temp_colname., 
                          round(temp_count / &temp_sum. * 100, 1) as &temp_colname._per 
                   from temp_ds 
                   where &key_col. = "&temp_regimen.";
        quit;
        /* Convert format to string */
        data regimen_ds;
            set temp_regimen_ds;
            items=put(temp_items, &format_length..);
        run;
        proc sql noprint;
            insert into regimen_ds values(., %eval(&temp_sum.), ., 'n');
        quit;

        %let colname=B.&temp_colname.;
        %JOIN_TO_TEMPLATE(regimen_ds, temp_join_regimen, 
                            %quote(items char(2), count num, per num), 
                            items, 
                            %quote('n', 'CR', 'PR', 'SD', 'PD', 'NE'), 
                            %quote(&colname. label="&temp_regimen.", B.&temp_colname._per));
        %if &i.=1 %then %do;
            data &output_ds.;
                set temp_join_regimen;
            run;
        %end;
        %else %do;
            data temp_output_ds;
                set &output_ds.;
            run;
            proc delete data=&output_ds.;
            run;
            proc sql noprint;
                create table &output_ds. as
                    select A.*, &colname., B.&temp_colname._per 
                    from temp_output_ds A inner join temp_join_regimen B on A.items = B.items;
            quit;
        %end;
    %end;
    %ds2csv (data=&output_ds., runmode=b, csvfile=&outpath.\_5_5_3_&output_ds..csv, labels=Y);

%mend EDIT_RESPONSE;

%SET_FREQ(ds_res_1, 'é°ó√ÇÃëtå¯äÑçá', RECISTORRES, %str(ope_non_chemo_cnt ope_non_chemo_per));

data ds_ope_chemo ds_non_ope_chemo;
    set ptdata;
    if analysis_set=&ope_chemo. then output ds_ope_chemo;
    if analysis_set=&non_ope_chemo. then output ds_non_ope_chemo;
run;
%JOIN_TO_TEMPLATE(ds_res_1, response_ope_non_chemo, 
                    %quote(items char(2), count num, per num), 
                    items, 
                    %quote('n', 'CR', 'PR', 'SD', 'PD', 'NE'), 
                    %quote(B.ope_non_chemo_cnt label="é°ó√Ç»Çµ", B.ope_non_chemo_per label='(%)'));
%ds2csv (data=response_ope_non_chemo, runmode=b, csvfile=&outpath.\_5_5_3_response_ope_no_chemo.csv, labels=Y);

proc sql;
    create table ds_res_2
    as select adjuvantCAT, RECISTORRES, count(*) as count from ds_ope_chemo group by adjuvantCAT, RECISTORRES;
quit;
%EDIT_RESPONSE(ds_ope_chemo, adjuvantCAT, response_ope_chemo);

proc sql;
    create table ds_res_3
    as select chemCAT, RECISTORRES, count(*) from ds_non_ope_chemo group by chemCAT, RECISTORRES;
quit;
%EDIT_RESPONSE(ds_non_ope_chemo, chemCAT, response_non_ope_chemo);

* Delete the working dataset;
proc datasets lib=work nolist; 
    delete ds_res_1-ds_res_3 temp_output_ds regimen_ds temp_join_regimen temp_regimen_ds; 
    run; 
quit;
