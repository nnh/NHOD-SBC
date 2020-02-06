/******************************************************
Program Name : output_excel.sas
Study Name : NHOD-SBC
Author : Ohtsuka Mariko
Date : 2020-01-27
SAS version : 9.4
*******************************************************/
%macro CAT_COUNT_AND_PERCENT(input_ds, input_count_var_name, output_var_name, output_ds);
    * 列番号を取得;
    %let dsid=%sysfunc(open(&input_ds., i));
    %let count_var_num=%sysfunc(varnum(&dsid, &input_count_var_name.));
    %let per_var_num=%eval(&count_var_num. + 1);
    %let per_var_name=%sysfunc(varname(&dsid., &per_var_num.));
    %let rc=%sysfunc(close(&dsid));
    data &output_ds.;
        set &input_ds.;
        if &per_var_name.^=. then do;
            &output_var_name.=catt(&input_count_var_name., ' (', &per_var_name., '%)');
        end;
        else do;
            if &input_count_var_name.^=. then do;
                &output_var_name.=&input_count_var_name.;
            end;
            else do;
                &output_var_name.=cat(.);
            end;
        end;
        drop &input_count_var_name. &per_var_name.;
    run;
%mend;
%macro OUTPUT_INTO_SHEET(input_ds, str_put, output_sheet, start_row, start_col, last_col);
    proc sql noprint;
        select count(*) into:row_count from &input_ds.;
    quit;
    %let last_row=%eval(&row_count. + &start_row. -1);
    %let target_range=%sysfunc(catt(excel|, &output_sheet. , !, R, &start_row., C, &start_col ,:R, &last_row., C, &last_col.));
    filename &output_sheet. dde "&target_range." notab;
    data _NULL_;
        set &input_ds.;
        t='09'x;
        file &output_sheet.;
        put &str_put.;
    run;

%mend OUTPUT_INTO_SHEET;

options noxwait noxsync;
%let templatepath=C:\Users\Mariko;
%let template_input=test.xlsx;
%sysexec "&templatepath.\&template_input.";
data _NULL_;
  rc = sleep(5);
run;
*解析対象集団の内訳;
%OUTPUT_INTO_SHEET(ds_n, %quote(count), t000, start_row=4, start_col=2, last_col=2);
*症例の内訳と中止例集計;
data ds_t001_1;
    set cancel;
    keep ope_non_chemo_cnt ope_chemo_cnt non_ope_chemo_cnt non_ope_non_chemo_cnt;
run;
%OUTPUT_INTO_SHEET(ds_t001_1, %quote(ope_non_chemo_cnt t ope_chemo_cnt t non_ope_chemo_cnt t non_ope_non_chemo_cnt), 
                     t001, start_row=5, start_col=2, last_col=5);



*中止理由;
/*
---------------
*/



*背景と人口統計学的特性;
%CAT_COUNT_AND_PERCENT(ds_demog, all_cnt, all, ds_t002);
%CAT_COUNT_AND_PERCENT(ds_t002, ope_non_chemo_cnt, ope_non_chemo, ds_t002);
%CAT_COUNT_AND_PERCENT(ds_t002, ope_chemo_cnt, ope_chemo, ds_t002);
%CAT_COUNT_AND_PERCENT(ds_t002, non_ope_non_chemo_cnt, non_ope_non_chemo, ds_t002);
%CAT_COUNT_AND_PERCENT(ds_t002, non_ope_chemo_cnt, non_ope_chemo, ds_t002);
%OUTPUT_INTO_SHEET(ds_t002, %quote(all t ope_non_chemo t ope_chemo t non_ope_chemo t non_ope_non_chemo), 
                     t002, start_row=7, start_col=4, last_col=8);
*複数の原発癌に関する記述;
%OUTPUT_INTO_SHEET(ds_multiple_primary_cancers, %quote(subjid t MHCOM), l001, start_row=5, start_col=1, last_col=8);
*手術の根治度 (癌遺残);
data ds_t003;
    set ds_surgical_curability;
    keep ope_non_chemo_cnt ope_chemo_cnt;
run;
%OUTPUT_INTO_SHEET(ds_t003, %quote(ope_non_chemo_cnt t ope_chemo_cnt), t003, start_row=6, start_col=2, last_col=3);
*アジュバント化学療法レジメン;
data ds_t004;
    set ds_adjuvant_chemo_regimen;
    keep ope_chemo_cnt;
run;
%OUTPUT_INTO_SHEET(ds_t004, %quote(ope_chemo_cnt), t004, start_row=6, start_col=2, last_col=2);
*第一選択化学療法レジメン;
data ds_t005;
    set ds_first_line_chemo_regimen;
    keep non_ope_chemo_cnt;
run;
%OUTPUT_INTO_SHEET(ds_t005, %quote(non_ope_chemo_cnt), t005, start_row=6, start_col=2, last_col=2);
*原発巣切除の有無;
/*
data _null_;
    file sas2xl;
    put '[error(false)]';
    put '[close("false")]';
    put '[quit()]';
run;

*/
