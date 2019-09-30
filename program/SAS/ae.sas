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
解析対象群：
1)治癒切除・Chemotherapyの解析対象集団
2)治癒未切除・Chemotherapyの解析対象集団

治療期間全体を通じて
　　　　　　　　　　　　　　　最悪のグレード（例数）
　　　　　　　　　　　　　　　1     2   3   4
-----------------------------------------------------
末梢神経障害  AE_MortoNeuropathy_trm AE_SensNeuropathy_trm
下痢  AE_diarrhea_trm 
血液毒性
　好中球減少  AE_DecreasNeut_trm
　血小板減少  AE_DecreasPLT_trm
皮膚障害    AE_Skin_trm
食欲不振    AE_Anorexia_trm
高血圧 AE_HighBDPRES_trm
蛋白尿 AE_Prote_trm
-----------------------------------------------------
*/
%macro AE_EXEC;
    %local ds_output_ae varname_t i temp_varname temp_label;
    %let ds_output_ae=ds_ae;
    %let varname_t="AE_MortoNeuropathy,AE_SensNeuropathy,AE_diarrhea,AE_DecreasNeut,AE_Skin,AE_Anorexia,AE_HighBDPRES,AE_Prote";
    %let label_t="末梢神経障害,下痢,好中球減少,血小板減少,皮膚障害,食欲不振,高血圧,蛋白尿";
    %let max_index = %sysfunc(countc(&varname_t., ','));
    %let max_index = %eval(&max_index. + 1);
    %CREATE_OUTPUT_DS(output_ds=&ds_output_ae., items_label='治療による有害事象');
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

