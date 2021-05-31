/******************************************************
Program Name : output_excel.sas
Study Name : NHOD-SBC
Author : Ohtsuka Mariko
Date : 2020-03-06
SAS version : 9.4
*******************************************************/
%macro CAT_COUNT_AND_PERCENT(input_ds, input_count_var_name, output_var_name, output_ds);
    /*  *** Functional argument *** 
        input_ds : Input dataset 
        input_count_var_name : Target variable
        output_var_name Output variable name
        output_ds : Output dataset
        *** Example ***
        %CAT_COUNT_AND_PERCENT(ds_demog, all_cnt, all, ds_t002);
    */
    %local dsid count_var_num per_var_num per_var_name rc;
    %let dsid=%sysfunc(open(&input_ds., i));
    %let count_var_num=%sysfunc(varnum(&dsid, &input_count_var_name.));
    %let per_var_num=%eval(&count_var_num. + 1);
    %let per_var_name=%sysfunc(varname(&dsid., &per_var_num.));
    %let rc=%sysfunc(close(&dsid));
    proc sql noprint;
        create table temp_ds_per as
        select *,
            case when &per_var_name. is not missing then
                cat(&input_count_var_name., ' (', compress(&per_var_name., , 's'), '%)')
            else
                case when &input_count_var_name. is not missing then
                    compress(put(&input_count_var_name., best12.), , 's')
                else
                    ''
                end
            end as &output_var_name.
        from &input_ds.;
    quit;
    data &output_ds.;
        set temp_ds_per;
        drop &input_count_var_name. &per_var_name.;
    run;
%mend;
%macro OUTPUT_INTO_SHEET(input_ds, str_put, output_sheet, start_row, start_col, last_col);
    /*  *** Functional argument *** 
        input_ds : Input dataset 
        str_put : Output variables
        output_sheet : Output sheet name
        start_row : Output start row
        start_col : Output start column
        last_col : Output end column
        *** Example ***
        %OUTPUT_INTO_SHEET(ds_n, %quote(count), t000, start_row=4, start_col=2, last_col=2);
    */
    %local row_count last_row target_range max_index temp_var temp_col i;
    proc sql noprint;
        select count(*) into:row_count from &input_ds.;
    quit;
    %let last_row=%eval(&row_count. + &start_row. -1);
    %let max_index = %sysfunc(countc(&str_put., ','));
    %let max_index = %eval(&max_index. + 1);
    %do i = 1 %to &max_index.;
        %let temp_col=%eval(&start_col + &i. - 1);
        %let target_range=%sysfunc(catt(excel|, &output_sheet. , !, R, &start_row., C, &temp_col ,:R, &last_row., C, &temp_col.));
        %let temp_var=%scan(&str_put., &i., ",");
        filename &output_sheet. dde "&target_range." notab;
        data _NULL_;
            set &input_ds.;
            file &output_sheet.;
            put &temp_var.;
        run;
    %end;
%mend OUTPUT_INTO_SHEET;
%macro OUTPUT_INTO_SHEET_OS(input_ds, target_str1, target_str2, target_sheet, start_row, start_col, last_col, key_var);
    /*  *** Functional argument *** 
        input_ds : Input dataset 
        target_str1 : Output variables
        target_sheet : Output sheet name
        start_row : Output start row
        start_col : Output start column
        last_col : Output end column
        key_var : Key variable
        *** Example ***
        %OUTPUT_INTO_SHEET_OS(output_lifetest_&sheet_name._2, %quote(group, os_day, SURVIVAL), %quote(group), &sheet_name., 
                                &os_graph_data_source_start_row., &os_graph_data_source_start_col_2., 
                                &os_graph_data_source_end_col_2., %quote(os_day));
    */
    %local row_count output_flg i;
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
    /*  *** Functional argument *** 
        sheet_name : Output sheet name
        annual_sheet_name : Output sheet name
        output_control_group : 1 : Multiple groups, 0 : Single group
        *** Example ***
        %OUTPUT_OS(f001, t007);
    */
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
    %OUTPUT_INTO_SHEET_OS(output_lifetest_&sheet_name._1, %quote(group, os_day, SURVIVAL), %quote(group), &sheet_name., 
                            &os_graph_data_source_start_row., &os_graph_data_source_start_col_1., 
                            &os_graph_data_source_end_col_1., %quote(os_day));
    %OUTPUT_INTO_SHEET(lifetest_&sheet_name._n_1, %quote(count), &annual_sheet_name., start_row=&os_n_row., 
                         start_col=&os_n_col1., last_col=&os_n_col1.);
    %OUTPUT_INTO_SHEET(lifetest_&sheet_name._annual_1, %quote(output), &annual_sheet_name., start_row=&os_annual_row., 
                         start_col=&os_n_col1., last_col=&os_n_col1.);
    %if &output_control_group.=1 %then %do;
        %OUTPUT_INTO_SHEET(homtests_lifetest_&sheet_name., %quote(ProbChiSq), &sheet_name., start_row=&os_p_value_row., 
                             start_col=&os_p_value_col., last_col=&os_p_value_col.);
        %OUTPUT_INTO_SHEET_OS(output_lifetest_&sheet_name._2, %quote(group, os_day, SURVIVAL), %quote(group), &sheet_name., 
                                &os_graph_data_source_start_row., &os_graph_data_source_start_col_2., 
                                &os_graph_data_source_end_col_2., %quote(os_day));
        %OUTPUT_INTO_SHEET(lifetest_&sheet_name._n_2, %quote(count), &annual_sheet_name., start_row=&os_n_row., 
                             start_col=&os_n_col2., last_col=&os_n_col2.);
        %OUTPUT_INTO_SHEET(lifetest_&sheet_name._annual_2, %quote(output), &annual_sheet_name., start_row=&os_annual_row., 
                             start_col=&os_n_col2., last_col=&os_n_col2.);
    %end;
