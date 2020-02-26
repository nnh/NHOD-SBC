**************************************************************************
Program Name : os_pfs.sas
Study Name : NHOD-SBC
Author : Ohtsuka Mariko
Date : 2020-2-21
SAS version : 9.4
**************************************************************************;

%macro EXEC_LIFETEST_1(input_ds, output_ds, group_var, target_1, target_2, p_value=0.05);
    /*  *** Functional argument *** 
        input_ds : Input dataset 
        output_ds : Output dataset
        group_var : Group variable
        target_1 : Target group
        target_2 : Target group
        p_value : Risk rate of confidence interval 
        *** Example ***
        %EXEC_LIFETEST_1(os_all, lifetest_f001, analysis_group, &ope_group., &non_ope_group.);
    */
    data temp_input;
        set &input_ds.;
        where os_day^=.;
    run;
    ods listing close;
    ods output HomTests=temp_homtests;
    proc lifetest  
        data=temp_input stderr outsurv=temp_surv alpha=&p_value.;
        strata &group_var.;
        time os_day*censor(1);
    run;
    data &output_ds._1 &output_ds._2;
        set temp_surv;
        if &group_var.=&target_1. then do;
            output &output_ds._1;
        end;
        else if &group_var=&target_2. then do;
            output &output_ds._2;
        end;
    run;
    %OS_FUNC_1(&output_ds._1, &target_1.);
    %OS_FUNC_1(&output_ds._2, &target_2.);
    /* log-rank */
    data homtests_&output_ds.;
        set temp_homtests;
        if _N_=1 then do;
            output;
        end;
    run;
    /* Annual overall survival */
    proc lifetest 
        data=temp_input outsurv=temp_surv_timelist alpha=&p_value. timelist=1 2 3 reduceout;
        strata &group_var.;
        time os_years*censor(1);
    run;
    data temp_surv_timelist_annual;
        set temp_surv_timelist;
        temp_survival=setDecimalFormat(SURVIVAL*100);
        temp_lcl=setDecimalFormat(SDF_LCL*100);
        temp_ucl=setDecimalFormat(SDF_UCL*100);
        output=cat(compress(temp_survival), ' (', compress(temp_lcl), ' - ', compress(temp_ucl), ')');
        keep &group_var. output;
    run;
    proc sql noprint;
        create table temp_&output_ds._n_1
        as select count(*) as count from temp_input where &group_var.=&target_1.;
        create table temp_&output_ds._n_2
        as select count(*) as count from temp_input where &group_var.=&target_2.;
    quit;
    %EDIT_N(temp_&output_ds._n_1, &output_ds._n_1);
    %EDIT_N(temp_&output_ds._n_2, &output_ds._n_2);
    data &output_ds._annual_1 &output_ds._annual_2;
        set temp_surv_timelist_annual;
        if &group_var.=&target_1. then do;
            output &output_ds._annual_1;
        end;
        else if &group_var=&target_2. then do;
            output &output_ds._annual_2;
        end;
    run;
%mend EXEC_LIFETEST_1;
%macro EXEC_LIFETEST_2(input_ds, output_ds, target_1, p_value=0.05);
    /*  *** Functional argument *** 
        input_ds : Input dataset 
        output_ds : Output dataset
        target_1 : Target group
        p_value : Risk rate of confidence interval 
        *** Example ***
        %EXEC_LIFETEST_2(ds_non_ope_chemo_pfs, lifetest_f006, &non_ope_chemo.);
    */
    data temp_input;
        set &input_ds.;
        where os_day^=.;
    run;
    ods listing close;
    proc lifetest  
        data=temp_input stderr outsurv=&output_ds._1 alpha=&p_value.;
        time os_day*censor(1);
    run;
    %OS_FUNC_1(&output_ds._1, &target_1.);
    /* Annual overall survival */
    proc lifetest 
        data=temp_input outsurv=&output_ds._annual_1 alpha=&p_value. timelist=1 2 3 reduceout;
        time os_years*censor(1);
    run;
    data temp_surv_timelist_annual;
        set temp_surv_timelist;
        temp_survival=setDecimalFormat(SURVIVAL*100);
        temp_lcl=setDecimalFormat(SDF_LCL*100);
        temp_ucl=setDecimalFormat(SDF_UCL*100);
        output=cat(compress(temp_survival), ' (', compress(temp_lcl), ' - ', compress(temp_ucl), ')');
        keep output;
    run;
    proc sql noprint;
        create table temp_&output_ds._n_1
        as select count(*) as count from temp_input;
    quit;
    %EDIT_N(temp_&output_ds._n_1, &output_ds._n_1);
