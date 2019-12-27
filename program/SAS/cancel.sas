**************************************************************************
Program Name : cancel.sas
Study Name : NHOD-SBC
Author : Ohtsuka Mariko
Date : 2019-12-25
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
    %local str_item cnt1 cnt2 cnt3 cnt4;
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
            insert into &output_ds.
            values("&str_item.", &cnt1., &cnt2. ,&cnt3. ,&cnt4.); 
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
proc sql;
    create table ds_cancel (
        cancel char(6) label='è«ó·ÇÃì‡ñÛÇ∆íÜé~ó·èWåv',
        ope_non_chemo num label=&ope_non_chemo.,
        ope_chemo num label=&ope_chemo.,
        non_ope_non_chemo num label=&non_ope_non_chemo.,
        non_ope_chemo num label=&non_ope_chemo.
   );
quit;
proc sql;
    create table ds_reasons_for_withdrawal(
        reasons num label='íÜé~óùóR');
quit;
%EXEC_CANCEL;
%JOIN_TO_TEMPLATE(ds_cancel, ds_cancel_join, 
                    %quote(cancel char(6), ope_non_chemo num, ope_chemo num, non_ope_non_chemo num, non_ope_chemo num), 
                    cancel, %quote('äÆóπó·', 'íÜé~ó·'), 
                    %quote(B.ope_non_chemo label=&ope_non_chemo., B.ope_chemo label=&ope_chemo., B.non_ope_non_chemo label=&non_ope_non_chemo., B.non_ope_chemo label=&non_ope_chemo.));

%ds2csv (data=ds_cancel_join, runmode=b, csvfile=&outpath.\ds_cancel.csv, labels=Y);
%ds2csv (data=ds_reasons_for_withdrawal, runmode=b, csvfile=&outpath.\ds_reasons_for_withdrawal.csv, labels=Y);

* Delete the working dataset;
proc datasets lib=work nolist; delete cancel temp_ds template_ds ds_cancel; run; quit;
