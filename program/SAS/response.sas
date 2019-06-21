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

/* 5.5.3. ¡—Ã‚Ì‘tŒøŠ„‡
‰ğÍ‘ÎÛŒQF
¡–üØœEnonCT‚Ì‰ğÍ‘ÎÛW’c
¡–üØœECT‚Ì‰ğÍ‘ÎÛW’c
¡–ü–¢ØœECT‚Ì‰ğÍ‘ÎÛW’c
*/
%CREATE_OUTPUT_DS(output_ds=ds_res, items_label='¡—Ã‚Ì‘tŒøŠ„‡');
proc contents data=ds_res out=ds_colnames varnum noprint; run;
%macro RES_FUNC;
    %local temp_fmt1 temp_fmt2 const_cat1 const_cat2;
    %let const_cat1=chemCAT;
    %let const_cat2=adjuvantCAT;
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
    %EXEC_FREQ(ds_input_res, %str(analysis_set*RECISTORRES*regimen), ds_res);
    data ds_res_1 ds_res_2 ds_res_3;
        set ds_res;
        if analysis_set=&ope_non_chemo. then do;
            output ds_res_1;
        end;
        else if analysis_set=&ope_chemo. then do;
            output ds_res_2;
        end;
        else if analysis_set=&non_ope_chemo. then do;
            output ds_res_3;
        end;
    run;
%mend RES_FUNC;
%RES_FUNC;
