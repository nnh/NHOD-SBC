**************************************************************************
Program Name : ae.sas
Study Name : NHOD-SBC
Author : Ohtsuka Mariko
Date : 2019-12-24
SAS version : 9.4
**************************************************************************;
%macro AE_EXEC(target_column, output_ds);
    /*  *** Functional argument *** 
        target_column : Output target group
        output_ds : Output dataset name
        *** Example ***
        %AE_EXEC(ope_chemo_cnt, ae_ope_chemo);
    */
    %local ds_output_ae varname_t i temp_varname temp_label max_index colname;
    %let varname_t="AE_MortoNeuropathy,AE_SensNeuropathy,AE_diarrhea,AE_DecreasNeut,AE_DecreasPLT,AE_Skin,AE_Anorexia,AE_HighBDPRES,AE_Prote";
    %let label_t="末梢性運動ニューロパチー,末梢性感覚ニューロパチー,下痢,好中球減少,血小板減少,皮膚障害,食欲不振,高血圧,蛋白尿";
    %let max_index = %sysfunc(countc(&varname_t., ','));
    %let max_index = %eval(&max_index. + 1);
    %do i = 1 %to &max_index.; 
        %let temp_varname=%scan(&varname_t., &i., ",");
        %let temp_label=%scan(&label_t., &i., ",");
        %SET_FREQ(temp_ae, '治療による有害事象', &temp_varname._grd, %str(&target_column.), .);
        /* Remove unnecessary space in items */
        data ae_&i.;
            set temp_ae(rename=(items=temp_items));
            items=strip(temp_items);
            drop temp_items;
        run;
        /* Form a AE table */
        %let colname=B.&target_column.;
        %JOIN_TO_TEMPLATE(ae_&i., temp_join_ae, %quote(items char(1), &target_column. num), items, %quote(&colname.), %quote('1', '2', '3', '4'), &temp_label.);
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
                    select A.*, &colname. as &target_column.&i. from temp_output_ds A inner join temp_join_ae B on A.items = B.items;
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
        drop _NAME_;
    run;
%mend AE_EXEC;
%AE_EXEC(ope_chemo_cnt, ae_ope_chemo);
%AE_EXEC(non_ope_chemo_cnt, ae_non_ope_chemo);