%mend OUTPUT_OS;
%macro OUTPUT_INTO_SHEET_RESPONSE(input_ds_head, input_col, sheet_name, start_row, start_col, max_index);
    %local i target_col;
    %do i = 1 %to &max_index.;
        %let target_col=%eval(&start_col. - 1 + &i.); 
        %OUTPUT_INTO_SHEET(&input_ds_head.&i._n, %quote(&input_col.), &sheet_name., start_row=&start_row., start_col=&target_col., last_col=&target_col.);
        %CAT_COUNT_AND_PERCENT(&input_ds_head.&i., &input_col., output_col, ds_response);
        %OUTPUT_INTO_SHEET(ds_response, output_col, &sheet_name., start_row=%eval(&start_row.+1), start_col=&target_col., last_col=&target_col.);
    %end;
%mend OUTPUT_INTO_SHEET_RESPONSE;

options noxwait noxsync;
%sysexec "&templatepath.\&template_input.";
data _NULL_;
  rc = sleep(5);
run;
%OUTPUT_INTO_SHEET(ds_n, %quote(count), t000, start_row=4, start_col=2, last_col=2);
%OUTPUT_INTO_SHEET(cancel, %quote(ope_non_chemo_cnt, ope_chemo_cnt, non_ope_non_chemo_cnt, non_ope_chemo_cnt), 
                     t001, start_row=5, start_col=2, last_col=5);



*íÜé~óùóR;
/*
---------------
*/



%OUTPUT_INTO_SHEET(ds_demog_n, %quote(all_cnt, ope_non_chemo_cnt, ope_chemo_cnt, non_ope_non_chemo_cnt, non_ope_chemo_cnt), 
                     t002, start_row=5, start_col=4, last_col=8);
%CAT_COUNT_AND_PERCENT(ds_demog, all_cnt, all, ds_t002);
%CAT_COUNT_AND_PERCENT(ds_t002, ope_non_chemo_cnt, ope_non_chemo, ds_t002);
%CAT_COUNT_AND_PERCENT(ds_t002, ope_chemo_cnt, ope_chemo, ds_t002);
%CAT_COUNT_AND_PERCENT(ds_t002, non_ope_non_chemo_cnt, non_ope_non_chemo, ds_t002);
%CAT_COUNT_AND_PERCENT(ds_t002, non_ope_chemo_cnt, non_ope_chemo, ds_t002);
%OUTPUT_INTO_SHEET(ds_t002, %quote(all, ope_non_chemo, ope_chemo, non_ope_non_chemo, non_ope_chemo), 
                     t002, start_row=7, start_col=4, last_col=8);
%OUTPUT_INTO_SHEET(ds_multiple_primary_cancers, %quote(subjid, MHCOM), l001, start_row=5, start_col=1, last_col=2);
%OUTPUT_INTO_SHEET(ds_surgical_curability_n, %quote(ope_non_chemo_cnt, ope_chemo_cnt), t003, start_row=5, 
                     start_col=2, last_col=3);
%CAT_COUNT_AND_PERCENT(ds_surgical_curability, ope_non_chemo_cnt, ope_non_chemo, ds_t003);
%CAT_COUNT_AND_PERCENT(ds_t003, ope_chemo_cnt, ope_chemo, ds_t003);
%OUTPUT_INTO_SHEET(ds_t003, %quote(ope_non_chemo, ope_chemo), t003, start_row=6, start_col=2, last_col=3);
%OUTPUT_INTO_SHEET(ds_adjuvant_chemo_regimen_n, %quote(ope_chemo_cnt), t004, start_row=5, start_col=2, last_col=2);
%CAT_COUNT_AND_PERCENT(ds_adjuvant_chemo_regimen, ope_chemo_cnt, ope_chemo, ds_t004);
%OUTPUT_INTO_SHEET(ds_t004, %quote(ope_chemo), t004, start_row=6, start_col=2, last_col=2);
%OUTPUT_INTO_SHEET(ds_first_line_chemo_regimen_n, %quote(non_ope_chemo_cnt), t005, start_row=5, start_col=2, last_col=2);
%CAT_COUNT_AND_PERCENT(ds_first_line_chemo_regimen, non_ope_chemo_cnt, non_ope_chemo, ds_t005);
%OUTPUT_INTO_SHEET(ds_t005, %quote(non_ope_chemo), t005, start_row=6, start_col=2, last_col=2);
%OUTPUT_INTO_SHEET(ds_primary_site_resection_n, %quote(ope_non_chemo_cnt, ope_chemo_cnt, non_ope_non_chemo_cnt, non_ope_chemo_cnt), 
                     t006, start_row=5, start_col=2, last_col=5);
