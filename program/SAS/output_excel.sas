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
%macro OUTPUT_INTO_SHEET_OS(input_ds, target_str1, target_str2, target_sheet, start_row, start_col, last_col, key_var);
    %local row_count output_flg;
    proc sql noprint;
        select count(*) into:row_count trimmed from &input_ds.;
    quit;
    %do i = 1 %to %eval(&row_count.);
        data temp;
            set &input_ds.;
            if _N_=&i. then do;
                call symput('output_flg', input(&key_var., best12.));
                output;
            end;
        run;
        %if &output_flg.^=. %then %do;
            %OUTPUT_INTO_SHEET(temp, &target_str1., &target_sheet., start_row=%eval(&start_row.+&i.), start_col=&start_col., last_col=&last_col.);
        %end;
        %else %do;
            %OUTPUT_INTO_SHEET(temp, &target_str2., &target_sheet., start_row=%eval(&start_row.+&i.), start_col=&start_col., last_col=&start_col.);
        %end;

    %end;
%mend OUTPUT_INTO_SHEET_OS;
%macro OUTPUT_OS(sheet_name, annual_sheet_name, output_control_group=1);
    %local os_p_value_row os_p_value_col os_graph_data_source_start_row os_graph_data_source_start_col_1
           os_graph_data_source_start_col_2 os_graph_data_source_end_col_2 os_n_row os_n_col1 os_n_col2;
    %let os_p_value_row=7;
    %let os_p_value_col=2;
    %let os_graph_data_source_start_row=10;
    %let os_graph_data_source_start_col_1=8;
    %let os_graph_data_source_end_col_1=10;
    %let os_graph_data_source_start_col_2=11;
    %let os_graph_data_source_end_col_2=13;
    %let os_n_row=5;
    %let os_annual_row=6;
    %let os_n_col1=2;
    %let os_n_col2=3;
    %OUTPUT_INTO_SHEET_OS(output_lifetest_&sheet_name._1, %quote(group t os_day t SURVIVAL), %quote(group), &sheet_name., 
                            &os_graph_data_source_start_row., &os_graph_data_source_start_col_1., 
                            &os_graph_data_source_end_col_1., %quote(os_day));
    %OUTPUT_INTO_SHEET(lifetest_&sheet_name._n_1, %quote(count), &annual_sheet_name., start_row=&os_n_row., 
                         start_col=&os_n_col1., last_col=&os_n_col1.);
    %OUTPUT_INTO_SHEET(lifetest_&sheet_name._annual_1, %quote(output), &annual_sheet_name., start_row=&os_annual_row., 
                         start_col=&os_n_col1., last_col=&os_n_col1.);
    %if &output_control_group.=1 %then %do;
        %OUTPUT_INTO_SHEET(homtests_lifetest_&sheet_name., %quote(ProbChiSq), &sheet_name., start_row=&os_p_value_row., 
                             start_col=&os_p_value_col., last_col=&os_p_value_col.);
        %OUTPUT_INTO_SHEET_OS(output_lifetest_&sheet_name._2, %quote(group t os_day t SURVIVAL), %quote(group), &sheet_name., 
                                &os_graph_data_source_start_row., &os_graph_data_source_start_col_2., 
                                &os_graph_data_source_end_col_2., %quote(os_day));
        %OUTPUT_INTO_SHEET(lifetest_&sheet_name._n_2, %quote(count), &annual_sheet_name., start_row=&os_n_row., 
                             start_col=&os_n_col2., last_col=&os_n_col2.);
        %OUTPUT_INTO_SHEET(lifetest_&sheet_name._annual_2, %quote(output), &annual_sheet_name., start_row=&os_annual_row., 
                             start_col=&os_n_col2., last_col=&os_n_col2.);
    %end;

%mend OUTPUT_OS;

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
%OUTPUT_INTO_SHEET(ds_demog_n, %quote(all_cnt t ope_non_chemo_cnt t ope_chemo_cnt t non_ope_chemo_cnt t non_ope_non_chemo_cnt), 
                     t002, start_row=5, start_col=4, last_col=8);
