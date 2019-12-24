**************************************************************************
Program Name : ae.sas
Study Name : NHOD-SBC
Author : Ohtsuka Mariko
Date : 2019-12-24
SAS version : 9.4
**************************************************************************;
/*
解析対象群：
1)治癒切除・Chemotherapyの解析対象集団
2)治癒未切除・Chemotherapyの解析対象集団

治療期間全体を通じて
　　　　　　　　　　　　　　　最悪のグレード（例数）
　　　　　　　　　　　　　　　1     2   3   4
-----------------------------------------------------
末梢神経障害  AE_MortoNeuropathy_trm AE_SensNeuropathy_trm
下痢  AE_diarrhea_trm 
血液毒性
　好中球減少  AE_DecreasNeut_trm
　血小板減少  AE_DecreasPLT_trm
皮膚障害    AE_Skin_trm
食欲不振    AE_Anorexia_trm
高血圧 AE_HighBDPRES_trm
蛋白尿 AE_Prote_trm
-----------------------------------------------------
*/
%macro AE_EXEC(target_column, output_ds);
    %local ds_output_ae varname_t i temp_varname temp_label max_index colname;
    %let varname_t="AE_MortoNeuropathy,AE_SensNeuropathy,AE_diarrhea,AE_DecreasNeut,AE_Skin,AE_Anorexia,AE_HighBDPRES,AE_Prote";
    %let label_t="末梢神経障害,下痢,好中球減少,血小板減少,皮膚障害,食欲不振,高血圧,蛋白尿";
    %let max_index = %sysfunc(countc(&varname_t., ','));
    %let max_index = %eval(&max_index. + 1);
    %do i = 1 %to &max_index.; 
        %let temp_varname=%scan(&varname_t., &i., ",");
        %let temp_label=%scan(&label_t., &i., ",");
        %SET_FREQ(temp_ae, '治療による有害事象', &temp_varname._grd, %str(ope_chemo_cnt), response_ope_no_chemo.csv);
        data ae_&i.;
            set temp_ae(rename=(items=temp_items));
            items=strip(temp_items);
            drop temp_items;
        run;
        %let colname=B.&target_column.;
        %JOIN_TO_TEMPLATE(ae_&i., temp_join_ae, %quote(items char(1), &target_column. num), items, %quote(&colname.), %quote('1', '2', '3', '4'), &temp_label.);
        %if &i.=1 %then %do;
            data &output_ds.;
                set temp_join_ae(rename=(&target_column.=&temp_varname.));
            run;
        %end;
        %else %do;
            data temp_output_ds;
                set &output_ds.;
            run;
            proc delete data=&output_ds.;
            run;
            proc sql noprint;
                create table &output_ds. as
                    select A.*, &colname. as &temp_varname. from temp_output_ds A inner join temp_join_ae B on A.items = B.items;
            quit;
        %end;
    %end;
%mend AE_EXEC;
%AE_EXEC(ope_chemo_cnt, ae_ope_chemo_cnt);
