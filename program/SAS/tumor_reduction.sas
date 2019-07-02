**************************************************************************
Program Name : tumor_reduction.sas
Study Name : NHOD-SBC
Author : Ohtsuka Mariko
Date : 2019-06-25
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
/* 解析対象群：
治癒未切除・Chemotherapyの解析対象集団
─────────────────────────────
    ベースライン        3ヵ月Lesion3m       6ヵ月 */
%let ds_output_tumor=ds_tumor_reduction;
%let varname_t="SBCsum,Lesion3m,Lesion6m";
%let label_t="ベースライン,3ヵ月,6ヵ月";
%CREATE_OUTPUT_DS(output_ds=&ds_output_tumor., items_label='腫瘍の縮小率');
data temp_1 temp_2 temp_3;
    set &ds_output_tumor.;
run;
%TO_NUM_TEST_RESULTS(var=SBCsum)
%MEANS_FUNC(title='SBCsum', var_var=SBCsum_num, output_ds=temp_1);
%TO_NUM_TEST_RESULTS(var=Lesion3m)
%MEANS_FUNC(title='Lesion3m', var_var=Lesion3m_num, output_ds=temp_2);
%TO_NUM_TEST_RESULTS(var=Lesion6m)
%MEANS_FUNC(title='Lesion6m', var_var=Lesion6m_num, output_ds=temp_3);
data ds3;
    set temp_1(keep=non_ope_chemo_cnt rename=(non_ope_chemo_cnt=aaa));
    label aaa='ベースライン';
run;

%macro aaa;
    %local i;
    %do i = 1 %to 3; 
        %let temp_varname=%scan(&varname_t., &i., "," );
        data abc;
            set temp_&i.(keep=non_ope_chemo_cnt rename=(non_ope_chemo_cnt=&temp_varname.&i.));
        run;
    %end; 
    *    label aaa='ベースライン';
%mend;
%aaa;
