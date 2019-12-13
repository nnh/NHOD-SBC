**************************************************************************
Program Name : response.sas
Study Name : NHOD-SBC
Author : Ohtsuka Mariko
Date : 2019-12-13
SAS version : 9.4
**************************************************************************;
* 5.5.3. Response rate of treatment;
/*解析対象群：
治癒切除・nonCTの解析対象集団
治癒切除・CTの解析対象集団
治癒未切除・CTの解析対象集団
*/
%SET_FREQ(ds_res_1, '治療の奏効割合', RECISTORRES, %str(ope_non_chemo_cnt), response_ope_no_chemo.csv);
data ds_ope_chemo ds_non_ope_chemo;
    set ptdata;
    if analysis_set=&ope_chemo. then output ds_ope_chemo;
    if analysis_set=&non_ope_chemo. then output ds_non_ope_chemo;
run;
proc sql;
    create table ds_res_2
    as select adjuvantCAT, RECISTORRES, count(*) from ds_ope_chemo group by adjuvantCAT, RECISTORRES;
quit;
proc sql;
    create table ds_res_3
    as select chemCAT, RECISTORRES, count(*) from ds_non_ope_chemo group by chemCAT, RECISTORRES;
quit;
