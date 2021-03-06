* Save log;
options errorabend;
proc printto log="C:\Users\Mariko\Desktop\log.log" new;
run;
data class;
    set sashelp.class;
run;
/******************************************************
Program Name : main.sas
Study Name : NHOD-SBC
Author : Ohtsuka Mariko
Date : 2020-03-06
SAS version : 9.4
*******************************************************/
%let saihi_input=��͑ΏۏW�c�ꗗ.xlsx;
%let saihi_input_range=Sheet1!R2C1:R33C4;
%let template_input=��͐}�\�e���v���[�g20200221.xlsx;
%let template_output=sas_output.xlsx;
**************************************************************************;
* Define macros;
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
%let projectpath=%GET_DIRECTORY_PATH(&thisfile., 3);
%inc "&projectpath.\program\SAS\macro\libname.sas";

%include "\\aronas\Stat\Trials\NHO\NHOD-SBC\program\SAS\analysis_sets.sas";
%include "\\aronas\Stat\Trials\NHO\NHOD-SBC\program\SAS\cancel.sas";
%include "\\aronas\Stat\Trials\NHO\NHOD-SBC\program\SAS\demog.sas";
%include "\\aronas\Stat\Trials\NHO\NHOD-SBC\program\SAS\treatment.sas";
%include "\\aronas\Stat\Trials\NHO\NHOD-SBC\program\SAS\os_pfs.sas";
%include "\\aronas\Stat\Trials\NHO\NHOD-SBC\program\SAS\response.sas";
%include "\\aronas\Stat\Trials\NHO\NHOD-SBC\program\SAS\tumor_reduction.sas";
%include "\\aronas\Stat\Trials\NHO\NHOD-SBC\program\SAS\ae.sas";
%include "\\aronas\Stat\Trials\NHO\NHOD-SBC\program\SAS\output_excel.sas";
* *** main program end ***;
proc printto;
run;
* *** eof ***;