%CAT_COUNT_AND_PERCENT(ds_demog, all_cnt, all, ds_t002);
%CAT_COUNT_AND_PERCENT(ds_t002, ope_non_chemo_cnt, ope_non_chemo, ds_t002);
%CAT_COUNT_AND_PERCENT(ds_t002, ope_chemo_cnt, ope_chemo, ds_t002);
%CAT_COUNT_AND_PERCENT(ds_t002, non_ope_non_chemo_cnt, non_ope_non_chemo, ds_t002);
%CAT_COUNT_AND_PERCENT(ds_t002, non_ope_chemo_cnt, non_ope_chemo, ds_t002);
%OUTPUT_INTO_SHEET(ds_t002, %quote(all t ope_non_chemo t ope_chemo t non_ope_chemo t non_ope_non_chemo), 
                     t002, start_row=7, start_col=4, last_col=8);
*複数の原発癌に関する記述;
%OUTPUT_INTO_SHEET(ds_multiple_primary_cancers, %quote(subjid t MHCOM), l001, start_row=4, start_col=1, last_col=8);
*手術の根治度 (癌遺残);
%OUTPUT_INTO_SHEET(ds_surgical_curability, %quote(ope_non_chemo_cnt t ope_chemo_cnt), t003, start_row=5, start_col=2,
                     last_col=3);
*アジュバント化学療法レジメン;
%OUTPUT_INTO_SHEET(ds_adjuvant_chemo_regimen, %quote(ope_chemo_cnt), t004, start_row=5, start_col=2, last_col=2);
*第一選択化学療法レジメン;
%OUTPUT_INTO_SHEET(ds_first_line_chemo_regimen, %quote(non_ope_chemo_cnt), t005, start_row=5, start_col=2, last_col=2);
*原発巣切除の有無;
%OUTPUT_INTO_SHEET(ds_primary_site_resection, 
                     %quote(ope_non_chemo_cnt t ope_chemo_cnt t non_ope_non_chemo_cnt t non_ope_chemo_cnt), t006, 
                     start_row=5, start_col=2, last_col=5);
*全生存期間;
%OUTPUT_OS(f001, t007);
%OUTPUT_OS(f002, t008);
%OUTPUT_OS(f003, t009);
%OUTPUT_INTO_SHEET(t010_n, %quote(ope_non_chemo_cnt t ope_chemo_cnt t non_ope_non_chemo_cnt t non_ope_chemo_cnt), t010, start_row=5, start_col=2, last_col=5);
%OUTPUT_INTO_SHEET(t010, %quote(ope_non_chemo_cnt t ope_chemo_cnt t non_ope_non_chemo_cnt t non_ope_chemo_cnt), t010, start_row=6, start_col=2, last_col=5);
*無増悪生存期間;
%OUTPUT_OS(f004, t011);
%OUTPUT_OS(f005, t012);
%OUTPUT_OS(f006, t013, output_control_group=0);
%OUTPUT_INTO_SHEET(t014_n, %quote(ope_non_chemo_cnt t ope_chemo_cnt t non_ope_chemo_cnt), t014, start_row=5, start_col=2, last_col=5);
%OUTPUT_INTO_SHEET(t014, %quote(ope_non_chemo_cnt t ope_chemo_cnt t non_ope_chemo_cnt), t014, start_row=6, start_col=2, last_col=5);
*治療の奏功割合;
%OUTPUT_INTO_SHEET(response_ope_non_chemo, %quote(ope_non_chemo_cnt), t015, start_row=5, start_col=2, last_col=2);
%OUTPUT_INTO_SHEET(response_ope_chemo, %quote(count t count2 t count3 t count4 t count5), t016, 
                     start_row=5, start_col=2, last_col=7);
%OUTPUT_INTO_SHEET(response_non_ope_chemo, %quote(count t count2 t count3 t count4 t count5 t count6 t count7 t count8 t count9 t count10 t count11), t017, 
                     start_row=5, start_col=2, last_col=12);
*腫瘍の縮小率;
%OUTPUT_INTO_SHEET(ds_t018, %quote(non_ope_chemo_cnt t Lesion3m t Lesion6m), t018, start_row=5, start_col=2, last_col=4);
*治療による有害事象;
%OUTPUT_INTO_SHEET(ae_ope_chemo, %quote(_1 t _2 t _3 t _4), t019, start_row=6, start_col=2, last_col=5);
%OUTPUT_INTO_SHEET(ae_non_ope_chemo, %quote(_1 t _2 t _3 t _4), t019, start_row=6, start_col=6, last_col=9);

/*
data _null_;
    file sas2xl;
    put '[error(false)]';
    put '[close("false")]';
    put '[quit()]';
run;

*/