%CAT_COUNT_AND_PERCENT(ds_primary_site_resection, ope_non_chemo_cnt, ope_non_chemo, ds_t006);
%CAT_COUNT_AND_PERCENT(ds_t006, ope_chemo_cnt, ope_chemo, ds_t006);
%CAT_COUNT_AND_PERCENT(ds_t006, non_ope_non_chemo_cnt, non_ope_non_chemo, ds_t006);
%CAT_COUNT_AND_PERCENT(ds_t006, non_ope_chemo_cnt, non_ope_chemo, ds_t006);
%OUTPUT_INTO_SHEET(ds_t006, %quote(ope_non_chemo, ope_chemo, non_ope_non_chemo, non_ope_chemo), t006, 
                     start_row=6, start_col=2, last_col=5);
%OUTPUT_OS(f001, t007);
%OUTPUT_OS(f002, t008);
%OUTPUT_OS(f003, t009);
%OUTPUT_INTO_SHEET(t010_n, %quote(ope_non_chemo_cnt, ope_chemo_cnt, non_ope_non_chemo_cnt, non_ope_chemo_cnt), t010, 
                     start_row=5, start_col=2, last_col=5);
%OUTPUT_INTO_SHEET(t010, %quote(ope_non_chemo_cnt, ope_chemo_cnt, non_ope_non_chemo_cnt, non_ope_chemo_cnt), t010, 
                     start_row=6, start_col=2, last_col=5);
%OUTPUT_OS(f004, t011);
%OUTPUT_OS(f005, t012);
%OUTPUT_OS(f006, t013, output_control_group=0);
%OUTPUT_INTO_SHEET(t014_n, %quote(ope_non_chemo_cnt, ope_chemo_cnt, non_ope_chemo_cnt), t014, start_row=5, 
                     start_col=2, last_col=5);
%OUTPUT_INTO_SHEET(t014, %quote(ope_non_chemo_cnt, ope_chemo_cnt, non_ope_chemo_cnt), t014, start_row=6, 
                     start_col=2, last_col=5);
%OUTPUT_INTO_SHEET(response_ope_non_chemo_n, %quote(ope_non_chemo_cnt), t015, start_row=5, start_col=2, last_col=2);
%CAT_COUNT_AND_PERCENT(response_ope_non_chemo, ope_non_chemo_cnt, ope_non_chemo, ds_t015);
%OUTPUT_INTO_SHEET(ds_t015, %quote(ope_non_chemo), t015, start_row=6, start_col=2, last_col=2);
%OUTPUT_INTO_SHEET(response_ope_non_chemo_n, %quote(ope_non_chemo_cnt), t015, start_row=5, start_col=2, last_col=2);
%OUTPUT_INTO_SHEET_RESPONSE(output_res_ope_chemo, ope_chemo_cnt, t016, 5, 2, 5);
%OUTPUT_INTO_SHEET_RESPONSE(output_res_non_ope_chemo, non_ope_chemo_cnt, t017, 5, 2, 10);
%OUTPUT_INTO_SHEET(ds_t018, %quote(non_ope_chemo_cnt, Lesion3m, Lesion6m), t018, start_row=5, start_col=2, last_col=4);
%OUTPUT_INTO_SHEET(ds_t019, %quote(ope_1, ope_2, ope_3, ope_4, non_ope_1, non_ope_2, non_ope_3, non_ope_4), t019, 
                     start_row=6, start_col=2, last_col=9);
* Insert a blank line;
proc sql noprint;
    create table ds_dummy(v1 char(1), v2 char(1), v3 char(1), v4 char(1), v5 char(1), v6 char(1), v7 char(1), v8 char(1));
    insert into ds_dummy values("", "", "", "", "", "", "", ""); 
quit;
%OUTPUT_INTO_SHEET(ds_dummy, %quote(v1, v2, v3, v4, v5, v6, v7, v8), t019, start_row=9, start_col=2, last_col=9);

* Delete the output file if it exists;
%let output_file_name=&outpath.\&template_output.;
data _null_;
    fname="tempfile";
    rc=filename(fname, "&output_file_name.");
    if rc = 0 and fexist(fname) then do;
       rc=fdelete(fname);
    end;
    rc=filename(fname);
run;
filename sas2xl dde 'excel|system';
data _null_;
    file sas2xl;
    put '[error(false)]';
    put "[save.as(""&output_file_name."")]";
    put '[quit()]';
run;


