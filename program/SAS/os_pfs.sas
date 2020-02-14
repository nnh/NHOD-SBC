**************************************************************************
Program Name : os_pfs.sas
Study Name : NHOD-SBC
Author : Ohtsuka Mariko
Date : 2020-2-13
SAS version : 9.4
**************************************************************************;
%macro OS_FUNC(input_ds, output_filename, group_var, input_years, target, p_value=0.05, pfs_f=0);
    /*  *** Functional argument *** 
        input_ds : Dataset for lifetest 
        output_filename : Output file name
        group_var : Group variable
        input_years : Time variable
        target : 
        p_value : p value
        pfs_f : pfs=1, os=0
        *** Example ***
        %OS_FUNC(ds_os, os_1, analysis_group, os_years);
    */
    %local temp_group group delim_count output_survrate;
    %let output_survrate=&output_filename._survrate;
    ods graphics /reset=index;
    ods listing close;
        ods rtf file="&outpath.\&output_filename..rtf";
            ods noptitle;
            %if &group_var.=. %then %do;
                ods select survivalplot;
                proc lifetest 
                    data=&input_ds. stderr outsurv=os alpha=&p_value. plot=survival;
                    time &input_years.*censor(1);
                run;
            %end;
            %else %do;
                ods select survivalplot HomTests;
                proc lifetest  
                    data=&input_ds. stderr outsurv=os alpha=&p_value. plot=survival;
                    strata &group_var.;
                    time &input_years.*censor(1);
                run;
            %end;
        ods rtf close;
    ods listing;
    ods graphics /reset=all;
    /* Annual survival rate */
    ods graphics /reset=index;
    ods listing close;
        ods rtf file="&outpath.\temp.rtf";
            %if &group_var.=. %then %do;
                proc lifetest 
                    data=&input_ds. outsurv=temp_survrate noprint alpha=&p_value. timelist=1 2 3 reduceout;
                    time &input_years.*censor(1);
                run;
                %let delim_count=0;
                %let temp_group=.;
            %end;
            %else %do;
                proc lifetest 
                    data=&input_ds. outsurv=temp_survrate noprint alpha=&p_value. timelist=1 2 3 reduceout;
                    strata &group_var.;
                    time &input_years.*censor(1);
                run;
                proc sql noprint;
                    select distinct &group_var. into: temp_group separated by ',' from temp_survrate;
                quit;
                %let delim_count = %sysfunc(count("&temp_group.", %quote(,)));
            %end;
            %do i = 1 %to %eval(&delim_count.+1);    
                %let group=%sysfunc(scan(%quote(&temp_group.), &i., %quote(,)));
                %if &group_var.=. %then %do;
                    data temp;
                        set temp_survrate;
                        label SURVIVAL=&non_ope_chemo.;
                        keep TIMELIST SURVIVAL SDF_LCL SDF_UCL;
                        rename SURVIVAL=SURVIVAL&i. SDF_LCL=SDF_LCL&i. SDF_UCL=SDF_UCL&i.;
                    run;
                %end;
                %else %do;
                    data temp;
                        set temp_survrate;
                        where &group_var.="&group.";
                        label SURVIVAL="&group.";
                        keep TIMELIST SURVIVAL SDF_LCL SDF_UCL;
                        rename SURVIVAL=SURVIVAL&i. SDF_LCL=SDF_LCL&i. SDF_UCL=SDF_UCL&i.;
                    run;
                %end;
                %if &i.=1 %then %do;
                    data &output_survrate.;
                        set temp;
                    run;
                %end;
                %else %do;
                    data temp_output_ds;
                        set &output_survrate.;
                    run;
                    proc delete data=&output_survrate.;
                    run;
                    proc sql noprint;
                        create table &output_survrate. as
                            select A.*, B.SURVIVAL&i., B.SDF_LCL&i., B.SDF_UCL&i. from temp_output_ds A inner join temp B on A.TIMELIST = B.TIMELIST;
                    quit;
                %end;
            %end;
        ods rtf close;
    ods listing;
    ods graphics /reset=all;

    %if &pfs_f.=1 %then %do;
        data os;
            set os;
            label _CENSOR_='打ち切り値: 0=増悪・再発・死亡 1=打ち切り';
        run;
    %end;
    /* Format a dataset */
    %do i = 1 %to %eval(&delim_count.+1);
        data &output_survrate._&i.;
            set &output_survrate.;
            temp_surv=round(SURVIVAL&i.*100, 0.1);
            temp_lcl=round(SDF_LCL&i.*100, 0.1);
            temp_ucl=round(SDF_UCL&i.*100, 0.1);
            surv=cat(compress(temp_surv), ' (', compress(temp_lcl), ' - ', compress(temp_ucl),') ');
            keep surv;
        run;
    %end;
    
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




%macro aaa(input_ds, group, p_value=0.05, pfs_f=0);
    /*  *** Functional argument *** 
        input_ds : Dataset for lifetest
        group : Group name 
        p_value : p value
        pfs_f : pfs=1, os=0
        *** Example ***
    */
    proc lifetest  
        data=&input_ds. stderr outsurv=temp1 noprint alpha=&p_value. plot=survival;
        time os_day*censor(1);
    run;
    proc lifetest 
        data=&input_ds. outsurv=temp2 noprint alpha=&p_value. timelist=1 2 3 reduceout;
        time os_years*censor(1);
    run;

    data temp3;
        set temp1;
        temp_by=1;
        group=&group.;
    run;
    data temp4;
        set temp3;
        by temp_by;
        if first.temp_by=0 & last.temp_by=0 then do;
            output;
        end;
    run;
    data temp5;
        set temp1 temp4;
    run;
    proc sql noprint;
        create table temp6
        as select * from temp5 order by os_day;
    quit;
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
        as select group, os_day, SURVIVAL, SDF_LCL, SDF_UCL from temp5 order by os_day;
        create table temp_os_censor
        as select group, os_day, SURVIVAL, SDF_LCL, SDF_UCL from temp_censor4 order by os_day, seq;
        create table os_annual;
        as select * from temp_os 
        union 
        select * from temp_os_censor;
    quit;

    data &input_ds._annual;
        set temp2;
        temp_survival=setDecimalFormat(SURVIVAL*100);
        temp_lcl=setDecimalFormat(SDF_LCL*100);
        temp_ucl=setDecimalFormat(SDF_UCL*100);
        output=cat(compress(temp_survival), ' (', compress(temp_lcl), ' - ', compress(temp_ucl), ')');
        keep output;
    run;
%mend;
%aaa(os_ope_group, 'AAA');

