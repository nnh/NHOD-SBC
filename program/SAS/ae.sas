**************************************************************************
Program Name : ae.sas
Study Name : NHOD-SBC
Author : Ohtsuka Mariko
Date : 2019-12-24
SAS version : 9.4
**************************************************************************;
/*
��͑ΏیQ�F
1)�����؏��EChemotherapy�̉�͑ΏۏW�c
2)�������؏��EChemotherapy�̉�͑ΏۏW�c

���Ê��ԑS�̂�ʂ���
�@�@�@�@�@�@�@�@�@�@�@�@�@�@�@�ň��̃O���[�h�i�ᐔ�j
�@�@�@�@�@�@�@�@�@�@�@�@�@�@�@1     2   3   4
-----------------------------------------------------
�����_�o��Q  AE_MortoNeuropathy_trm AE_SensNeuropathy_trm
����  AE_diarrhea_trm 
���t�Ő�
�@�D��������  AE_DecreasNeut_trm
�@��������  AE_DecreasPLT_trm
�畆��Q    AE_Skin_trm
�H�~�s�U    AE_Anorexia_trm
������ AE_HighBDPRES_trm
�`���A AE_Prote_trm
-----------------------------------------------------
*/
%macro AE_EXEC(target_column, output_ds);
    %local ds_output_ae varname_t i temp_varname temp_label max_index colname;
    %let varname_t="AE_MortoNeuropathy,AE_SensNeuropathy,AE_diarrhea,AE_DecreasNeut,AE_Skin,AE_Anorexia,AE_HighBDPRES,AE_Prote";
    %let label_t="�����_�o��Q,����,�D��������,��������,�畆��Q,�H�~�s�U,������,�`���A";
    %let max_index = %sysfunc(countc(&varname_t., ','));
    %let max_index = %eval(&max_index. + 1);
    %do i = 1 %to &max_index.; 
        %let temp_varname=%scan(&varname_t., &i., ",");
        %let temp_label=%scan(&label_t., &i., ",");
        %SET_FREQ(temp_ae, '���Âɂ��L�Q����', &temp_varname._grd, %str(ope_chemo_cnt), response_ope_no_chemo.csv);
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
