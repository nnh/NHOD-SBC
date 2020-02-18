/******************************************************
Program Name : output_excel.sas
Study Name : NHOD-SBC
Author : Ohtsuka Mariko
Date : 2020-01-27
SAS version : 9.4
*******************************************************/
%macro CAT_COUNT_AND_PERCENT(input_ds, input_count_var_name, output_var_name, output_ds);
    * ��ԍ����擾;
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
*��͑ΏۏW�c�̓���;
%OUTPUT_INTO_SHEET(ds_n, %quote(count), t000, start_row=4, start_col=2, last_col=2);
*�Ǘ�̓���ƒ��~��W�v;
data ds_t001_1;
    set cancel;
    keep ope_non_chemo_cnt ope_chemo_cnt non_ope_chemo_cnt non_ope_non_chemo_cnt;
run;
%OUTPUT_INTO_SHEET(ds_t001_1, %quote(ope_non_chemo_cnt t ope_chemo_cnt t non_ope_chemo_cnt t non_ope_non_chemo_cnt), 
                     t001, start_row=5, start_col=2, last_col=5);



*���~���R;
/*
---------------
*/



*�w�i�Ɛl�����v�w�I����;
%OUTPUT_INTO_SHEET(ds_demog_n, %quote(all_cnt t ope_non_chemo_cnt t ope_chemo_cnt t non_ope_chemo_cnt t non_ope_non_chemo_cnt), 
                     t002, start_row=5, start_col=4, last_col=8);
%CAT_COUNT_AND_PERCENT(ds_demog, all_cnt, all, ds_t002);
%CAT_COUNT_AND_PERCENT(ds_t002, ope_non_chemo_cnt, ope_non_chemo, ds_t002);
%CAT_COUNT_AND_PERCENT(ds_t002, ope_chemo_cnt, ope_chemo, ds_t002);
%CAT_COUNT_AND_PERCENT(ds_t002, non_ope_non_chemo_cnt, non_ope_non_chemo, ds_t002);
%CAT_COUNT_AND_PERCENT(ds_t002, non_ope_chemo_cnt, non_ope_chemo, ds_t002);
%OUTPUT_INTO_SHEET(ds_t002, %quote(all t ope_non_chemo t ope_chemo t non_ope_chemo t non_ope_non_chemo), 
                     t002, start_row=7, start_col=4, last_col=8);
*�����̌������Ɋւ���L�q;
%OUTPUT_INTO_SHEET(ds_multiple_primary_cancers, %quote(subjid t MHCOM), l001, start_row=4, start_col=1, last_col=8);
*��p�̍����x (����c);
%OUTPUT_INTO_SHEET(ds_surgical_curability, %quote(ope_non_chemo_cnt t ope_chemo_cnt), t003, start_row=5, start_col=2,
                     last_col=3);
*�A�W���o���g���w�Ö@���W����;
%OUTPUT_INTO_SHEET(ds_adjuvant_chemo_regimen, %quote(ope_chemo_cnt), t004, start_row=5, start_col=2, last_col=2);
*���I�����w�Ö@���W����;
%OUTPUT_INTO_SHEET(ds_first_line_chemo_regimen, %quote(non_ope_chemo_cnt), t005, start_row=5, start_col=2, last_col=2);
*�������؏��̗L��;
%OUTPUT_INTO_SHEET(ds_primary_site_resection, 
                     %quote(ope_non_chemo_cnt t ope_chemo_cnt t non_ope_non_chemo_cnt t non_ope_chemo_cnt), t006, 
                     start_row=5, start_col=2, last_col=5);
