**************************************************************************
Program Name : response.sas
Study Name : NHOD-SBC
Author : Ohtsuka Mariko
Date : 2019-06-21
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

**************************************************************************;
%let thisfile=%GET_THISFILE_FULLPATH;
%let projectpath=%GET_DIRECTORY_PATH(&thisfile., 3);
%inc "&projectpath.\program\sas\analysis_sets.sas";
**************************************************************************;

/* 5.5.3. ���Â̑t������
��͑ΏیQ�F
�����؏��EnonCT�̉�͑ΏۏW�c
�����؏��ECT�̉�͑ΏۏW�c
�������؏��ECT�̉�͑ΏۏW�c
*/
%CREATE_OUTPUT_DS(output_ds=ds_res, items_label='���Â̑t������');
proc contents data=ds_res out=ds_colnames varnum noprint; run;
data temp_freq ds_res_1 ds_res_2 ds_res_3;
    set ds_res;
run;
%macro RES_FUNC;
    %local temp_fmt1 temp_fmt2 const_cat1 const_cat2 target_regimen i j temp_target_regimen;
    %let const_cat1=chemCAT;
    %let const_cat2=adjuvantCAT;
    /* ���w�Ö@�̎�ނ̕�������擾���Aregimen��Ɋi�[ */
    %do i = 1 %to 2;
        %GET_VAR_FORMAT(ptdata_contents, "&&const_cat&i.", temp_fmt&i.);
        %let temp_fmt&i.=%sysfunc(compress(&&temp_fmt&i.));
    %end;
    data ds_input_res;    
        set ptdata;
        if &const_cat1. ne '' then do;
            regimen=put(&const_cat1., &temp_fmt1..);
        end;
        else if &const_cat2. ne '' then do;
            regimen=put(&const_cat2., &temp_fmt2..);
        end;
    run;
    proc sql noprint;
        /* ���W�����ŕ����� */
        create table temp_regimen as select distinct regimen from ds_input_res where regimen ne '';
        select count(*) into:regimen_count from temp_regimen;
        /* �o�̓e�[�u���̍쐬 */
        create table ds_output_1 as select distinct RECISTORRES from ptdata where RECISTORRES ne .;
        create table ds_output_2 like ds_output_1;
        create table ds_output_3 like ds_output_1;
    quit;
    %do i = 1 %to &regimen_count.;
        /* ���o�Ώۂ̃��W��������ϐ��Ɋi�[ */
        data _NULL_;
            set temp_regimen(firstobs=&i. obs=&i.);
            if _N_=1 then call symput('target_regimen', regimen);
        run;
        data temp;
            set ds_input_res;
            where regimen="&target_regimen.";
        run;
        %EXEC_FREQ(temp, %str(analysis_set*RECISTORRES), temp_freq);
        data temp_freq;
            set temp_freq;
            /* �ϐ����Ɏg���Ȃ����߁A���W����������󔒂ƋL�����폜���� */
            %let temp_target_regimen=%sysfunc(compress(&target_regimen.,,kf));
            %let temp_target_regimen=%sysfunc(compress(&temp_target_regimen.));
            %put &temp_target_regimen.;
            rename count=&temp_target_regimen._cnt percent=&temp_target_regimen._per;
            label count=&target_regimen. percent=&target_regimen._per;
        run;
        data temp_res_1 temp_res_2 temp_res_3;
            set temp_freq;
            if analysis_set=&ope_non_chemo. then do;
                output temp_res_1;
            end;
            else if analysis_set=&ope_chemo. then do;
                output temp_res_2;
            end;
            else if analysis_set=&non_ope_chemo. then do;
                output temp_res_3;
            end;
        run;
        %do j = 1 %to 3;
            data ds_output_&j.;
                merge ds_output_&j. temp_res_&j.;
                by RECISTORRES;
            run;
        %end;
    %end;
%mend RES_FUNC;
%RES_FUNC;
