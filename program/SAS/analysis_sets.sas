**************************************************************************
Program Name : analysis_sets.sas
Study Name : NHOD-SBC
Author : Ohtsuka Mariko
Date : 2019-05-30
SAS version : 9.4
**************************************************************************;
proc datasets library=work kill nolist; quit;

options mprint mlogic symbolgen minoperator;
*Find the current working directory;
/*フォルダのパスを取得する*/
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

%let thisfile=%GET_THISFILE_FULLPATH;
%put &thisfile.;

%let projectpath=%GET_DIRECTORY_PATH(&thisfile., 3);
%put &projectpath.;

%let extpath=&projectpath\input\ext;
%put &extpath.;

proc import datafile="&extpath.\test.csv"
                    out=saihi
                    dbms=csv replace;
run;

data saihi;
    set saihi;
    SUBJID=input(VAR1, best12.);
	rename VAR2=ANALYSIS_SET VAR3=EFFICACY VAR4=SAFETY;
    drop VAR1;
run;

proc sort data=saihi; by SUBJID; run;

%macro COUNT (name, var, title, raw);

    proc freq data=&raw noprint;
        tables &var / out=&name;
    run;

    proc sort data=&name; by &var; run;

    data &name._2;
        format Category $12. Count Percent best12.;
        set &name;
        Category=&var;
        if &var=' ' then Category='MISSING';
        percent=round(percent, 0.1);
        drop &var;
    run;

    data &name._2;
        format Item $60. Category $12. Count Percent best12.;
        set &name._2;
        if _N_=1 then do; item="&title"; end;
    run;

    proc summary data=&name._2;
        var count percent;
        output out=&name._total sum=;
    run;

    data &name._total_2;
        format Item $60. Category $12. Count Percent best12.;
        set &name._total;
        item=' ';
        category='合計';
        keep Item Category Count Percent;
    run;

    data x_&name;
        format Item $60. Category $12. Count Percent best12.;
        set &name._2 &name._total_2;
    run;

%mend COUNT;

/*
    %COUNT (oxygen, oxygen, 登録例, saihi);
*/
proc sql;
	create table N (
		Item char(200) ,
		Category char(10),
		count num,
		percent num
	);
	insert into N (Item, Category, count, percent)
	select '登録例', 'N', count(*), 0 from saihi;
	insert into N (Item, Category, count, percent)
	select '有効性解析対象集団', 'N', count(*), 0 from saihi where EFFICACY = 1;
quit;

*治癒切除・non-Chemotherapyの解析対象集団;
