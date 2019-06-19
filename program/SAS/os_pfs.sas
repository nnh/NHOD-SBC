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
/* �f�f�����玀�S�܂ł̊��ԂƂ���B������ƒǐՕs�\��ł͍ŏI�����m�F���������đł��؂�Ƃ���B*/
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
/* Kaplan-Meier�Ȑ���log-rank���� */
/*1)�����؏��̉�͑ΏۏW�c�Ǝ������؏��̉�͑ΏۏW�c
2)�����؏��Enon-Chemotherapy�̉�͑ΏۏW�c�Ǝ����؏��EChemotherapy�̉�͑ΏۏW�c
3)�������؏��EnonChemotherapy�̉�͑ΏۏW�c�Ǝ������؏��EChemotherapy�̉�͑ΏۏW�c*/
%OS_FUNC(ds_os, os_1, analysis_group);
%OS_FUNC(ds_ope_os, os_2, analysis_set);
%OS_FUNC(ds_non_ope_os, os_3, analysis_set);

/* Kaplan-Meier�@�ɂ��N���̐����� */
/* �C�x���g*/
