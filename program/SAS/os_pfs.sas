**************************************************************************
Program Name : os_pfs.sas
Study Name : NHOD-SBC
Author : Ohtsuka Mariko
Date : 2020-1-7
SAS version : 9.4
**************************************************************************;
%macro OS_FUNC(input_ds, output_filename, group_var, input_years, p_value=0.05, pfs_f=0);
    /*  *** Functional argument *** 
        input_ds : Dataset for lifetest 
        output_filename : Output file name
        group_var : Group variable
        input_years : Time variable
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
    
    proc export data=os
        outfile="&outpath.\&output_filename..csv"
        label
        dbms=csv replace;
    run;
    proc export data=&output_survrate.
        outfile="&outpath.\&output_survrate..csv"
        label
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
%OS_FUNC(ds_os, _5_5_1_os_1, analysis_group, os_years);
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
%ds2csv (data=ds_death, runmode=b, csvfile=&outpath.\_5_5_1_os_event.csv, labels=Y);

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
%ds2csv (data=ds_pfs_event, runmode=b, csvfile=&outpath.\_5_5_2_pfs_event.csv, labels=Y);
