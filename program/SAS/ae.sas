**************************************************************************
Program Name : ae.sas
Study Name : NHOD-SBC
Author : Ohtsuka Mariko
Date : 2020-02-13
SAS version : 9.4
**************************************************************************;
%macro AE_EXEC(target_column, output_ds);
    /*  *** Functional argument *** 
        target_column : Output target group
        output_ds : Output dataset name
        *** Example ***
        %AE_EXEC(ope_chemo_cnt, ae_ope_chemo);
    */
    %local varname_t max_index i temp_varname temp_label;
    %let varname_t="AE_MortoNeuropathy,AE_SensNeuropathy,AE_diarrhea,dummy,AE_DecreasNeut,
                    AE_DecreasPLT,AE_Skin,AE_Anorexia,AE_HighBDPRES,AE_Prote";
    %let max_index = %sysfunc(countc(&varname_t., ','));
    %let max_index = %eval(&max_index. + 1);
    %do i = 1 %to &max_index.; 
        %let temp_varname=%scan(&varname_t., &i., ",");
        %CREATE_OUTPUT_DS(output_ds=ds_ae, items_label='é°ó√Ç…ÇÊÇÈóLäQéñè€');
        %FREQ_FUNC(input_ds=input_ae, title='', cat_var=analysis_set, var_var=&temp_varname._grd, output_ds=temp_freq, contents=ae_contents);
        data temp_freq_num;
            set temp_freq(rename=(items=temp_items));
            items=input(compress(temp_items), best.);
        run;
        %JOIN_TO_TEMPLATE(temp_freq_num, temp_join_ae, %quote(items num, &target_column. num), 
                            items, %quote(1, 2, 3, 4), %quote(B.&target_column. label="&target_column."));
        %if &i. = 1 %then %do;
            data join_ae;
                set temp_join_ae(rename=(&target_column.=&target_column.&i.));
            run;
        %end;
        %else %do;
            data temp_output_ds;
                set join_ae;
            run;
            proc delete data=join_ae;
            run;
            proc sql noprint;
                create table join_ae as
                    select A.*, B.&target_column. as &target_column.&i. 
                    from temp_output_ds A inner join temp_join_ae B on A.items = B.items;
            quit;
        %end;
    %end;
    /* Transpose and delete unnecessary variables */
    proc transpose data=join_ae out=&output_ds.;
        id items;
        var &target_column.1-&target_column.&max_index.;
    run;
    data &output_ds.;
        set &output_ds.(rename=(_LABEL_=ae));
        label ae='grade';
        drop _NAME_ ae;
    run;        
%mend AE_EXEC;
data input_ae;
    set ptdata;
    dummy_grd=.;
run;
proc contents data=input_ae out=temp_ae_contents varnum noprint; run;
data ae_contents;
    set temp_ae_contents(rename=(FORMAT=temp_format));
    attrib FORMAT label="ïœêîèoóÕå`éÆ" length=$32 format=$32.;
    FORMAT = "$";
run;
%AE_EXEC(ope_chemo_cnt, ae_ope_chemo);
%AE_EXEC(non_ope_chemo_cnt, ae_non_ope_chemo);
