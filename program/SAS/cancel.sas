**************************************************************************
Program Name : cancel.sas
Study Name : NHOD-SBC
Author : Ohtsuka Mariko
Date : 2019-06-04
SAS version : 9.4
**************************************************************************;
%macro INSERT_CANCEL(input_ds, output_ds, cond);
    /*  *** Functional argument ***
        input_ds : Table name of select statement 
        output_ds : Output dataset 
        cond : Extraction condition of select statement
        *** Example ***
        %INSERT_CANCEL(cancel, ds_cancel, 1);
    */
    %local str_item cnt1 cnt2 cnt3 cnt4 per1 per2 per3 per4;
    proc sql noprint;
        select * from &input_ds. where dsdecod=&cond.;
    quit;
    %put &sqlobs.; 
    %if &sqlobs.=1 %then %do;
        data temp_ds;
            set &input_ds.;
            format str_dsdecod $6.;
            where dsdecod=&cond.;
            str_dsdecod=cat(put(dsdecod, FMT_9_F.), 'ó·');
        run;    
        proc sql noprint;
            select distinct str_dsdecod into:str_item from temp_ds;
            select count into:cnt1 from temp_ds where analysis_set=&ope_non_chemo.;
            select count into:cnt2 from temp_ds where analysis_set=&ope_chemo.;
            select count into:cnt3 from temp_ds where analysis_set=&non_ope_non_chemo.;
            select count into:cnt4 from temp_ds where analysis_set=&non_ope_chemo.;
            select percent into:per1 from temp_ds where analysis_set=&ope_non_chemo.;
            select percent into:per2 from temp_ds where analysis_set=&ope_chemo.;
            select percent into:per3 from temp_ds where analysis_set=&non_ope_non_chemo.;
            select percent into:per4 from temp_ds where analysis_set=&non_ope_chemo.;
            insert into &output_ds.
            values("&str_item.", &cnt1., &per1., &cnt2., &per2. ,&cnt3., &per3. ,&cnt4., &per4.); 
        quit;
    %end;
%mend INSERT_CANCEL;

%macro EXEC_CANCEL;
    %EXEC_FREQ(ptdata, %str(dsdecod*analysis_set), cancel);
    %do i = 1 %to 2;
        %INSERT_CANCEL(cancel, ds_cancel, &i.);
    %end;
    %INSERT_SQL(ptdata, ds_reasons_for_withdrawal, %str(dsterm), %str(dsterm^=.));
%mend EXEC_CANCEL;

* 5.2. Breakdown of cases and count of discontinued cases;
%CREATE_OUTPUT_DS(output_ds=cancel, items_label='è«ó·ÇÃì‡ñÛÇ∆íÜé~ó·èWåv');
data ds_cancel;
    set cancel;
    drop all_cnt all_per title;
run;

proc sql;
    create table ds_reasons_for_withdrawal(
        reasons num label='íÜé~óùóR');
quit;

%EXEC_CANCEL;

%ds2csv (data=ds_cancel, runmode=b, csvfile=&outpath.\ds_cancel.csv, labels=Y);
%ds2csv (data=ds_reasons_for_withdrawal, runmode=b, csvfile=&outpath.\ds_reasons_for_withdrawal.csv, labels=Y);

* Delete the working dataset;
proc datasets lib=work nolist; delete cancel temp_ds; run; quit;
