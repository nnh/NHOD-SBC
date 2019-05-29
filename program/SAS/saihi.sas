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
/*�t�H���_�̃p�X���擾����*/
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
	/*�����؏��EChemotherapy�̉�͑ΏۏW�c�F
	EDC�f�[�^���u�����؏�������v�A
	�u�p��⏕���w�Ö@�̎��{������v�A
	�u�p��⏕���w�Ö@��6�����Ԗ����ŏI���������������v�̏Ǘ�B*/
	/*�����؏��Enon-Chemotherapy�̉�͑ΏۏW�c�F
	EDC�f�[�^���u�����؏�������v�A
	�u�p��⏕���w�Ö@�̎��{���Ȃ��v�̏Ǘ�B
	�܂���EDC�f�[�^���u�����؏�������v�A
	�u�p��⏕���w�Ö@�̎��{������v�A
	�u�p��⏕���w�Ö@��6�����Ԗ����ŏI���������͂��v�̏Ǘ�B*/
	/*�E�������؏��Enon-Chemotherapy�̉�͑ΏۏW�c�F
	EDC�f�[�^���u�����؏����Ȃ��v�A
	�u�������؏���ɑ΂��鉻�w�Ö@�̎��{���Ȃ��v�̏Ǘ�A
	�܂��́u�����؏����Ȃ��v�A
	�u�������؏���ɑ΂��鉻�w�Ö@�̎��{������v�A
	�u���w�Ö@�@1�R�[�X�����������������v�̏Ǘ�*/
	/*�E�������؏��EChemotherap�̉�͑ΏۏW�c�F
	EDC�f�[�^���u�����؏����Ȃ��v�A
	�u�������؏���ɑ΂��鉻�w�Ö@�̎��{������v�A
	�u���w�Ö@�@1�R�[�X�����������͂��v�̏Ǘ�*/
	set col temp_ds;
	format o1 o2 $60. ;
	if f3VAR13="����" then do;
		o1="�����؏�";
		if f4VAR13="����" and f4VAR17="������" then do;
			o2="�����؏��EChemotherapy�Q";
		end;
		if (f4VAR13="�Ȃ�") or (f4VAR13="����" and f4VAR17="�͂�") then do;
			o2="�����؏��Enon-Chemotherapy�Q";
		end;
	end;
	else if f3VAR13="�Ȃ�" then do;
		o1="�������؏�";
		if (f2VAR13="�Ȃ�") or (f2VAR13="����" and f2VAR19="������") then do;
			o2="�������؏��Enon-Chemotherapy�Q";
		end;
		else if f2VAR13="����" and f2VAR19="�͂�" then do;
			o2="�������؏��EChemotherapy�Q";
		end;
	end;
	if _N_=1 then do;
		o1="�����؏�/�������؏�";
		o2="��͑ΏۏW�c";
	end;
run;

%ds2csv (data=output_ds, runmode=b, csvfile=C:\Users\Mariko\Desktop\out_all.csv, labels=N);
data output_ds;
	set output_ds;
	label VAR9="�Ǘ�o�^�ԍ�";
	label o2="��͑ΏۏW�c";
	if _N_=1 then delete;
	keep VAR9 o2;
run;
%ds2csv (data=output_ds, runmode=b, csvfile=C:\Users\Mariko\Desktop\out.csv, labels=Y);
