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
%macro OS_FUNC(input_ds, output_filename, group_var);
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
                time os_years*censor(1);
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
data ds_os ds_ope_os ds_non_ope_os ds_death;
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
    if censor=0 then do;
        output ds_death;
    end;

run;
/* Kaplan-Meier曲線とlog-rank検定 */
/*1)治癒切除の解析対象集団と治癒未切除の解析対象集団
2)治癒切除・non-Chemotherapyの解析対象集団と治癒切除・Chemotherapyの解析対象集団
3)治癒未切除・nonChemotherapyの解析対象集団と治癒未切除・Chemotherapyの解析対象集団*/
%OS_FUNC(ds_os, os_1, analysis_group);
%OS_FUNC(ds_ope_os, os_2, analysis_set);
%OS_FUNC(ds_non_ope_os, os_3, analysis_set);

/* Kaplan-Meier法による年次の生存率 */
/* イベント*/
