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
%macro TUMOR_REDUCTION_EXEC;
    %local ds_output_tumor varname_t label_t i temp_varname temp_label;
    %let ds_output_tumor=ds_tumor_reduction;
    %let varname_t="SBCsum,Lesion3m,Lesion6m";
    %let label_t="�x�[�X���C��,3����,6����";
    %CREATE_OUTPUT_DS(output_ds=&ds_output_tumor., items_label='��ᇂ̏k����');
    %do i = 1 %to 3; 
        data temp_&i.;
            set &ds_output_tumor.;
        run;
        %let temp_varname=%scan(&varname_t., &i., "," );
        %let temp_label=%scan(&label_t., &i., "," );
        %TO_NUM_TEST_RESULTS(var=&temp_varname.);
        %MEANS_FUNC(title="&temp_varname.", var_var=&temp_varname._num, output_ds=temp_&i.);
        data temp_tumor;
            %if %sysfunc(exist(work.temp_tumor)) %then %do;
                set temp_tumor;
            %end;
            set temp_&i.(keep=items non_ope_chemo_cnt rename=(non_ope_chemo_cnt=&temp_varname.));
            label &temp_varname.=&temp_label.;
        run;
    %end; 
    data &ds_output_tumor.;
        set temp_tumor;
        if _N_=1 then delete;
    run;
    * Delete the working dataset;
    /*proc datasets lib=work nolist; save &ds_output_tumor.; quit;*/
%mend TUMOR_REDUCTION_EXEC;
%TUMOR_REDUCTION_EXEC;
