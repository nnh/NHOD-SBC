**************************************************************************
Program Name : ae.sas
Study Name : NHOD-SBC
Author : Ohtsuka Mariko
Date : 2020-02-25
SAS version : 9.4
**************************************************************************;
%macro AE_EXEC_2(var);
    /*  *** Functional argument *** 
        var : Target variable
        *** Example ***
        %AE_EXEC_2(&temp_varname.);
    */
    %local ae_count1 ae_count2 ae_count3 ae_count4 ae_count5 ae_count6 ae_count7 ae_count8 
           i j temp_idx max_grd input_ds_t temp_input_ds;
    %let max_grd=4;
    %let input_ds_t="ds_ae_ope_chemo,ds_ae_non_ope_chemo";
    proc sql noprint;
        %do i = 1 %to 2;
            %let temp_input_ds=%scan(&input_ds_t., &i., ",");
            %do j = 1 %to &max_grd.;
                %let temp_idx=%eval(&j. + (&i. - 1) * &max_grd.);
                select count(*) into:ae_count&temp_idx. from &temp_input_ds. where &var.=&j.;
                %put &&ae_count&temp_idx.;
            %end;
        %end;
        insert into ds_t019 values(&ae_count1., &ae_count2., &ae_count3., &ae_count4., &ae_count5., &ae_count6., &ae_count7., &ae_count8.);
    quit;
%mend AE_EXEC_2;
%macro AE_EXEC_1();
    %local varname_t max_index i temp_varname;
    %let varname_t="AE_MortoNeuropathy_grd,AE_SensNeuropathy_grd,AE_diarrhea_grd,dummy,AE_DecreasNeut_grd,
                    AE_DecreasPLT_grd,AE_Skin_grd,AE_Anorexia_grd,AE_HighBDPRES_grd,AE_Prote_grd";
    %let max_index = %sysfunc(countc(&varname_t., ','));
    %let max_index = %eval(&max_index. + 1);
    proc sql noprint;
        create table ds_t019(ope_1 num, ope_2 num, ope_3 num, ope_4 num, non_ope_1 num, non_ope_2 num, non_ope_3 num, non_ope_4 num);
    quit;
    %do i = 1 %to &max_index.; 
        %let temp_varname=%scan(&varname_t., &i., ",");
        %AE_EXEC_2(&temp_varname.);
    %end;
%mend AE_EXEC_1;
data ds_ae_ope_chemo ds_ae_non_ope_chemo;
    set ptdata_all;
    dummy=.;
    if analysis_set=&ope_chemo. then do;
        output ds_ae_ope_chemo;
    end;
    if analysis_set=&non_ope_chemo. then do;
        output ds_ae_non_ope_chemo;
    end;
run;
%AE_EXEC_1();
