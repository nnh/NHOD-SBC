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
    ベースライン        3ヵ月       6ヵ月 */
%CREATE_OUTPUT_DS(output_ds=ds_tumor_reduction, items_label='腫瘍の縮小率');
data ds_input;
    set ptdata;
    where analysis_set=&non_ope_chemo.;
run;

proc sql;
/*        insert into ds_demog(title, items, ope_non_chemo_cnt)
            select '症例数', 'n', count from ds_n where Category=&ope_chemo.;*/
        insert into ds_demog(title, items, all_cnt, ope_chemo_cnt, ope_non_chemo_cnt, non_ope_chemo_cnt, non_ope_non_chemo_cnt)
            select distinct 
                    '症例数', 
                    'n', 
                    (select count from ds_n where Category=&efficacy_group.),
                    (select count from ds_n where Category=&ope_chemo.),
                    (select count from ds_n where Category=&ope_non_chemo.),
                    (select count from ds_n where Category=&non_ope_chemo.),
                    (select count from ds_n where Category=&non_ope_non_chemo.) from ds_n;
quit;
