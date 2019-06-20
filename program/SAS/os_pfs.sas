**************************************************************************
Program Name : os_pfs.sas
Study Name : NHOD-SBC
Author : Ohtsuka Mariko
Date : 2019-06-19
SAS version : 9.4
**************************************************************************;
*Define constants;
**************************************************************************;
*Define macros;
%macro GET_THISFILE_FULLPATH;
    %local _fullpath _path;
    %let _fullpath=;
    %let _path=;

    %if %length(%sysfunc(getoption(sysin)))=0 %then
      %let _fullpath=%sysget(sas_execfilepath);
    %else
      %let _fullpath=%sysfunc(getoption(sysin));
    &_fullpath.
%mend GET_THISFILE_FULLPATH;

%macro GET_DIRECTORY_PATH(input_path, directory_level);
    %let input_path_len=%length(&input_path.);
    %let temp_path=&input_path.;
    %do i = 1 %to &directory_level.;
        %let temp_len=%scan(&temp_path., -1, '\');
        %let temp_path=%substr(&temp_path., 1, %length(&temp_path.)-%length(&temp_len.)-1);
        %put &temp_path.;
    %end;
    %let _path=&temp_path.;
    &_path.
%mend GET_DIRECTORY_PATH;
%macro OS_FUNC(input_ds, output_filename, group_var, input_years);
    ods graphics on;
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
    ods graphics off;

    proc export data=os
        outfile="&outpath.\&output_filename..csv"
        dbms=csv replace;
    run;
%mend OS_FUNC;

**************************************************************************;
%let thisfile=%GET_THISFILE_FULLPATH;
%let projectpath=%GET_DIRECTORY_PATH(&thisfile., 3);
%inc "&projectpath.\program\sas\analysis_sets.sas";
**************************************************************************;
data ds_os ds_ope_os ds_non_ope_os;
/* 5.5.1. 全生存期間（OS） */
/* 診断日から死亡までの期間とする。生存例と追跡不能例では最終生存確認日をもって打ち切りとする。*/
    set ptdata;
    if DTHFL=1 then do;
        os_day=DTHDTC-DIGDTC;
        censor=0;
    end;
    if DTHFL ne 1 then do;
        os_day=SURVDTC-DIGDTC;
        censor=1;
    end;
    os_years=round((os_day/365), 0.001);
    keep censor os_years analysis_set analysis_group;
    output ds_os;
    if analysis_group=&ope_group. then do;
        output ds_ope_os;
    end;
    if analysis_group=&non_ope_group. then do;
        output ds_non_ope_os;
    end;
run;
/* Kaplan-Meier曲線とlog-rank検定 */
/*1)治癒切除の解析対象集団と治癒未切除の解析対象集団
2)治癒切除・non-Chemotherapyの解析対象集団と治癒切除・Chemotherapyの解析対象集団
3)治癒未切除・nonChemotherapyの解析対象集団と治癒未切除・Chemotherapyの解析対象集団*/
%OS_FUNC(ds_os, os_1, analysis_group, os_years);
%OS_FUNC(ds_ope_os, os_2, analysis_set, os_years);
%OS_FUNC(ds_non_ope_os, os_3, analysis_set, os_years);

/* Kaplan-Meier法による年次の生存率 */
/* イベント*/
%CREATE_OUTPUT_DS(output_ds=ds_death, items_label='イベント');
proc contents data=ds_death out=ds_colnames varnum noprint; run;
%FREQ_FUNC(cat_var=analysis_set, var_var=DTHFL, output_ds=ds_death);
data ds_death;
    set ds_death;
    where items='1';
    if _N_=1 then title='死亡';
run;
/* 無増悪生存期間（PFS） */
/*起点日から、増悪・再発RECURRYNと判断された日RECURRDTCまたは死亡日DTHDTCのうち早い方までの期間とする。
増悪と判断されていない生存例では臨床的に増悪がないことが確認された最終日（最終無増悪生存確認日SURVDTC）をもって打ち切りとする。
追跡不能例では追跡不能となる以前で生存が確認されていた最終日SURVDTCをもって打ち切りとする。
Kaplan-Meier法により生存曲線を図示し、log-rank検定を実施する。増悪の定義はRECISTガイドラインに従う。
解析集団と起点日は以下を対象とする。
1) 治癒切除・non-Chemotherapyの解析対象集団、起点日は切除日
2) 治癒切除・Chemotherapyの解析対象集団、起点日は切除日
3) 治癒未切除・Chemotherapyの解析対象集団、起点日は一次治療の投与開始日
4)治癒未切除・non-Chemotherapyの解析対象集団、起点日は診断日
*/
%macro EDIT_DS_PFS;
    %local const_pfs_end_date;
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
        /* 死亡日より増悪判断日が早ければ更新 */
        update ds_pfs set pfs_end_date = RECURRDTC, censor = 0 where (RECURRYN = 2) and (RECURRDTC < pfs_end_date);
        /* 生存確認日 */
        update ds_pfs set pfs_end_date = SURVDTC, censor = 0 where (DTHFL ne '1') and (RECURRYN ne 2) and (pfs_start_date ne .) and (pfs_end_date ne .);
        update ds_pfs set pfs_days = pfs_end_date - pfs_start_date, pfs_years = round(((pfs_end_date - pfs_start_date)/365), 0.001);
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
%EDIT_DS_PFS;
%OS_FUNC(ds_pfs, pfs_1, analysis_group, pfs_years);
%OS_FUNC(ds_ope_pfs, pfs_2, analysis_set, pfs_years);
%OS_FUNC(ds_non_ope_chemo_pfs, pfs_3, analysis_set, pfs_years);
