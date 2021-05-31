**************************************************************************
Program Name : analysis_sets.sas
Study Name : NHOD-SBC
Author : Ohtsuka Mariko
Date : 2020-02-26
SAS version : 9.4
**************************************************************************;
%macro EDIT_DS_SEX();
    %local raw_path dir_raw raw_registration i;
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
            "M"="íjê´"
            "F"="èóê´";
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
    if substr(analysis_set, 1, 8)='é°ñ¸êÿèú' then do;
        analysis_group=&ope_group.;
    end;
    else if substr(analysis_set, 1, 10)='é°ñ¸ñ¢êÿèú' then do;
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
    where efficacy=1 & analysis_group is not missing;
run;

* Get variable information of ptdata;
proc contents data=ptdata out=temp_ptdata_contents varnum noprint; run;
data ptdata_contents;
    set temp_ptdata_contents(rename=(FORMAT=temp_format));
    attrib FORMAT label="ïœêîèoóÕå`éÆ" length=$32 format=$32.;
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
%CREATE_DS_N(ptdata_all, ds_N);
%CREATE_DS_N(ptdata, ds_N_efficacy);
