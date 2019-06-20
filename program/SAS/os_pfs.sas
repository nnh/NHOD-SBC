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
/* 5.5.1. �S�������ԁiOS�j */
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
run;
/* Kaplan-Meier�Ȑ���log-rank���� */
/*1)�����؏��̉�͑ΏۏW�c�Ǝ������؏��̉�͑ΏۏW�c
2)�����؏��Enon-Chemotherapy�̉�͑ΏۏW�c�Ǝ����؏��EChemotherapy�̉�͑ΏۏW�c
3)�������؏��EnonChemotherapy�̉�͑ΏۏW�c�Ǝ������؏��EChemotherapy�̉�͑ΏۏW�c*/
%OS_FUNC(ds_os, os_1, analysis_group, os_years);
%OS_FUNC(ds_ope_os, os_2, analysis_set, os_years);
%OS_FUNC(ds_non_ope_os, os_3, analysis_set, os_years);

/* Kaplan-Meier�@�ɂ��N���̐����� */
/* �C�x���g*/
%CREATE_OUTPUT_DS(output_ds=ds_death, items_label='�C�x���g');
proc contents data=ds_death out=ds_colnames varnum noprint; run;
%FREQ_FUNC(cat_var=analysis_set, var_var=DTHFL, output_ds=ds_death);
data ds_death;
    set ds_death;
    where items='1';
    if _N_=1 then title='���S';
run;
/* �������������ԁiPFS�j */
/*�N�_������A�����E�Ĕ�RECURRYN�Ɣ��f���ꂽ��RECURRDTC�܂��͎��S��DTHDTC�̂����������܂ł̊��ԂƂ���B
�����Ɣ��f����Ă��Ȃ�������ł͗Տ��I�ɑ������Ȃ����Ƃ��m�F���ꂽ�ŏI���i�ŏI�����������m�F��SURVDTC�j�������đł��؂�Ƃ���B
�ǐՕs�\��ł͒ǐՕs�\�ƂȂ�ȑO�Ő������m�F����Ă����ŏI��SURVDTC�������đł��؂�Ƃ���B
Kaplan-Meier�@�ɂ�萶���Ȑ���}�����Alog-rank��������{����B�����̒�`��RECIST�K�C�h���C���ɏ]���B
��͏W�c�ƋN�_���͈ȉ���ΏۂƂ���B
1) �����؏��Enon-Chemotherapy�̉�͑ΏۏW�c�A�N�_���͐؏���
2) �����؏��EChemotherapy�̉�͑ΏۏW�c�A�N�_���͐؏���
3) �������؏��EChemotherapy�̉�͑ΏۏW�c�A�N�_���͈ꎟ���Â̓��^�J�n��
4)�������؏��Enon-Chemotherapy�̉�͑ΏۏW�c�A�N�_���͐f�f��
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
        /* ���S����葝�����f����������΍X�V */
        update ds_pfs set pfs_end_date = RECURRDTC, censor = 0 where (RECURRYN = 2) and (RECURRDTC < pfs_end_date);
        /* �����m�F�� */
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