%mend EXEC_LIFETEST_2;

%macro OS_FUNC_1(input_ds, group);
    /*  *** Functional argument *** 
        input_ds : Dataset for lifetest
        group : Group name 
        *** Example ***
        %OS_FUNC_1(&output_ds._1, &target_1.);
    */
    data temp1;
        set &input_ds.(rename=(SURVIVAL=temp_survival)) end=eof;
        where os_day^=.;
        group=&group.;
        retain SURVIVAL;
        if eof=1 then do;
            SURVIVAL=.;
        end;
        else if temp_survival^=. then do;
            SURVIVAL=temp_survival;
        end;
        temp_by=0;
        drop temp_survival; 
    run;
    data temp3;
        set temp1(rename=(SURVIVAL=temp_survival) drop=temp_by);
        temp_by=1;
        SURVIVAL=lag1(temp_survival);
        drop temp_survival;
    run;
    data temp4;
        set temp3;
        by temp_by;
    run;
    data temp5;
        set temp1 temp4;
    run;
    proc sql noprint;
        create table temp6
        as select * from temp5 order by os_day, temp_by desc;
    quit;
    data temp7;
        set temp6 nobs=OBS;
        if _N_^=1 & _N_^=OBS then output;
    run;
    data temp_censor1;
        set temp1;
        where _CENSOR_=1;
        seq=3;
        if SURVIVAL^=. then do;
            output;
        end;
    run;
    data temp_censor2;
        set temp_censor1(rename=(SURVIVAL=temp_survival));
        SURVIVAL=temp_survival+0.03;
        seq=2;
        drop temp_survival;
    run;
    data temp_censor3;
        set temp_censor1(rename=(SURVIVAL=temp_survival));
        SURVIVAL=.;
        seq=1;
        drop temp_survival;
    run;
    data temp_censor4;
        set temp_censor1 temp_censor2 temp_censor3;
    run;
    proc sql noprint;
        create table temp_os
        as select group, os_day, SURVIVAL, SDF_LCL, SDF_UCL from temp7;
        create table temp_os_censor
        as select group, os_day, SURVIVAL, SDF_LCL, SDF_UCL, seq from temp_censor4 order by os_day, seq;
        update temp_os_censor set os_day=. where seq = 1;
    quit;
    data output_&input_ds.;
        set temp_os temp_os_censor(drop=seq);      
        if SURVIVAL^=. then do; 
            temp_survival=setDecimalFormat(SURVIVAL*100);
        end;
        else do;
            call missing(temp_survival);
        end;
        if os_day^=. then do;
            temp_os_day=put(os_day, best12.);
        end;
        else do;
            call missing(temp_os_day);
        end;
        keep group temp_survival temp_os_day;
        drop SURVIVAL;
        rename temp_survival=survival temp_os_day=os_day;
    run;
%mend OS_FUNC_1;

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
        update ds_pfs set pfs_end_date = SURVDTC where (DTHFL ne '1') and (RECURRYN ne 2) and (pfs_start_date ne .) and (pfs_end_date ne .);
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
data os_all os_ope_group os_non_ope_group;
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
    output os_all;
    if analysis_group=&ope_group. then do;
        output os_ope_group;
    end;
    else if analysis_group=&non_ope_group. then do;
        output os_non_ope_group;
    end;
