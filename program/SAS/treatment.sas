**************************************************************************
Program Name : treatment.sas
Study Name : NHOD-SBC
Author : Ohtsuka Mariko
Date : 2019-06-14
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

%macro EDIT_DS_ALL(ds=temp_all_ds, cat_var=analysis_set, char_len=100, cat_str=&all_group.);
    data &ds.;
        set &ds.;
        format &cat_var. $&char_len..; 
        &cat_var.=&cat_str.;
    run;
%mend EDIT_DS_ALL;

%macro SET_FREQ(output_ds_name, str_label, var, str_keep, csv_name);
    %CREATE_OUTPUT_DS(output_ds=&output_ds_name., items_label=&str_label.)
    proc contents data=&output_ds_name. out=ds_colnames varnum noprint; run;
    %FREQ_FUNC(var_var=&var., output_ds=&output_ds_name.);
    data &output_ds_name.;
        set &output_ds_name.;
        keep title items &str_keep.;
    run;
    %ds2csv (data=&output_ds_name., runmode=b, csvfile=&outpath.\&csv_name., labels=Y);
%mend SET_FREQ;

**************************************************************************;
%let thisfile=%GET_THISFILE_FULLPATH;
%let projectpath=%GET_DIRECTORY_PATH(&thisfile., 3);
%inc "&projectpath.\program\sas\analysis_sets.sas";
**************************************************************************;
%SET_FREQ(ds_surgical_curability, 'éËèpÇÃç™é°ìx', resectionCAT, %str(ope_non_chemo_cnt ope_non_chemo_per ope_chemo_cnt ope_chemo_per), surgical_curability.csv);
*The adjuvant  chemotherapy regimen;
