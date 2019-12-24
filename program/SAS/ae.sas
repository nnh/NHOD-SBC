**************************************************************************
Program Name : ae.sas
Study Name : NHOD-SBC
Author : Ohtsuka Mariko
Date : 2019-12-24
SAS version : 9.4
**************************************************************************;
/*
πΝΞΫQF
1)‘όΨEChemotherapyΜπΝΞΫWc
2)‘ό’ΨEChemotherapyΜπΝΞΫWc

‘ΓϊΤSΜπΚΆΔ
@@@@@@@@@@@@@@@Ε«ΜO[hiαj
@@@@@@@@@@@@@@@1     2   3   4
-----------------------------------------------------
½_oαQ  AE_MortoNeuropathy_trm AE_SensNeuropathy_trm
Ί  AE_diarrhea_trm 
tΕ«
@DΈ­  AE_DecreasNeut_trm
@¬ΒΈ­  AE_DecreasPLT_trm
ηαQ    AE_Skin_trm
H~sU    AE_Anorexia_trm
³ AE_HighBDPRES_trm
`A AE_Prote_trm
-----------------------------------------------------
*/
%macro AE_EXEC(target_column, output_ds);
    %local ds_output_ae varname_t i temp_varname temp_label max_index colname;
    %let varname_t="AE_MortoNeuropathy,AE_SensNeuropathy,AE_diarrhea,AE_DecreasNeut,AE_Skin,AE_Anorexia,AE_HighBDPRES,AE_Prote";
    %let label_t="½_oαQ,Ί,DΈ­,¬ΒΈ­,ηαQ,H~sU,³,`A";
    %let max_index = %sysfunc(countc(&varname_t., ','));
    %let max_index = %eval(&max_index. + 1);
    %do i = 1 %to &max_index.; 
        %let temp_varname=%scan(&varname_t., &i., ",");
        %let temp_label=%scan(&label_t., &i., ",");
        %SET_FREQ(temp_ae, '‘ΓΙζιLQΫ', &temp_varname._grd, %str(ope_chemo_cnt), response_ope_no_chemo.csv);
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
