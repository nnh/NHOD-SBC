**************************************************************************
Program Name : demog.sas
Study Name : NHOD-SBC
Author : Ohtsuka Mariko
Date : 2020-01-20
SAS version : 9.4
**************************************************************************;
%macro FREQ_METAYN;
    %local i row_count item2 item3 item4;
    %let item2='あり';
    %let item3='なし';
    %let item4='不明';
    proc sql noprint;
        %do i = 1 %to 5;     
            create table ds_meta_&i. like ds_demog;
        %end;
    quit;

    %FREQ_FUNC(var_var=metaYN, output_ds=ds_meta_1);
    /* Split dataset by presence or absence of metastases */
    %do i = 2 %to 4;
        proc sql noprint;
            insert into ds_meta_&i. select * from ds_meta_1 where items =  &&item&i.;
        quit;
        proc sql noprint;
            select count(*) into :row_count from ds_meta_&i.;
        quit;
        %if &row_count. = 0 %then %do;
            proc sql noprint;
                insert into ds_meta_&i. values('', &&item&i., ., ., ., ., ., ., ., ., ., .);
            quit;
        %end;
    %end;
    proc sql noprint;
        update ds_meta_2 set title = '転移臓器';
        insert into ds_meta_5 select * from ds_meta_1 where (items ne &item2.) and (items ne &item3.) and (items ne &item4.);
    quit;
%mend FREQ_METAYN;

%macro FREQ_METASITE;
    %local i temp_meta_1 temp_meta_2 temp_meta_3 temp_meta_4 temp_meta_5 row count;
    %let temp_meta_1='　肝臓';
    %let temp_meta_2='　肺';
    %let temp_meta_3='　腹膜播種';
    %let temp_meta_4='　腹腔内リンパ節';
    %let temp_meta_5='　その他';
    %do i = 1 %to 5;
        proc sql;
            create table temp_metasite_&i. like ds_demog;
        quit;
        %FREQ_FUNC(input_ds=ptdata, var_var=metasite_&i., output_ds=temp_metasite_&i.);
        proc sql noprint;
            create table output_meta_&i. like ds_demog;
            insert into output_meta_&i. select * from temp_metasite_&i. where items like '%TRUE%';
            update output_meta_&i. set title = &&temp_meta_&i., items = '';
        quit;
        proc sql noprint;
            select count(*) into :row_count from output_meta_&i.;
        quit;
        %if &row_count. = 0 %then %do;
            proc sql noprint;
                insert into output_meta_&i. values(&&temp_meta_&i., '', ., ., ., ., ., ., ., ., ., .);
            quit;
        %end;
    %end;
    data ds_demog;
        set ds_demog output_meta_1-output_meta_5;
    run;
%mend FREQ_METASITE;

%macro FREQ_META;
    %FREQ_METAYN;
    /* meta = yes */
    data ds_demog;
        set ds_demog ds_meta_2;
    run;
    /* Output details of the meta */
    %FREQ_METASITE;
    data ds_demog;
        set ds_demog ds_meta_3 ds_meta_4;
    run;
%mend FREQ_META;

* 5.3. Background and demographic characteristics;
options noquotelenmax; 
%CREATE_OUTPUT_DS(output_ds=ds_demog, items_label='背景と人口統計学的特性');
%MEANS_FUNC(title='年齢', var_var=AGE);
%FORMAT_FREQ(sex, %quote('男性', '女性'), '性別');
%FORMAT_FREQ(CrohnYN, %quote('あり', 'なし', '不明'), 'クローン病');
%FORMAT_FREQ(HNPCCYN, %quote('あり', 'なし', '不明'), 'HNPCC');
%FORMAT_FREQ(TNMCAT, %quote('I', 'II', 'III', 'IV'), 'TNM分類');
%FORMAT_FREQ(PS, %quote('0', '1', '2', '3', '4'), 'PS');
%FORMAT_FREQ(SBCSITE, %quote('十二指腸', '空腸', '回腸'), '部位');
%FORMAT_FREQ(SBCdegree, %quote('高分化', '中分化', '低分化', '未分化', '不明'), '病理組織の分化度');
%FORMAT_FREQ(RASYN, %quote('あり', 'なし', '不明'), 'RAS変異の有無');
%FREQ_META;
%TO_NUM_TEST_RESULTS(var=LDH);
%MEANS_FUNC(title='LDH', var_var=LDH_num);
%TO_NUM_TEST_RESULTS(var=CEA);
%MEANS_FUNC(title='CEA', var_var=CEA_num);
%TO_NUM_TEST_RESULTS(var=CA199);
%MEANS_FUNC(title='CA199', var_var=CA199_num);
%ds2csv (data=ds_demog, runmode=b, csvfile=&outpath.\_5_3_demog.csv, labels=Y);
* Multiple primary cancers;
data ds_multiple_primary_cancers;
    format subjid best12.;
    set ptdata(rename=(subjid=id));
    where MHCOM ne '';
    subjid = id;
    keep subjid MHCOM;
run;
%ds2csv (data=ds_multiple_primary_cancers, runmode=b, csvfile=&outpath.\_5_3_multiple_primary_cancers.csv, labels=Y);

* Delete the working dataset;
proc datasets lib=work nolist; 
    delete ds_colnames ds_join ds_meta_1-ds_meta_5 ds_title output_meta_1-output_meta_5 template_ds temp_ds_demog 
           temp_freq temp_metasite_1-temp_metasite_5; 
    run;
quit;
