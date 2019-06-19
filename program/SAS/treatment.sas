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

%macro SET_FREQ(output_ds_name, str_label, var, str_keep, csv_name);
    /*  *** Functional argument *** 
        output_ds_name : Name of the data set to output
        str_label : Title
        var : Target variable name of input data set
        str_keep : Variables to leave in the output data set
        csv_name : csv name
        *** Example ***
        %SET_FREQ(ds_surgical_curability, '手術の根治度', resectionCAT, %str(ope_non_chemo_cnt ope_non_chemo_per ope_chemo_cnt ope_chemo_per), surgical_curability.csv);
    */
    %CREATE_OUTPUT_DS(output_ds=&output_ds_name.)
    proc contents data=&output_ds_name. out=ds_colnames varnum noprint; run;
    %FREQ_FUNC(var_var=&var., output_ds=&output_ds_name.);
    data &output_ds_name.;
        set &output_ds_name.;
        if _N_=1 then title=&str_label;
        keep title items &str_keep.;
    run;
    %ds2csv (data=&output_ds_name., runmode=b, csvfile=&outpath.\&csv_name., labels=Y);
%mend SET_FREQ;

**************************************************************************;
%let thisfile=%GET_THISFILE_FULLPATH;
%let projectpath=%GET_DIRECTORY_PATH(&thisfile., 3);
%inc "&projectpath.\program\sas\analysis_sets.sas";
**************************************************************************;
%SET_FREQ(ds_surgical_curability, '手術の根治度', resectionCAT, %str(ope_non_chemo_cnt ope_non_chemo_per ope_chemo_cnt ope_chemo_per), surgical_curability.csv);
%SET_FREQ(ds_adjuvant_chemo_regimen, 'アジュバント化学療法レジメン', adjuvantCAT, %str(ope_chemo_cnt ope_chemo_per), adjuvant_chemo_regimen.csv);
%SET_FREQ(ds_first_line_chemo_regimen, '第一選択化学療法レジメン', chemCAT, %str(non_ope_chemo_cnt non_ope_chemo_per), first_line_chemo_regimen.csv);
%let temp_str_keep=%str(ope_non_chemo_cnt ope_non_chemo_per ope_chemo_cnt ope_chemo_per non_ope_non_chemo_cnt non_ope_non_chemo_per non_ope_chemo_cnt non_ope_chemo_per);
%SET_FREQ(ds_primary_site_resection, '原発巣切除の有無', PLresectionYN, &temp_str_keep., primary_site_resection.csv);
