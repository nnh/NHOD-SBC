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

%macro SET_COLNAMES(input_ds);  
    %global temp_name_cnt temp_name_per;
    data _NULL_;
        set &input_ds.;
        if _N_=1 then do;
            call symput('temp_analysis_set', analysis_set);
        end;
    run;
    data _NULL_;
        set ds_colnames;
        if LABEL="&temp_analysis_set." then do;
            call symput('temp_name_cnt', NAME);
        end;
    run;
    %let temp_name_per=%substr(&temp_name_cnt, 1, %sysfunc(length(&temp_name_cnt.))-3)per;
%mend SET_COLNAMES;

%macro GET_LENGTH(input_ds, var);
    %global var_len;
    data _NULL_;
        set &input_ds.;
        if NAME=&var. then do;
            call symput('var_len', LENGTH);
        end;
    run;
%mend GET_LENGTH; 

%macro GET_TYPE(input_ds, var);
    %global var_type;
    %local temp_type;
    data _NULL_;
        set &input_ds.;
        if NAME=&var. then do;
            call symput('temp_type', TYPE);
        end;
        if temp_type=1 then do;
            call symput('var_type', 'best12.');
        end;
        else do;
            call symput('var_type', '$');
        end;
    run;
%mend GET_TYPE; 

%macro GET_FORMAT(input_ds, var);
    %global str_format;
    %GET_TYPE(&input_ds., &var.);
    %let str_format=&var_type.;
    %if &str_format.=$ %then %do;
        %GET_LENGTH(&input_ds., &var.);
        %let str_format=%sysfunc(cat(&str_format., &var_len.));
    %end;
     /*    if &str_format.='$' then do;
            %GET_LENGTH(&input_ds., &var.);
            %let str_format=%sysfunc(cat(&str_format., &var_len.));
        end;*/

%mend GET_FORMAT;

%macro FREQ_FUNC(input_ds=ptdata, title='', cat_var=analysis_set, var_var='', output_ds=ds_demog);
    proc freq data=&input_ds. noprint;
        tables &var_var./missing out=temp_all_ds;
    run;
    %EDIT_DS_ALL;
    proc freq data=&input_ds. noprint;
        tables &cat_var.*&var_var./missing out=temp_ds;
    run;

    data temp_ds;
        set temp_all_ds temp_ds;
        temp_per=round(percent, 0.1);
        /* Convert format to string */
        %let dsid=%sysfunc(open(temp_ds, i));
        %if &dsid %then %do;
            %let fmt=%sysfunc(varfmt(&dsid, %sysfunc(varnum(&dsid, &var_var.))));
            %let rc=%sysfunc(close(&dsid));
        %end;
        %put &fmt.;
        items=put(&var_var., &fmt.);
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

    %do i = 1 %to 5;
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
        merge temp1 temp2 temp3 temp4 temp5;
        by temp_items;
        if _N_=1 then do; title=&title.; end;
        items=temp_items;
        drop temp_items;
    run;

    data &output_ds.;
        set &output_ds. temp_output;
    run;

    /* Delete the working dataset */
    proc datasets lib=work nolist; delete temp1-temp5 temp_ds temp_all_ds temp_output; run; quit;

%mend FREQ_FUNC;
**************************************************************************;
%let thisfile=%GET_THISFILE_FULLPATH;
%let projectpath=%GET_DIRECTORY_PATH(&thisfile., 3);
%inc "&projectpath.\program\sas\analysis_sets.sas";
**************************************************************************;
%CREATE_OUTPUT_DS(output_ds=ds_demog, items_label='背景と人口統計学的特性');
proc contents data=ds_demog out=ds_colnames varnum noprint; run;

%MEANS_FUNC(title='年齢', var_var=age);
%FREQ_FUNC(title='クローン病', var_var=crohnyn);

%ds2csv (data=ds_demog, runmode=b, csvfile=&outpath.\aaa.csv, labels=Y);
