**************************************************************************
Program Name : tumor_reduction.sas
Study Name : NHOD-SBC
Author : Ohtsuka Mariko
Date : 2020-02-12
SAS version : 9.4
**************************************************************************;
%macro TUMOR_REDUCTION_EXEC;
    %local varname_t label_t i temp_varname temp_label;
    %let varname_t="SBCsum,Lesion3m,Lesion6m";
    %let label_t="ベースライン,3ヵ月,6ヵ月";
    %CREATE_OUTPUT_DS(output_ds=ds_t018, items_label='腫瘍の縮小率');
    %do i = 1 %to 3; 
        data temp&i.;
            set ds_t018;
        run;
        %let temp_varname=%scan(&varname_t., &i., "," );
        %let temp_label=%scan(&label_t., &i., "," );
        %TO_NUM_TEST_RESULTS(var=&temp_varname.);
        %MEANS_FUNC(title="&temp_varname.", var_var=&temp_varname._num, output_ds=temp&i., output_flg=1);
        data temp&i.;
            set temp&i.;
            keep items non_ope_chemo_cnt;
        run;
    %end; 
    proc sql noprint;
        create table temp_ds_t018
        as select a.*, b.non_ope_chemo_cnt as Lesion3m
        from temp1 as a, temp2 as b
        where a.items = b.items;
        create table ds_t018
        as select a.*, b.non_ope_chemo_cnt as Lesion6m
        from temp_ds_t018 as a, temp3 as b
        where a.items = b.items;
    quit;
    data ds_t018;
        set ds_t018;
        drop items;
    run;
%mend TUMOR_REDUCTION_EXEC;
%TUMOR_REDUCTION_EXEC;
