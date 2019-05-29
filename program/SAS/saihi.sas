**************************************************************************
Program Name : saihi.sas
Study Name : NHOD-SBC
Author : Ohtsuka Mariko
Date : 2019-05-29
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

%let rawpath=&projectpath\input\rawdata;
%put &rawpath.;

%let extpath=&projectpath\input\ext;
%put &extpath.;

%let csv_ymd=%str(_190524_0949.csv);
%put &csv_ymd.;

%macro READ_CSV(aliasname);
	proc import datafile="&rawpath.\SBC_&aliasname.&csv_ymd."
    	                out=temp_ds
        	            dbms=csv replace;
			getnames=no;
	run;
	data col;
		set temp_ds;
		if _N_=1; 
	run;
	data temp_ds;
		set temp_ds;
		if _N_=1 then delete;
	run;
	proc sort data=temp_ds; by VAR9; run;
	data &aliasname.;
		set temp_ds col;
	run;
%mend READ_CSV;

%let aliasname=registration;
%READ_CSV(&aliasname.);
data &aliasname.;
    set &aliasname.;
	rename VAR21=regVAR21 VAR25=regVAR25;
	keep VAR9 VAR21 VAR25;
run;

%let aliasname=flowsheet2;
%READ_CSV(&aliasname.);
data &aliasname.;
    set &aliasname.;
	rename VAR13=f2VAR13 VAR19=f2VAR19;
	keep VAR9 VAR13 VAR19;
run;

%let aliasname=flowsheet3;
%READ_CSV(&aliasname.);
data &aliasname.;
    set &aliasname.;
	rename VAR13=f3VAR13;
	keep VAR9 VAR13;
run;

%let aliasname=flowsheet4;
%READ_CSV(&aliasname.);
data &aliasname.;
    set &aliasname.;
	rename VAR13=f4VAR13 VAR17=f4VAR17;
	keep VAR9 VAR13 VAR17;
run;

data merge_ds;
	merge registration flowsheet2 flowsheet3 flowsheet4;
	by VAR9;
run;

data col;
	set merge_ds nobs=_OBS;
	if _N_=_OBS then output;
run;

data temp_ds;
	set merge_ds nobs=_OBS;
	if _N_^=_OBS then output;
run;

proc sort data=temp_ds sortseq=linguistic (numeric_collation=on) ;
by VAR9;
run;

data output_ds;
	/*治癒切除・Chemotherapyの解析対象集団：
	EDCデータより「治癒切除＝あり」、
	「術後補助化学療法の実施＝あり」、
	「術後補助化学療法が6ヵ月間未満で終了した＝いいえ」の症例。*/
	/*治癒切除・non-Chemotherapyの解析対象集団：
	EDCデータより「治癒切除＝あり」、
	「術後補助化学療法の実施＝なし」の症例。
	またはEDCデータより「治癒切除＝あり」、
	「術後補助化学療法の実施＝あり」、
	「術後補助化学療法が6ヵ月間未満で終了した＝はい」の症例。*/
	/*・治癒未切除・non-Chemotherapyの解析対象集団：
	EDCデータより「治癒切除＝なし」、
	「治癒未切除例に対する化学療法の実施＝なし」の症例、
	または「治癒切除＝なし」、
	「治癒未切除例に対する化学療法の実施＝あり」、
	「化学療法　1コース完遂した＝いいえ」の症例*/
	/*・治癒未切除・Chemotherapの解析対象集団：
	EDCデータより「治癒切除＝なし」、
	「治癒未切除例に対する化学療法の実施＝あり」、
	「化学療法　1コース完遂した＝はい」の症例*/
	set col temp_ds;
	format o1 o2 $60. ;
	if f3VAR13="あり" then do;
		o1="治癒切除";
		if f4VAR13="あり" and f4VAR17="いいえ" then do;
			o2="治癒切除・Chemotherapy群";
		end;
		if (f4VAR13="なし") or (f4VAR13="あり" and f4VAR17="はい") then do;
			o2="治癒切除・non-Chemotherapy群";
		end;
	end;
	else if f3VAR13="なし" then do;
		o1="治癒未切除";
		if (f2VAR13="なし") or (f2VAR13="あり" and f2VAR19="いいえ") then do;
			o2="治癒未切除・non-Chemotherapy群";
		end;
		else if f2VAR13="あり" and f2VAR19="はい" then do;
			o2="治癒未切除・Chemotherapy群";
		end;
	end;
	if _N_=1 then do;
		o1="治癒切除/治癒未切除";
		o2="解析対象集団";
	end;
run;

%ds2csv (data=output_ds, runmode=b, csvfile=C:\Users\Mariko\Desktop\out_all.csv, labels=N);
data output_ds;
	set output_ds;
	label VAR9="症例登録番号";
	label o2="解析対象集団";
	if _N_=1 then delete;
	keep VAR9 o2;
run;
%ds2csv (data=output_ds, runmode=b, csvfile=C:\Users\Mariko\Desktop\out.csv, labels=Y);
