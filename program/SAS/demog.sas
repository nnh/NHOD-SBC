**************************************************************************
Program Name : demog.sas
Study Name : NHOD-SBC
Author : Ohtsuka Mariko
Date : 2019-06-05
SAS version : 9.4
**************************************************************************;
*Define constants;
**************************************************************************;
*Define macros;
%macro GET_THISFILE_FULLPATH;
    %local _fullpath _path;
    %let _fullpath=;
    %let _path=;

    %if %length(%sysfunc(getoption(sysin)))=0 %then
      %let _fullpath=%sysget(sas_execfilepath);
    %else
      %let _fullpath=%sysfunc(getoption(sysin));
    &_fullpath.
%mend GET_THISFILE_FULLPATH;

%macro GET_DIRECTORY_PATH(input_path, directory_level);
    %let input_path_len=%length(&input_path.);
    %let temp_path=&input_path.;
    %do i = 1 %to &directory_level.;
        %let temp_len=%scan(&temp_path., -1, '\');
        %let temp_path=%substr(&temp_path., 1, %length(&temp_path.)-%length(&temp_len.)-1);
        %put &temp_path.;
    %end;
    %let _path=&temp_path.;
    &_path.
%mend GET_DIRECTORY_PATH;

%macro EDIT_DS_ALL(ds=temp_all_ds, cat_var=analysis_set, char_len=100, cat_str=&all_group.);
    data &ds.;
        set &ds.;
        format &cat_var. $&char_len..; 
        &cat_var.=&cat_str.;
    run;
%mend EDIT_DS_ALL;

%macro MEANS_FUNC(input_ds=ptdata, title='', cat_var=analysis_set, var_var='', output_ds=ds_demog);
    %local select_str columns;
    %let columns = %str(n=n mean=temp_mean std=temp_std median=median q1=q1 q3=q3 min=min max=max);
    /* Calculation of summary statistics (overall) */
    proc means data=&input_ds. noprint;
        var &var_var.;
        output out=temp_all_ds &columns.;
    run;
    %EDIT_DS_ALL;
    /* Calculation of summary statistics */
    proc means data=&input_ds. noprint;
        class &cat_var.;
        var &var_var.;
        output out=temp_ds  &columns.;
    run;
    /* Round mean and std, remove variable labels */
    data temp_ds;
        set temp_all_ds temp_ds;
        mean=round(temp_mean, 0.1);
        std=round(temp_std, 0.1);
        attrib _ALL_ label=" ";
    run;
    /* Sort observations */
    proc sql;
        create table temp_means like temp_ds;
        insert into temp_means select * from temp_ds where &cat_var.=&all_group.;
        insert into temp_means set &cat_var.='dummy';
        insert into temp_means select * from temp_ds where &cat_var.=&ope_non_chemo. ;
        insert into temp_means set &cat_var.='dummy'; 
        insert into temp_means select * from temp_ds where &cat_var.=&ope_chemo. ;
        insert into temp_means set &cat_var.='dummy';  
        insert into temp_means select * from temp_ds where &cat_var.=&non_ope_non_chemo. ;
        insert into temp_means set &cat_var.='dummy';  
        insert into temp_means select * from temp_ds where &cat_var.=&non_ope_chemo. ; 
        insert into temp_means set &cat_var.='dummy'; 
    quit;
    proc transpose data=temp_means out=tran_means;
        var n mean std median q1 q3 min max;
    run;
    /* Set title only on the first line */
    proc sql;
        insert into &output_ds. select &title., * from tran_means where _NAME_='n';
        insert into &output_ds. select '', * from tran_means where _NAME_ NE 'n';
    quit;
    /* Delete the working dataset */
    proc datasets lib=work nolist; delete temp_all_ds temp_ds temp_means tran_means; run; quit;

%mend MEANS_FUNC;

%macro FREQ_FUNC(input_ds=ptdata, title='', cat_var=analysis_set, var_var='', output_ds=ds_demog);
    proc freq data=&input_ds. noprint;
        tables &var_var./missing out=temp_all_ds;
    run;
    %EDIT_DS_ALL;
    proc freq data=&input_ds. noprint;
        tables &cat_var.*&var_var./missing out=temp_ds;
    run;
    %local temp_var_format format_f temp_len i;
    %let temp_var_format='';
    %let format_f=.;
    %GET_VAR_FORMAT(ptdata_contents, "&var_var.", temp_var_format);
    %let temp_len = %sysfunc(length(&temp_var_format.));
    %if &temp_len. >=3 %then %do;
        %let format_f=1;
    %end;

    data temp_ds;
        set temp_all_ds temp_ds;
        temp_per=round(percent, 0.1);
        %if &format_f.=1 %then %do;
            /* Convert format to string */
            %let dsid=%sysfunc(open(temp_ds, i));
            %if &dsid %then %do;
                %let fmt=%sysfunc(varfmt(&dsid, %sysfunc(varnum(&dsid, &var_var.))));
                %let rc=%sysfunc(close(&dsid));
            %end;
            %put &fmt.;
            items=put(&var_var., &fmt.);
        %end;
        %else %do;
            retain items;
            items=&var_var.;
        %end;
        drop percent &var_var.;
        rename temp_per=percent;
    run;

    /* Split the dataset */
    data temp1 temp2 temp3 temp4 temp5;
        set temp_ds;
        if analysis_set=&all_group. then output temp1;
        else if analysis_set=&ope_non_chemo. then output temp2;
        else if analysis_set=&ope_chemo. then output temp3;
        else if analysis_set=&non_ope_non_chemo. then output temp4;
        else if analysis_set=&non_ope_chemo. then output temp5;
    run;

    %do i = 1 %to %eval(&demog_group_count.);
        %SET_COLNAMES(temp&i.);
        data temp&i.;
            set temp&i.;
            drop analysis_set;
            rename count=&temp_name_cnt. percent=&temp_name_per. items=temp_items;
        run;
        proc sort data=temp&i. out=temp&i.; by temp_items; run; 
    %end;
 
    %GET_FORMAT(ds_colnames, 'items');
    data temp_output;
        format title items &str_format..;
        merge temp1-temp&demog_group_count.;
        by temp_items;
        if _N_=1 then do; title=&title.; end;
        items=temp_items;
        drop temp_items;
    run;

    data &output_ds.;
        set &output_ds. temp_output;
    run;

    /* Delete the working dataset */
    proc datasets lib=work nolist; delete temp1-temp&demog_group_count. temp_ds temp_all_ds temp_output; run; quit;

%mend FREQ_FUNC;

%macro FREQ_METAYN;
    %local i;
    proc sql noprint;
        %do i = 1 %to 4;     
            create table ds_meta_&i. like ds_demog;
        %end;
    quit;

    %FREQ_FUNC(var_var=metaYN, output_ds=ds_meta_1);

    proc sql noprint;
        insert into ds_meta_2 select * from ds_meta_1 where items = 'あり';
        update ds_meta_2 set title = '転移臓器';
        insert into ds_meta_3 select * from ds_meta_1 where items = 'なし';
        insert into ds_meta_4 select * from ds_meta_1 where (items ne 'あり') and (items ne 'なし');
    quit;

%mend FREQ_METAYN;

%macro FREQ_METASITE;
    %local i temp_meta_1 temp_meta_2 temp_meta_3 temp_meta_4 temp_meta_5;
    %let temp_meta_1='　肝臓';
    %let temp_meta_2='　肺';
    %let temp_meta_3='　腹膜播種';
    %let temp_meta_4='　腹腔内リンパ節';
    %let temp_meta_5='　その他';
    %do i = 1 %to %eval(&demog_group_count.);
        proc sql;
            create table temp_metasite_&i. like ds_demog;
        quit;
        %FREQ_FUNC(input_ds=ptdata, var_var=metasite_&i., output_ds=temp_metasite_&i.);
        proc sql noprint;
            create table output_meta_&i. like ds_demog;
            insert into output_meta_&i. select * from temp_metasite_&i. where items like '%TRUE%';
            update output_meta_&i. set title = &&temp_meta_&i., items = '';
        quit;
    %end;
    data ds_demog;
        set ds_demog output_meta_1-output_meta_&demog_group_count.;
    run;
    /* Delete the working dataset */
    proc datasets lib=work nolist; delete temp_metasite_1-temp_metasite_&demog_group_count. output_meta_1-output_meta_&demog_group_count. ; run; quit;

%mend FREQ_METASITE;

%macro FREQ_META;
    %FREQ_METAYN;
    data ds_demog;
        set ds_demog ds_meta_2;
    run;
    %FREQ_METASITE;
    data ds_demog;
        set ds_demog ds_meta_3 ds_meta_4;
    run;
    /* Delete the working dataset */
    proc datasets lib=work nolist; delete ds_meta_1-ds_meta_4 ; run; quit;

%mend FREQ_META;

**************************************************************************;
%let thisfile=%GET_THISFILE_FULLPATH;
%let projectpath=%GET_DIRECTORY_PATH(&thisfile., 3);
%inc "&projectpath.\program\sas\analysis_sets.sas";
**************************************************************************;
%CREATE_OUTPUT_DS(output_ds=ds_demog, items_label='背景と人口統計学的特性');
proc contents data=ds_demog out=ds_colnames varnum noprint; run;
%MEANS_FUNC(title='年齢', var_var=AGE);
%FREQ_FUNC(title='クローン病', var_var=CrohnYN);
%FREQ_FUNC(title='HNPCC', var_var=HNPCCYN);
%FREQ_FUNC(title='TNM分類', var_var=TNMCAT);
%FREQ_FUNC(title='PS', var_var=PS);
%FREQ_FUNC(title='部位', var_var=SBCSITE);
%FREQ_FUNC(title='病理組織の分化度', var_var=SBCdegree);
%FREQ_FUNC(title='RAS変異の有無', var_var=RASYN);
%FREQ_META;
%TO_NUM_TEST_RESULTS(var=LDH);
%MEANS_FUNC(title='LDH', var_var=LDH_num);
%TO_NUM_TEST_RESULTS(var=CEA);
%MEANS_FUNC(title='CEA', var_var=CEA_num);
%TO_NUM_TEST_RESULTS(var=CA199);
%MEANS_FUNC(title='CA199', var_var=CA199_num);
%ds2csv (data=ds_demog, runmode=b, csvfile=&outpath.\demog.csv, labels=Y);
*Multiple primary cancers;
data multiple_primary_cancers;
    format subjid best12.;
    set ptdata(rename=(subjid=id));
    where MHCOM ne '';
    subjid = id;
    keep subjid MHCOM;
run;
