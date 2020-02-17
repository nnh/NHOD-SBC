**************************************************************************
Program Name : os_pfs.sas
Study Name : NHOD-SBC
Author : Ohtsuka Mariko
Date : 2020-2-13
SAS version : 9.4
**************************************************************************;

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
data os_ope_group os_non_ope_group os_ope_non_chemo os_ope_chemo os_non_ope_non_chemo os_non_ope_chemo;
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
    if analysis_group=&ope_group. then do;
        output os_ope_group;
        if analysis_set=&ope_chemo. then do;
            output os_ope_chemo;
        end;
        else if analysis_set=&ope_non_chemo. then do;
            output os_ope_non_chemo;
        end; 
    end;
    else if analysis_group=&non_ope_group. then do;
        output os_non_ope_group;
        if analysis_set=&non_ope_chemo. then do;
            output os_non_ope_chemo;
        end;
        else if analysis_set=&non_ope_non_chemo. then do;
            output os_non_ope_non_chemo;
        end; 
    end;
run;
* Kaplan-Meier, log-rank;
%OS_FUNC(ds_os, _5_5_1_os_1, analysis_group, os_years, %quote(&ope_group., &non_ope_group.));
%OS_FUNC(ds_ope_os, _5_5_1_os_2, analysis_set, os_years);
%OS_FUNC(ds_non_ope_os, _5_5_1_os_3, analysis_set, os_years);

* event;
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

* 5.5.2 PFS;
%EDIT_DS_PFS;
%OS_FUNC(ds_pfs, _5_5_2_pfs_1, analysis_group, pfs_years, pfs_f=1);
%OS_FUNC(ds_ope_pfs, _5_5_2_pfs_2, analysis_set, pfs_years, pfs_f=1);
%OS_FUNC(ds_non_ope_chemo_pfs, _5_5_2_pfs_3, ., pfs_years, pfs_f=1);

* event;
%CREATE_OUTPUT_DS(output_ds=ds_exacerbation, items_label='イベント');
proc contents data=ds_exacerbation out=ds_colnames varnum noprint; run;
%FREQ_FUNC(cat_var=analysis_set, var_var=RECURRYN, output_ds=ds_exacerbation);
data ds_exacerbation;
    set ds_exacerbation;
    where items='あり';
    if _N_=1 then title='増悪・再発';
    keep title ope_non_chemo_cnt ope_chemo_cnt non_ope_chemo_cnt;
run;

data ds_pfs_event;
    set ds_death(keep=title ope_non_chemo_cnt ope_chemo_cnt non_ope_chemo_cnt) ds_exacerbation;
run;

%macro OS_FUNC(input_ds, group, p_value=0.05, pfs_f=0);
    /*  *** Functional argument *** 
        input_ds : Dataset for lifetest
        group : Group name 
        p_value : p value
        pfs_f : pfs=1, os=0
        *** Example ***
    */
    data temp_input;
        set &input_ds.;
        where os_day^=.;
    run;
    proc lifetest  
        data=temp_input stderr outsurv=temp_surv noprint alpha=&p_value. plot=survival;
        time os_day*censor(1);
    run;
    proc sql noprint;
        create table temp1
        as select *, &group. as group from temp_surv where os_day ^= . order by os_day;
    quit;
    data temp1;
        set temp_surv;
        where os_day^=.;
        group=&group.;
        temp_by=0;
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
/*        if first.temp_by=0 & last.temp_by=0 then do;
            output;
        end;*/
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
        temp_survival=setDecimalFormat(SURVIVAL*100);
        keep group temp_survival os_day;
        drop SURVIVAL;
        rename temp_survival=survival;
    run;
    proc lifetest 
        data=temp_input outsurv=temp2 noprint alpha=&p_value. timelist=1 2 3 reduceout;
        time os_years*censor(1);
    run;
    data output_&input_ds._annual;
        set temp2;
        temp_survival=setDecimalFormat(SURVIVAL*100);
        temp_lcl=setDecimalFormat(SDF_LCL*100);
        temp_ucl=setDecimalFormat(SDF_UCL*100);
        output=cat(compress(temp_survival), ' (', compress(temp_lcl), ' - ', compress(temp_ucl), ')');
        keep output;
    run;
%mend OS_FUNC;
%OS_FUNC(os_ope_group, &ope_group.);
%OS_FUNC(os_non_ope_group, &non_ope_group.);
%OS_FUNC(os_ope_non_chemo, &ope_non_chemo.);
%OS_FUNC(os_ope_chemo, &non_ope_chemo.);

