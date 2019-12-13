**************************************************************************
Program Name : ae.sas
Study Name : NHOD-SBC
Author : Ohtsuka Mariko
Date : 2019-07-03
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
/*
��͑ΏیQ�F
1)�����؏��EChemotherapy�̉�͑ΏۏW�c
2)�������؏��EChemotherapy�̉�͑ΏۏW�c

���Ê��ԑS�̂�ʂ���
�@�@�@�@�@�@�@�@�@�@�@�@�@�@�@�ň��̃O���[�h�i�ᐔ�j
�@�@�@�@�@�@�@�@�@�@�@�@�@�@�@1     2   3   4
-----------------------------------------------------
�����_�o��Q  AE_MortoNeuropathy_trm AE_SensNeuropathy_trm
����  AE_diarrhea_trm 
���t�Ő�
�@�D��������  AE_DecreasNeut_trm
�@��������  AE_DecreasPLT_trm
�畆��Q    AE_Skin_trm
�H�~�s�U    AE_Anorexia_trm
������ AE_HighBDPRES_trm
�`���A AE_Prote_trm
-----------------------------------------------------
*/
%macro AE_EXEC;
    %local ds_output_ae varname_t i temp_varname temp_label;
    %let ds_output_ae=ds_ae;
    %let varname_t="AE_MortoNeuropathy,AE_SensNeuropathy,AE_diarrhea,AE_DecreasNeut,AE_Skin,AE_Anorexia,AE_HighBDPRES,AE_Prote";
    %let label_t="�����_�o��Q,����,�D��������,��������,�畆��Q,�H�~�s�U,������,�`���A";
    %let max_index = %sysfunc(countc(&varname_t., ','));
    %let max_index = %eval(&max_index. + 1);
    %CREATE_OUTPUT_DS(output_ds=&ds_output_ae., items_label='���Âɂ��L�Q����');
    %do i = 1 %to &max_index.; 
        data temp_ae_&i.;
            set &ds_output_ae.;
        run;
        %let temp_varname=%scan(&varname_t., &i., ",");
        %let temp_label=%scan(&label_t., &i., ",");
        %FREQ_FUNC(input_ds=ptdata, title=&temp_varname., cat_var=analysis_set, var_var=&temp_varname._grd, output_ds=temp_ae_&i.);

    %end;
%mend AE_EXEC;
%AE_EXEC;
