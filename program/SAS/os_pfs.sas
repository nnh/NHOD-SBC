**************************************************************************
Program Name : os_pfs.sas
Study Name : NHOD-SBC
Author : Ohtsuka Mariko
Date : 2020-x-x
SAS version : 9.4
**************************************************************************;
%macro OS_FUNC(input_ds, output_filename, group_var, input_years);
    /*  *** Functional argument *** 
        input_ds : Dataset for lifetest 
        output_filename : Output file name
        group_var : Group variable
        input_years : Time variable
        *** Example ***
        %OS_FUNC(ds_os, os_1, analysis_group, os_years);
    */
    ods graphics /reset=index;
    ods listing close;
        ods rtf file="&outpath.\&output_filename..rtf";
            ods noptitle;
            ods select survivalplot HomTests;
            proc lifetest  
                data=&input_ds. 
                stderr 
                outsurv=os 
                alpha=0.05 
                plot=survival;
                strata &group_var.;
                time &input_years.*censor(1);
            run;
        ods rtf close;
    ods listing;
    ods graphics /reset=all;

    proc export data=os
        outfile="&outpath.\&output_filename..csv"
        dbms=csv replace;
    run;
%mend OS_FUNC;

%macro EDIT_DS_PFS;
    %local const_pfs_end_date;
    /* Set initial value of end date to future date */
    %let const_pfs_end_date=today()+1;
    data ds_pfs;
        set ptdata;
        format pfs_days best12.  pfs_years best12. pfs_start_date yymmdd10. pfs_end_date yymmdd10. censor best12.;
        /* Starting date */
        select (analysis_set);
            when (&ope_chemo., &ope_non_chemo.) do;
                pfs_start_date=resectionDTC;
            end;
            when (&non_ope_chemo.) do;
                pfs_start_date=chemSTDTC;
            end;
            when (&non_ope_non_chemo.) do;
                pfs_start_date=DIGDTC;
            end;
            otherwise call missing(pfs_start_date);
        end;
    run;
    proc sql noprint;
        /* Initial value */
        update ds_pfs set pfs_end_date = &const_pfs_end_date., censor = 1;
        /* In case of death set the date of death */
        update ds_pfs set pfs_end_date = DTHDTC, censor = 0 where DTHFL= '1';
        /* Update if exacerbation date is earlier than death date */
        update ds_pfs set pfs_end_date = RECURRDTC, censor = 0 where (RECURRYN = 2) and (RECURRDTC < pfs_end_date);
        /* Survival confirmation date */
        update ds_pfs set pfs_end_date = SURVDTC, censor = 0 where (DTHFL ne '1') and (RECURRYN ne 2) and (pfs_start_date ne .) and (pfs_end_date ne .);
        update ds_pfs set pfs_days = getDays(pfs_start_date, pfs_end_date), pfs_years = getYears(getDays(pfs_start_date, pfs_end_date));
    quit;
    data ds_ope_pfs ds_non_ope_chemo_pfs;
        set ds_pfs;
        if analysis_group=&ope_group. then do;
            output ds_ope_pfs;
        end;
        if analysis_set=&non_ope_chemo. then do;
            output ds_non_ope_chemo_pfs;
        end;
    run;
%mend EDIT_DS_PFS;

* 5.5.1. OS;
data ds_os ds_ope_os ds_non_ope_os;
    set ptdata;
    /* 1:death */
    if DTHFL = 1 then do;
        os_day=getDays(DIGDTC, DTHDTC);
        censor=0;
    end;
    else do;
        os_day=getDays(DIGDTC, SURVDTC);
        censor=1;
    end;
    os_years=getYears(os_day);
    keep censor os_day os_years analysis_set analysis_group;
    output ds_os;
    if analysis_group=&ope_group. then do;
        output ds_ope_os;
    end;
    if analysis_group=&non_ope_group. then do;
        output ds_non_ope_os;
    end;
run;
* Kaplan-Meier, log-rank;
%OS_FUNC(ds_os, os_1, analysis_group, os_years);
%OS_FUNC(ds_ope_os, os_2, analysis_set, os_years);
%OS_FUNC(ds_non_ope_os, os_3, analysis_set, os_years);

* Kaplan-Meier法による年次の生存率;

* Annual survival rate, event;
%CREATE_OUTPUT_DS(output_ds=ds_death, items_label='イベント');
proc contents data=ds_death out=ds_colnames varnum noprint; run;
%FREQ_FUNC(cat_var=analysis_set, var_var=DTHFL, output_ds=ds_death);
data ds_death;
    set ds_death;
    where items ^= "";
    if items = 1 then title = '死亡';
    else title = 'n';
    keep title ope_non_chemo_cnt ope_chemo_cnt non_ope_non_chemo_cnt non_ope_chemo_cnt;
run;

* 5.5.2 PFS
%EDIT_DS_PFS;
%OS_FUNC(ds_pfs, pfs_1, analysis_group, pfs_years);
%OS_FUNC(ds_ope_pfs, pfs_2, analysis_set, pfs_years);
%OS_FUNC(ds_non_ope_chemo_pfs, pfs_3, analysis_set, pfs_years);
* event ;
%CREATE_OUTPUT_DS(output_ds=ds_exacerbation, items_label='イベント');
proc contents data=ds_exacerbation out=ds_colnames varnum noprint; run;
%FREQ_FUNC(cat_var=analysis_set, var_var=RECURRYN, output_ds=ds_exacerbation);
data ds_exacerbation;
    set ds_exacerbation;
    where items='あり';
    if _N_=1 then title='増悪・再発';
run;

data ds_pfs_event;
    set ds_death ds_exacerbation;
run;
