**************************************************************************
Program Name : tumor_reduction.sas
Study Name : NHOD-SBC
Author : Ohtsuka Mariko
Date : 2019-06-25
SAS version : 9.4
**************************************************************************;
%macro TUMOR_REDUCTION_EXEC;
    %local ds_output_tumor varname_t label_t i temp_varname temp_label;
    %let ds_output_tumor=ds_tumor_reduction;
    %let varname_t="SBCsum,Lesion3m,Lesion6m";
    %let label_t="ベースライン,3ヵ月,6ヵ月";
    %CREATE_OUTPUT_DS(output_ds=&ds_output_tumor., items_label='腫瘍の縮小率');
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
    *proc datasets lib=work nolist; save &ds_output_tumor.; quit;
%mend TUMOR_REDUCTION_EXEC;
%TUMOR_REDUCTION_EXEC;
