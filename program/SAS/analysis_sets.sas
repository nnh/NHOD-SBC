**************************************************************************
Program Name : analysis_sets.sas
Study Name : NHOD-SBC
Author : Ohtsuka Mariko
Date : 2020-02-06
SAS version : 9.4
**************************************************************************;
%macro EDIT_DS_SEX();
    %local raw_path dir_raw raw_registration;
    %let raw_path="&projectpath.\input\rawdata";
    filename dir_raw &raw_path.;
    data temp_rawdata_filename; 
       length var $400;
       * Open directory;
       did = dopen("dir_raw");
       * set file names in variables;
       do i = 1 to dnum(did);
           var = dread(did, i);
           output ;
       end;
       rc = dclose(did) ;
    run;
    * Set the csv name of registration;
    data _NULL_;
        set temp_rawdata_filename;
        if PRXMATCH('/SBC_registration_/',var)=1 then do;
            call symput('raw_registration', compress(var));
        end;
    run;
    proc import 
        datafile="&projectpath.\input\rawdata\&raw_registration."
        out=temp_registration
        dbms=csv replace;
        getnames=yes;
        guessingrows=999;
    run;
    proc format library=libads;
        value $FMT_SEX
            0="�j��"
            1="����";
    run;
    data ds_registration;
        set temp_registration;
        subjid=input(VAR9, best12.);
        format field9 FMT_SEX.;
        keep subjid field9;
        rename field9=sex;
    run;
    * Delete the working dataset;
    proc datasets lib=work nolist; delete temp_rawdata_filename temp_registration; run; quit;
%mend EDIT_DS_SEX;
* Load analysis target group from EXCEL file;
options noxwait noxsync;
%sysexec "&projectpath.\document\&saihi_input.";
data _NULL_;
  rc = sleep(5);
run;
filename sas2xl dde 'excel | system';
%let temp_setfile="excel|[&saihi_input.]&saihi_input_range.";
filename exc dde &temp_setfile.;
data saihi;
    attrib
        subjid format=best12.
        analysis_set length=$30.
        efficacy format=best12.
        safety format=best12.
        analysis_group length=$24.;
    infile exc notab dlm="09"x dsd lrecl=5000;
    input subjid analysis_set efficacy safety;
    if substr(analysis_set, 1, 8)='�����؏�' then do;
        analysis_group=&ope_group.;
    end;
    else if substr(analysis_set, 1, 10)='�������؏�' then do;
        analysis_group=&non_ope_group.;
    end;
run;
data _null_;
    file sas2xl;
    put '[error(false)]';
    put '[close("false")]';
    put '[quit()]';
run;
proc sort data=saihi; by subjid; run;

* Load ptdata and merge with analysis target group information;
data ptdata;
    set libads.ptdata;
    temp_subjid=input(subjid, best12.);
    drop subjid;
    rename temp_subjid=subjid;
run;
data ptdata;
    merge ptdata saihi;
    by subjid;
run;
* Merge sex;
%EDIT_DS_SEX;
data ptdata ptdata_all;
    merge ptdata ds_registration;
    by subjid;
run;
* Efficacy group;
data ptdata;
    set ptdata;
    where efficacy=1;
run;

* Get variable information of ptdata;
proc contents data=ptdata out=temp_ptdata_contents varnum noprint; run;
data ptdata_contents;
    set temp_ptdata_contents(rename=(FORMAT=temp_format));
    attrib FORMAT label="�ϐ��o�͌`��" length=$32 format=$32.;
    if type=1 & temp_format='' then do;
        FORMAT = "$";
    end;
    else if find(NAME, 'metaSITE_')=1 then do;
        FORMAT = "$";
    end;
    else do;
        FORMAT= temp_format;
    end;
run;

* 5.1. Breakdown of analysis target group (registration example);
proc sql noprint;
    create table ds_N (Item char(200), Category char(200), count num, percent num);
    select count(*) into: count_n from ptdata_all;
    insert into ds_N values('��͑ΏۏW�c�̓���', '�o�^��', &count_n., 100);
quit;
%EXEC_FREQ(ptdata_all, efficacy, efficacy);
%EXEC_FREQ(ptdata_all, safety, safety);
%EXEC_FREQ(ptdata_all, analysis_set, analysis_set);
%EXEC_FREQ(ptdata_all, analysis_group, analysis_group);

data analysis; 
    set analysis_set(rename=(analysis_set=analysis))
        analysis_group(rename=(analysis_group=analysis));
run;

%INSERT_SQL(safety, ds_N, %str('', '���S����͑ΏۏW�c', count, percent), %str(safety=1));
%INSERT_SQL(efficacy, ds_N, %str('', &efficacy_group., count, percent), %str(efficacy=1));
%INSERT_SQL(analysis, ds_N, %str('', &ope_group., count, percent), %str(analysis=)&ope_group.);
%INSERT_SQL(analysis, ds_N, %str('', &ope_non_chemo., count, percent), %str(analysis=)&ope_non_chemo.);
%INSERT_SQL(analysis, ds_N, %str('', &ope_chemo., count, percent), %str(analysis=)&ope_chemo.);
%INSERT_SQL(analysis, ds_N, %str('', &non_ope_group., count, percent), %str(analysis=)&non_ope_group.);
%INSERT_SQL(analysis, ds_N, %str('', &non_ope_non_chemo., count, percent), %str(analysis=)&non_ope_non_chemo.);
%INSERT_SQL(analysis, ds_N, %str('', &non_ope_chemo., count, percent), %str(analysis=)&non_ope_chemo.);

* Delete the working dataset;
proc datasets lib=work nolist; save ptdata ds_n ptdata_contents ptdata_all; quit;