*�S�������� (�����؏��Ǝ������؏�);
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
%OUTPUT_INTO_SHEET(homtests_lifetest_f001, %quote(ProbChiSq), f001, start_row=2, start_col=7, last_col=7);
%OUTPUT_INTO_SHEET_OS(output_lifetest_f001_1, %quote(group t os_day t SURVIVAL), %quote(group), f001, 10, 8, 10, %quote(os_day));
%OUTPUT_INTO_SHEET_OS(output_lifetest_f001_2, %quote(group t os_day t SURVIVAL), %quote(group), f001, 10, 11, 13, %quote(os_day));
%OUTPUT_INTO_SHEET(homtests_lifetest_f002, %quote(ProbChiSq), f002, start_row=2, start_col=7, last_col=7);
%OUTPUT_INTO_SHEET_OS(output_lifetest_f002_1, %quote(group t os_day t SURVIVAL), %quote(group), f002, 10, 8, 10, %quote(os_day));
%OUTPUT_INTO_SHEET_OS(output_lifetest_f002_2, %quote(group t os_day t SURVIVAL), %quote(group), f002, 10, 11, 13, %quote(os_day));
%OUTPUT_INTO_SHEET(homtests_lifetest_f003, %quote(ProbChiSq), f003, start_row=2, start_col=7, last_col=7);
%OUTPUT_INTO_SHEET_OS(output_lifetest_f003_1, %quote(group t os_day t SURVIVAL), %quote(group), f003, 10, 8, 10, %quote(os_day));
%OUTPUT_INTO_SHEET_OS(output_lifetest_f003_2, %quote(group t os_day t SURVIVAL), %quote(group), f003, 10, 11, 13, %quote(os_day));
%OUTPUT_INTO_SHEET(lifetest_f001_n_1, %quote(count), t007, start_row=5, start_col=2, last_col=2);
%OUTPUT_INTO_SHEET(lifetest_f001_n_2, %quote(count), t007, start_row=5, start_col=3, last_col=3);
%OUTPUT_INTO_SHEET(Lifetest_f001_annual_1, %quote(output), t007, start_row=6, start_col=2, last_col=2);
%OUTPUT_INTO_SHEET(Lifetest_f001_annual_2, %quote(output), t007, start_row=6, start_col=3, last_col=3);
%OUTPUT_INTO_SHEET(lifetest_f002_n_1, %quote(count), t008, start_row=5, start_col=2, last_col=2);
%OUTPUT_INTO_SHEET(lifetest_f002_n_2, %quote(count), t008, start_row=5, start_col=3, last_col=3);
%OUTPUT_INTO_SHEET(Lifetest_f002_annual_1, %quote(output), t008, start_row=6, start_col=2, last_col=2);
%OUTPUT_INTO_SHEET(Lifetest_f002_annual_2, %quote(output), t008, start_row=6, start_col=3, last_col=3);
%OUTPUT_INTO_SHEET(Lifetest_f003_annual_1, %quote(output), t009, start_row=6, start_col=2, last_col=2);
%OUTPUT_INTO_SHEET(Lifetest_f003_annual_2, %quote(output), t009, start_row=6, start_col=3, last_col=3);
%OUTPUT_INTO_SHEET(lifetest_f003_n_1, %quote(count), t009, start_row=5, start_col=2, last_col=2);
%OUTPUT_INTO_SHEET(lifetest_f003_n_2, %quote(count), t009, start_row=5, start_col=3, last_col=3);
%OUTPUT_INTO_SHEET(t010_n, %quote(ope_non_chemo_cnt t ope_chemo_cnt t non_ope_non_chemo_cnt t non_ope_chemo_cnt), t010, start_row=5, start_col=2, last_col=5);
%OUTPUT_INTO_SHEET(t010, %quote(ope_non_chemo_cnt t ope_chemo_cnt t non_ope_non_chemo_cnt t non_ope_chemo_cnt), t010, start_row=6, start_col=2, last_col=5);

*���Â̑t������;
%OUTPUT_INTO_SHEET(response_ope_non_chemo, %quote(ope_non_chemo_cnt), t015, start_row=5, start_col=2, last_col=2);
%OUTPUT_INTO_SHEET(response_ope_chemo, %quote(count t count2 t count3 t count4 t count5), t016, 
                     start_row=5, start_col=2, last_col=7);
%OUTPUT_INTO_SHEET(response_non_ope_chemo, %quote(count t count2 t count3 t count4 t count5 t count6 t count7 t count8 t count9 t count10 t count11), t017, 
                     start_row=5, start_col=2, last_col=12);
*��ᇂ̏k����;
%OUTPUT_INTO_SHEET(ds_t018, %quote(non_ope_chemo_cnt t Lesion3m t Lesion6m), t018, start_row=5, start_col=2, last_col=4);
*���Âɂ��L�Q����;
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