run;
* Kaplan-Meier, log-rank;
%EXEC_LIFETEST_1(os_all, lifetest_f001, analysis_group, &ope_group., &non_ope_group.);
%EXEC_LIFETEST_1(os_ope_group, lifetest_f002, analysis_set, &ope_non_chemo., &ope_chemo.);
%EXEC_LIFETEST_1(os_non_ope_group, lifetest_f003, analysis_set, &non_ope_non_chemo., &non_ope_chemo.);
* event;
%CREATE_OUTPUT_DS(output_ds=ds_death, items_label='イベント', insert_n_flg=1);
proc contents data=ds_death out=ds_colnames varnum noprint; run;
%FREQ_FUNC(cat_var=analysis_set, var_var=DTHFL, output_ds=ds_death);
data t010 temp_t010_n;
    set ds_death;
    keep ope_non_chemo_cnt ope_chemo_cnt non_ope_non_chemo_cnt non_ope_chemo_cnt;
    where items ^= "";
    if items=1 then do;
        output t010;
    end;
    else if items='n' then do;
        output temp_t010_n;
    end;
run;
%EDIT_N(temp_t010_n, t010_n);
* Convert NA to 0;
proc sql noprint;
    update t010 set ope_non_chemo_cnt=0 where ope_non_chemo_cnt is missing;
    update t010 set ope_chemo_cnt=0 where ope_chemo_cnt is missing;
    update t010 set non_ope_non_chemo_cnt=0 where non_ope_non_chemo_cnt is missing;
    update t010 set non_ope_chemo_cnt=0 where non_ope_chemo_cnt is missing;
quit;

* 5.5.2 PFS;
%EDIT_DS_PFS;
/* Set initial value of end date to future date */
%let const_pfs_end_date=today()+1;
data ds_pfs;
    set ptdata;
    format os_day best12. os_years best12. pfs_start_date yymmdd10. pfs_end_date yymmdd10. censor best12.;
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
    update ds_pfs set pfs_end_date = SURVDTC where (DTHFL ne '1') and (RECURRYN ne 2) and (pfs_start_date ne .) and (pfs_end_date ne .);
    update ds_pfs set os_day = getDays(pfs_start_date, pfs_end_date), os_years = getYears(getDays(pfs_start_date, pfs_end_date));
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
%EXEC_LIFETEST_1(ds_pfs, lifetest_f004, analysis_group, &ope_group., &non_ope_group.);
%EXEC_LIFETEST_1(ds_ope_pfs, lifetest_f005, analysis_set, &ope_non_chemo., &ope_chemo.);
%EXEC_LIFETEST_2(ds_non_ope_chemo_pfs, lifetest_f006, &non_ope_chemo.);
* event;
%CREATE_OUTPUT_DS(output_ds=ds_exacerbation, items_label='イベント');
proc contents data=ds_exacerbation out=ds_colnames varnum noprint; run;
%FREQ_FUNC(cat_var=analysis_set, var_var=RECURRYN, output_ds=ds_exacerbation);
data ds_exacerbation;
    set ds_exacerbation;
    where items='あり';
    keep ope_non_chemo_cnt ope_chemo_cnt non_ope_chemo_cnt;
run;
data t014_n;
    set t010_n(keep=ope_non_chemo_cnt ope_chemo_cnt non_ope_chemo_cnt);
run;
data t014;
    set t010(keep=ope_non_chemo_cnt ope_chemo_cnt non_ope_chemo_cnt) ds_exacerbation;
run;
* Convert NA to 0;
proc sql noprint;
    update t014 set ope_non_chemo_cnt=0 where ope_non_chemo_cnt is missing;
    update t014 set ope_chemo_cnt=0 where ope_chemo_cnt is missing;
    update t014 set non_ope_chemo_cnt=0 where non_ope_chemo_cnt is missing;
quit;
